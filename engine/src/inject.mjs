import fs from "node:fs";

export const ROOT_CLASS = "xjtu-hot-theme";
export const STYLE_ID = "xjtu-hot-theme-style";

export const FIXED_CSS = `
html.${ROOT_CLASS} {
  --color-text-foreground: var(--xjtu-text) !important;
  --color-text-foreground-secondary: var(--xjtu-muted) !important;
  --color-text-foreground-tertiary: color-mix(in srgb, var(--xjtu-muted) 72%, transparent) !important;
  --color-icon-primary: var(--xjtu-text) !important;
  --color-icon-secondary: var(--xjtu-muted) !important;
  --color-icon-tertiary: color-mix(in srgb, var(--xjtu-muted) 70%, transparent) !important;
  --color-icon-accent: var(--xjtu-accent) !important;
  --color-text-accent: var(--xjtu-accent) !important;
  --color-text-link-foreground: var(--xjtu-accent) !important;
  --color-border: var(--xjtu-line) !important;
  --color-border-light: color-mix(in srgb, var(--xjtu-line) 60%, transparent) !important;
  --color-border-heavy: var(--xjtu-line) !important;
  --color-border-focus: var(--xjtu-accent) !important;
  --color-background-panel: var(--xjtu-panel) !important;
  --color-background-surface: color-mix(in srgb, var(--xjtu-panel) 88%, transparent) !important;
  --color-background-surface-under: color-mix(in srgb, var(--xjtu-panel) 76%, var(--xjtu-bg)) !important;
  --color-background-control: var(--xjtu-panel) !important;
  --color-background-control-opaque: var(--xjtu-panel) !important;
  --color-background-elevated-primary: var(--xjtu-panel) !important;
  --color-background-elevated-primary-opaque: var(--xjtu-panel) !important;
  --color-background-elevated-secondary: var(--xjtu-panel) !important;
  --color-background-elevated-secondary-opaque: var(--xjtu-panel) !important;
  --color-background-button-primary: var(--xjtu-accent) !important;
  --color-background-button-primary-hover: color-mix(in srgb, var(--xjtu-accent) 86%, black) !important;
  --color-background-button-secondary: color-mix(in srgb, var(--xjtu-text) 10%, transparent) !important;
  --color-background-button-secondary-hover: color-mix(in srgb, var(--xjtu-text) 15%, transparent) !important;
  --color-text-button-primary: var(--xjtu-bg) !important;
  --color-text-button-secondary: var(--xjtu-text) !important;
  --color-accent-blue: var(--xjtu-accent) !important;
  --codex-base-accent: var(--xjtu-accent) !important;
  --codex-base-ink: var(--xjtu-text) !important;
  --codex-base-surface: var(--xjtu-panel) !important;
  --color-token-bg-primary: transparent !important;
  --color-token-main-surface-primary: transparent !important;
  --color-token-side-bar-background: transparent !important;
  --color-token-foreground: var(--xjtu-text) !important;
  --color-token-text-primary: var(--xjtu-text) !important;
  --color-token-text-secondary: var(--xjtu-muted) !important;
  --color-token-border: var(--xjtu-line) !important;
  --color-token-primary: var(--xjtu-accent) !important;
  --color-token-link: var(--xjtu-accent) !important;
  color-scheme: var(--xjtu-color-scheme) !important;
}

html.${ROOT_CLASS} body {
  background-color: var(--xjtu-bg) !important;
  background-image:
    linear-gradient(color-mix(in srgb, var(--xjtu-bg) var(--xjtu-body-a), transparent), color-mix(in srgb, var(--xjtu-bg) var(--xjtu-body-b), transparent)),
    var(--xjtu-art) !important;
  background-position: center, var(--xjtu-position-x) center !important;
  background-size: cover, auto var(--xjtu-zoom) !important;
  background-repeat: no-repeat !important;
  background-attachment: fixed !important;
  color: var(--xjtu-text) !important;
}

html.${ROOT_CLASS} main.main-surface {
  background-color: transparent !important;
  background-image:
    linear-gradient(color-mix(in srgb, var(--xjtu-bg) var(--xjtu-main-a), transparent), color-mix(in srgb, var(--xjtu-bg) var(--xjtu-main-b), transparent)),
    var(--xjtu-art) !important;
  background-position: center, var(--xjtu-position-x) center !important;
  background-size: cover, auto var(--xjtu-zoom) !important;
  background-repeat: no-repeat !important;
  background-attachment: fixed !important;
  border: 0 !important;
  border-radius: 0 !important;
  box-shadow: inset 1px 0 color-mix(in srgb, var(--xjtu-line) 55%, transparent) !important;
  backdrop-filter: none !important;
}

html.${ROOT_CLASS} aside.app-shell-left-panel {
  background-color: var(--xjtu-bg) !important;
  background-image:
    linear-gradient(color-mix(in srgb, var(--xjtu-bg) var(--xjtu-sidebar-a), transparent), color-mix(in srgb, var(--xjtu-bg) var(--xjtu-sidebar-b), transparent)),
    var(--xjtu-art) !important;
  background-position: center, var(--xjtu-position-x) center !important;
  background-size: cover, auto var(--xjtu-zoom) !important;
  background-repeat: no-repeat !important;
  background-attachment: fixed !important;
  border-right: 1px solid color-mix(in srgb, var(--xjtu-line) 55%, transparent) !important;
  color: var(--xjtu-text) !important;
  text-shadow: 0 1px 3px color-mix(in srgb, var(--xjtu-bg) 76%, transparent);
  backdrop-filter: none !important;
}

html.${ROOT_CLASS} aside.app-shell-left-panel nav,
html.${ROOT_CLASS} [role="main"] { background: transparent !important; }

html.${ROOT_CLASS} aside.app-shell-left-panel button:hover {
  background: color-mix(in srgb, var(--xjtu-accent) 15%, transparent) !important;
}

html.${ROOT_CLASS} aside.app-shell-left-panel :is([aria-current="page"], [aria-selected="true"]) {
  background: color-mix(in srgb, var(--xjtu-accent) 20%, transparent) !important;
  box-shadow: inset 3px 0 var(--xjtu-accent) !important;
}

html.${ROOT_CLASS} main.main-surface > header,
html.${ROOT_CLASS} header.app-header-tint {
  background: color-mix(in srgb, var(--xjtu-panel) 42%, transparent) !important;
  border-bottom: 1px solid color-mix(in srgb, var(--xjtu-line) 60%, transparent) !important;
  backdrop-filter: none !important;
}

html.${ROOT_CLASS} .group\/home-suggestions > * {
  background: color-mix(in srgb, var(--xjtu-panel) 92%, transparent) !important;
  border: 1px solid var(--xjtu-line) !important;
  box-shadow: 0 12px 28px color-mix(in srgb, var(--xjtu-bg) 36%, transparent) !important;
  backdrop-filter: none !important;
}

html.${ROOT_CLASS} .composer-surface-chrome {
  background: color-mix(in srgb, var(--xjtu-panel) 94%, transparent) !important;
  border: 1px solid var(--xjtu-line) !important;
  color: var(--xjtu-text) !important;
  box-shadow: 0 16px 38px color-mix(in srgb, var(--xjtu-bg) 34%, transparent) !important;
  backdrop-filter: none !important;
}

html.${ROOT_CLASS}:not(.xjtu-conversation-wallpaper) main.main-surface:has([data-turn-key]) {
  background: var(--xjtu-bg) !important;
}

html.${ROOT_CLASS} :is(article, [data-message-author-role], textarea, .ProseMirror, [contenteditable="true"]) {
  color: var(--xjtu-text) !important;
}

html.${ROOT_CLASS} :is(pre, table, blockquote) {
  background: color-mix(in srgb, var(--xjtu-panel) 96%, var(--xjtu-bg)) !important;
  border-color: var(--xjtu-line) !important;
}

html.${ROOT_CLASS} ::selection { background: color-mix(in srgb, var(--xjtu-accent) 32%, transparent); }
html.${ROOT_CLASS} { scrollbar-color: color-mix(in srgb, var(--xjtu-text) 28%, transparent) transparent; }

#xjtu-hot-theme-transition {
  position: fixed;
  inset: 0;
  z-index: 2147483647;
  pointer-events: none;
  background: var(--xjtu-bg);
  opacity: 1;
  transition: opacity 180ms ease-out;
}

@media (prefers-reduced-motion: reduce) {
  #xjtu-hot-theme-transition { transition-duration: 1ms; }
}
`.trim();

const VARIABLE_NAMES = [
  "--xjtu-bg", "--xjtu-panel", "--xjtu-accent", "--xjtu-text", "--xjtu-muted", "--xjtu-line",
  "--xjtu-art", "--xjtu-position-x", "--xjtu-zoom", "--xjtu-body-a", "--xjtu-body-b",
  "--xjtu-main-a", "--xjtu-main-b", "--xjtu-sidebar-a", "--xjtu-sidebar-b", "--xjtu-color-scheme",
];

function mimeFor(filename) {
  if (filename.toLowerCase().endsWith(".png")) return "image/png";
  if (filename.toLowerCase().endsWith(".webp")) return "image/webp";
  return "image/jpeg";
}

export function themeVariables(theme) {
  return {
    "--xjtu-bg": theme.colors.background,
    "--xjtu-panel": theme.colors.panel,
    "--xjtu-accent": theme.colors.accent,
    "--xjtu-text": theme.colors.text,
    "--xjtu-muted": theme.colors.muted,
    "--xjtu-line": theme.colors.line,
    "--xjtu-position-x": theme.layout.positionX,
    "--xjtu-zoom": theme.layout.zoom,
    "--xjtu-body-a": theme.layout.bodyScrimStart,
    "--xjtu-body-b": theme.layout.bodyScrimEnd,
    "--xjtu-main-a": theme.layout.mainScrimStart,
    "--xjtu-main-b": theme.layout.mainScrimEnd,
    "--xjtu-sidebar-a": theme.layout.sidebarScrimStart,
    "--xjtu-sidebar-b": theme.layout.sidebarScrimEnd,
    "--xjtu-color-scheme": theme.variant,
  };
}

export function buildRendererScript(theme) {
  const payload = JSON.stringify({
    className: ROOT_CLASS,
    styleId: STYLE_ID,
    css: FIXED_CSS,
    variables: themeVariables(theme),
    imageBase64: fs.readFileSync(theme.imagePath).toString("base64"),
    mimeType: mimeFor(theme.imagePath),
    themeId: theme.id,
    mode: theme.mode,
    conversationWallpaper: theme.layout.conversationWallpaper,
    variableNames: VARIABLE_NAMES,
  });

  return `(() => {
    if (location.search.includes('initialRoute=%2Favatar-overlay') || location.search.includes('initialRoute=/avatar-overlay')) {
      return { installed: false, skipped: 'avatar-overlay' };
    }
    const P = ${payload};
    window.__XJTU_HOT_THEME__?.cleanup?.();
    const root = document.documentElement;
    const binary = Uint8Array.from(atob(P.imageBase64), (character) => character.charCodeAt(0));
    const imageUrl = URL.createObjectURL(new Blob([binary], { type: P.mimeType }));
    const ensure = () => {
      root.classList.add(P.className);
      root.classList.toggle('xjtu-conversation-wallpaper', P.conversationWallpaper);
      root.dataset.xjtuTheme = P.themeId;
      root.dataset.xjtuThemeMode = P.mode;
      for (const [name, value] of Object.entries(P.variables)) root.style.setProperty(name, value);
      root.style.setProperty('--xjtu-art', 'url("' + imageUrl + '")');
      let style = document.getElementById(P.styleId);
      if (!style) {
        style = document.createElement('style');
        style.id = P.styleId;
        (document.head || root).appendChild(style);
      }
      if (style.textContent !== P.css) style.textContent = P.css;
    };
    ensure();
    const transition = document.createElement('div');
    transition.id = 'xjtu-hot-theme-transition';
    document.body?.appendChild(transition);
    requestAnimationFrame(() => requestAnimationFrame(() => { transition.style.opacity = '0'; }));
    setTimeout(() => transition.remove(), 260);
    const observer = new MutationObserver(() => ensure());
    observer.observe(root, { childList: true, subtree: true });
    const interval = setInterval(ensure, 5000);
    const cleanup = () => {
      observer.disconnect();
      clearInterval(interval);
      document.getElementById(P.styleId)?.remove();
      document.getElementById('xjtu-hot-theme-transition')?.remove();
      root.classList.remove(P.className, 'xjtu-conversation-wallpaper');
      delete root.dataset.xjtuTheme;
      delete root.dataset.xjtuThemeMode;
      for (const name of P.variableNames) root.style.removeProperty(name);
      URL.revokeObjectURL(imageUrl);
      delete window.__XJTU_HOT_THEME__;
      return true;
    };
    window.__XJTU_HOT_THEME__ = { cleanup, ensure, themeId: P.themeId, mode: P.mode };
    return { installed: true, themeId: P.themeId, mode: P.mode, hasMain: Boolean(document.querySelector('main.main-surface')) };
  })()`;
}

export function buildApplyExpression(rendererScript) {
  return `(async () => {
    const { BrowserWindow, app } = require('electron');
    const state = globalThis.__XJTU_HOT_ENGINE__ ||= { handlers: new Map(), newWindowHandler: null, rendererScript: '' };
    state.rendererScript = ${JSON.stringify(rendererScript)};
    const isApp = (contents) => String(contents.getURL() || '').startsWith('app://');
    const inject = async (contents) => {
      if (!state.rendererScript || !isApp(contents)) return { installed: false, skipped: 'non-app' };
      try { return await contents.executeJavaScript(state.rendererScript); }
      catch (error) { return { installed: false, error: error.message }; }
    };
    const hook = (contents) => {
      if (!state.handlers.has(contents.id)) {
        const handler = () => { inject(contents).catch(() => {}); };
        contents.on('dom-ready', handler);
        contents.once('destroyed', () => state.handlers.delete(contents.id));
        state.handlers.set(contents.id, { contents, handler });
      }
    };
    const windows = BrowserWindow.getAllWindows();
    for (const window of windows) hook(window.webContents);
    if (!state.newWindowHandler) {
      state.newWindowHandler = (_event, window) => { hook(window.webContents); inject(window.webContents).catch(() => {}); };
      app.on('browser-window-created', state.newWindowHandler);
    }
    return Promise.all(windows.map((window) => inject(window.webContents)));
  })()`;
}

const RESTORE_RENDERER_SCRIPT = `(() => {
  if (window.__XJTU_HOT_THEME__?.cleanup) return window.__XJTU_HOT_THEME__.cleanup();
  document.getElementById('${STYLE_ID}')?.remove();
  document.getElementById('xjtu-hot-theme-transition')?.remove();
  const root = document.documentElement;
  root.classList.remove('${ROOT_CLASS}', 'xjtu-conversation-wallpaper');
  delete root.dataset.xjtuTheme;
  delete root.dataset.xjtuThemeMode;
  ${JSON.stringify(VARIABLE_NAMES)}.forEach((name) => root.style.removeProperty(name));
  return true;
})()`;

export const RESTORE_EXPRESSION = `(async () => {
  const { BrowserWindow, app } = require('electron');
  const state = globalThis.__XJTU_HOT_ENGINE__;
  if (state) {
    state.rendererScript = '';
    for (const { contents, handler } of state.handlers?.values?.() || []) {
      try { contents.removeListener('dom-ready', handler); } catch (error) {}
    }
    state.handlers?.clear?.();
    if (state.newWindowHandler) app.removeListener('browser-window-created', state.newWindowHandler);
  }
  const windows = BrowserWindow.getAllWindows().filter((window) => String(window.webContents.getURL() || '').startsWith('app://'));
  const results = await Promise.all(windows.map(async (window) => {
    try { return await window.webContents.executeJavaScript(${JSON.stringify(RESTORE_RENDERER_SCRIPT)}); }
    catch (error) { return false; }
  }));
  delete globalThis.__XJTU_HOT_ENGINE__;
  return results;
})()`;
