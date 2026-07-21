# Security policy

## Supported environment

The no-restart engine is experimental and currently verified only with Microsoft Store Codex `26.715.7063.0` on Windows. Treat other versions as unverified until `doctor`, unit tests, DryRun, a guarded preview, `verify`, and `disable` all pass.

## Inspector boundary

The engine briefly opens the Codex main-process Node Inspector on `127.0.0.1:9229`. It must verify the attached process ID, inject only local project assets, and close the Inspector after each operation. Do not remove the PID check, allow remote binding, or keep the Inspector open persistently.

## Reporting a vulnerability

Use the repository hosting platform's private security-advisory feature when available. Do not publish working exploitation details, credentials, private Codex data, or another user's local paths in a public issue.

Include:

- Codex and Windows versions;
- the exact command and first relevant error;
- whether ports 9229 or 9335 remained open;
- whether `disable` recovered the renderer;
- a minimal reproduction without credentials or conversation content.

## Sensitive information

Never attach Codex configuration containing secrets, browser profiles, cookies, authentication files, API keys, or full conversation logs. Redact usernames and absolute paths when they are not essential to the report.
