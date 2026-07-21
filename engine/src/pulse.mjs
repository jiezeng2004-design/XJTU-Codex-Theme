import { findCodexMainPid } from "./codex.mjs";
import { INSPECTOR_PORT } from "./config.mjs";

const delay = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds));

async function inspectorTargets(port = INSPECTOR_PORT, timeoutMs = 500) {
  const response = await fetch(`http://127.0.0.1:${port}/json/list`, {
    signal: AbortSignal.timeout(timeoutMs),
  });
  if (!response.ok) throw new Error(`Inspector endpoint returned HTTP ${response.status}.`);
  return response.json();
}

export async function inspectorPortOpen(port = INSPECTOR_PORT) {
  try { return Array.isArray(await inspectorTargets(port)); } catch { return false; }
}

class CdpSession {
  constructor(target, timeoutMs = 8000) {
    this.target = target;
    this.timeoutMs = timeoutMs;
    this.nextId = 0;
    this.pending = new Map();
    this.socket = null;
  }

  async open() {
    if (typeof WebSocket !== "function") throw new Error("This Node.js version does not provide WebSocket. Use Node.js 22 or newer.");
    this.socket = new WebSocket(this.target.webSocketDebuggerUrl);
    await new Promise((resolve, reject) => {
      this.socket.addEventListener("open", resolve, { once: true });
      this.socket.addEventListener("error", () => reject(new Error("Inspector WebSocket connection failed.")), { once: true });
    });
    this.socket.addEventListener("message", (event) => {
      const message = JSON.parse(String(event.data));
      const waiter = message.id && this.pending.get(message.id);
      if (!waiter) return;
      this.pending.delete(message.id);
      clearTimeout(waiter.timer);
      if (message.error) waiter.reject(new Error(message.error.message));
      else waiter.resolve(message.result);
    });
    await this.send("Runtime.enable");
    return this;
  }

  send(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = ++this.nextId;
      const timer = setTimeout(() => {
        if (this.pending.delete(id)) reject(new Error(`Inspector request timed out: ${method}`));
      }, this.timeoutMs);
      this.pending.set(id, { resolve, reject, timer });
      this.socket.send(JSON.stringify({ id, method, params }));
    });
  }

  fire(method, params = {}) {
    const id = ++this.nextId;
    this.socket?.send(JSON.stringify({ id, method, params }));
  }

  async evaluate(expression, awaitPromise = true) {
    const result = await this.send("Runtime.evaluate", {
      expression,
      includeCommandLineAPI: true,
      returnByValue: true,
      awaitPromise,
    });
    if (result.exceptionDetails) {
      throw new Error(result.exceptionDetails.exception?.description || result.exceptionDetails.text || "Inspector evaluation failed.");
    }
    return result.result?.value;
  }

  close() {
    for (const waiter of this.pending.values()) {
      clearTimeout(waiter.timer);
      waiter.reject(new Error("Inspector session closed."));
    }
    this.pending.clear();
    try { this.socket?.close(); } catch { /* already closed */ }
  }
}

function triggerInspector(pid) {
  if (typeof process._debugProcess !== "function") {
    const error = new Error("Node.js process._debugProcess is unavailable on this runtime.");
    error.code = "INSPECTOR_UNAVAILABLE";
    throw error;
  }
  process._debugProcess(Number(pid));
}

async function openInspector(pid, { allowExisting = false, timeoutMs = 8000 } = {}) {
  let targets = [];
  if (await inspectorPortOpen()) {
    if (!allowExisting) {
      const error = new Error(`127.0.0.1:${INSPECTOR_PORT} is already in use. Refusing to attach or close an inspector not opened by this operation.`);
      error.code = "INSPECTOR_PORT_IN_USE";
      throw error;
    }
    targets = await inspectorTargets(INSPECTOR_PORT, 600);
  } else {
    triggerInspector(pid);
    const deadline = Date.now() + timeoutMs;
    while (Date.now() < deadline) {
      try {
        targets = await inspectorTargets(INSPECTOR_PORT, 600);
        if (targets.some((target) => target.webSocketDebuggerUrl)) break;
      } catch { /* target is still opening */ }
      await delay(180);
    }
  }

  const target = targets.find((item) => item.webSocketDebuggerUrl);
  if (!target) throw new Error(`Codex inspector did not open on 127.0.0.1:${INSPECTOR_PORT} within ${timeoutMs}ms.`);
  const session = await new CdpSession(target, timeoutMs).open();
  const attachedPid = Number(await session.evaluate("process.pid", false));
  if (attachedPid !== Number(pid)) {
    session.close();
    const error = new Error(`Inspector PID mismatch: expected ${pid}, received ${attachedPid}.`);
    error.code = "INSPECTOR_PID_MISMATCH";
    throw error;
  }
  return session;
}

async function pulseOnce(expression, { allowExisting = false, timeoutMs = 10000 } = {}) {
  const pid = findCodexMainPid();
  if (!pid) {
    const error = new Error("Codex is not running. Open Codex normally before applying a hot theme.");
    error.code = "CODEX_NOT_RUNNING";
    throw error;
  }

  const session = await openInspector(pid, { allowExisting, timeoutMs: Math.min(timeoutMs, 8000) });
  try {
    return await session.evaluate(expression, true);
  } finally {
    try {
      session.fire("Runtime.evaluate", {
        expression: "setTimeout(()=>{try{require('inspector').close()}catch(e){};try{if(process._debugEnd)process._debugEnd()}catch(e){}},30)",
      });
    } catch { /* connection may already be closing */ }
    await delay(250);
    session.close();
  }
}

export async function pulse(expression, { allowExisting = false, timeoutMs = 10000 } = {}) {
  let lastError;
  for (let attempt = 1; attempt <= 3; attempt += 1) {
    try { return await pulseOnce(expression, { allowExisting, timeoutMs }); }
    catch (error) {
      lastError = error;
      if (["CODEX_NOT_RUNNING", "INSPECTOR_PORT_IN_USE", "INSPECTOR_PID_MISMATCH", "INSPECTOR_UNAVAILABLE"].includes(error.code)) throw error;
      if (attempt < 3) await delay(500);
    }
  }
  throw lastError;
}
