# Thuztra IDE — fork notes

This repo is **VSCodium's build harness** (upstream:
https://github.com/VSCodium/vscodium) carrying the *minimum* diff needed
to produce a Thuztra-branded build. The product code lives in
[thuztra-in](https://github.com/thuztra/thuztra-in) (web app + the
`vscode-extension/` thin layer); this repo only builds the desktop shell.

## The complete diff over upstream

1. **`prepare_vscode.sh`** — the stable-quality identity block
   (`nameShort`/`nameLong`/`applicationName` → Thuztra/thuztra,
   `dataFolderName` `.thuztra`, `urlProtocol` `thuztra`,
   `darwinBundleIdentifier` `in.thuztra.ide`, all `win32*` names, fresh
   GUIDs for every `win32*AppId` + context-menu CLSIDs — VSCodium's
   GUIDs would collide in the registry), plus `licenseUrl` and
   `reportIssueUrl` pointing here. The insider block is untouched (we
   only build stable).
2. **Icons** — Thuztra mark (orange `#FF4F00` rounded square, white
   path-drawn "T") replaces the generated artifacts:
   `src/stable/resources/win32/code.ico`, `win32/code_70x70.png`,
   `win32/code_150x150.png`, `linux/code.png`, `linux/code.svg`,
   `server/code-192.png`, `server/code-512.png`, `server/favicon.ico`.
   NOT yet rebranded: macOS `code.icns`, the Inno installer bitmaps
   (`win32/inno-*.bmp`), and the per-filetype icons — all still stock.
3. **`.github/workflows/`** — upstream's workflows are deleted (their
   ci-builds fire on every push across 3 OSes; their publish workflows
   need SignPath/winget secrets we don't have). One replacement:
   `build-windows.yml` (manual dispatch, stable, x64, artifact-only,
   `DISABLE_UPDATE=yes` so the build never points at VSCodium's update
   server).
4. **`README.md`** — Thuztra header prepended.
5. This file.

## Building

GitHub → Actions → "Build - Windows" → Run workflow. ~1.5–2.5 h; the
`bin-x64` artifact contains the unsigned installers
(`ThuztraUserSetup-x64-*.exe` etc.).

## Rebasing on upstream (do monthly — VS Code releases monthly)

```
git fetch upstream
git rebase upstream/master
```

Conflicts can only occur in the five places listed above. If
`prepare_vscode.sh` conflicts, re-apply the Thuztra block onto their new
version (keep OUR GUIDs). If their patches/ fail against a new VS Code,
that's upstream's problem to fix first — wait for their master to go
green before rebasing.

## Beta-gated (not yet done)

Code signing (SignPath or cert), auto-update infra (`updateUrl` +
versions repo), macOS/Linux builds + icns, installer bitmaps, bundling
the thuztra extension + basedpyright + Ruff into the build (today they
install from Open VSX / the extension's `extensionPack`).
