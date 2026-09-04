# Moonshot Intel

Research artifacts for Kimi / Moonshot AI ecosystem (Code API, Platform API, OAuth, architecture).

See [`moonshot-intel/error-matrix.json`](moonshot-intel/error-matrix.json) for the master index.

## Research notes

- [`local-inference/k3-in-c-analysis.md`](moonshot-intel/local-inference/k3-in-c-analysis.md) --
  running the full 2.78T Kimi K3 checkpoint on CPU via `kimi-k3-in-c`, reproduced build and
  test results, and why local K3 on Android is storage-bound rather than compute-bound.

## Cursor Cloud Agent

This repo is set up for **Build in Cloud**. Requirements:

1. GitHub remote on `origin` (see setup script below)
2. Cursor logged in + GitHub connected in Settings
3. Latest Cursor version

```powershell
powershell -ExecutionPolicy Bypass -File moonshot-intel\scripts\setup-github-remote.ps1 -GitHubUser YOUR_GITHUB_USERNAME
```

Then **Developer: Reload Window** and click **Build in Cloud** on the plan.
