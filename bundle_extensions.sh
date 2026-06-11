#!/usr/bin/env bash
# THUZTRA: inject the Thuztra extension stack as built-in extensions so a
# fresh install works out of the box (see THUZTRA.md). Runs between the
# package step (which produces VSCode-win32-${VSCODE_ARCH}) and
# prepare_assets.sh (which zips that folder and builds the installers
# from it), so the bundled extensions ride into every deliverable.
#
# The set is the closed dependency graph: ruff declares an
# extensionDependency on ms-python.python, and basedpyright requires the
# python extension's API at activation (fails without it) — so the
# ms-python trio (python + debugpy + vscode-python-envs) must ship too,
# or nothing activates on a machine that can't reach Open VSX.
# ms-python.python's extensionPack mentions Pylance, but pack entries are
# not dependencies and aren't auto-installed for builtins (Pylance is
# proprietary and stays out — basedpyright is the language server).
#
# Everything below is fetched from Open VSX pinned by version AND
# sha256 — when bumping a version, recompute the hash:
#   curl -fsSL <url> | sha256sum
# The thuztra extension itself is the committed vsix in
# bundled-extensions/ (built from thuztra-in/vscode-extension; rebuild
# with `npm run package` there and copy it over when it changes).
#
# Windows-only for now. Extraction uses python (the workflow's
# setup-python step provides it) so the script runs identically on a
# local machine for testing. Revisit when macOS/Linux builds land.

set -ex

THUZTRA_VSIX="bundled-extensions/thuztra-0.2.1.vsix"

# target-dir|url|sha256
PINNED="\
ms-python.python-2026.4.0|https://open-vsx.org/api/ms-python/python/2026.4.0/file/ms-python.python-2026.4.0.vsix|232aeafb01f069824fdd92d3e628c1c442bbcfa1d3cc945ff97076340bb2b4a6
ms-python.debugpy-2026.6.0|https://open-vsx.org/api/ms-python/debugpy/win32-x64/2026.6.0/file/ms-python.debugpy-2026.6.0@win32-x64.vsix|f4a8ba033acc9a1e14bf53f124d8d0848318702bbb161f2a5e47ae3d3d756a67
ms-python.vscode-python-envs-1.30.0|https://open-vsx.org/api/ms-python/vscode-python-envs/1.30.0/file/ms-python.vscode-python-envs-1.30.0.vsix|381ce9e6c2e44955146711fb92d3f36b9c4c53c142bcc7b6992bc97b1366d262
detachhead.basedpyright-1.39.7|https://open-vsx.org/api/detachhead/basedpyright/1.39.7/file/detachhead.basedpyright-1.39.7.vsix|866e630dc0556917e6ce10d35c53a945e376dbb945c984ff8be1c63dca5d917d
charliermarsh.ruff-2026.50.0|https://open-vsx.org/api/charliermarsh/ruff/win32-x64/2026.50.0/file/charliermarsh.ruff-2026.50.0@win32-x64.vsix|8bd632bd5d417ce10c168ca66fe8a4bbb758395f067464fba59bd95b1032285f"

EXT_DIR="VSCode-win32-${VSCODE_ARCH}/resources/app/extensions"

[[ -d "${EXT_DIR}" ]] || { echo "'${EXT_DIR}' not found — run after the package step"; exit 1; }

bundle() { # <vsix> <target-dir-name>  (a vsix is a zip; the payload is its extension/ subtree)
  local staging="staging-$2"
  rm -rf "${staging}" "${EXT_DIR:?}/$2"
  python -c "import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$1" "${staging}"
  mv "${staging}/extension" "${EXT_DIR}/$2"
  rm -rf "${staging}"
}

while IFS='|' read -r dir url sha; do
  curl -fsSL --retry 3 -o pinned.vsix "${url}"
  echo "${sha}  pinned.vsix" | sha256sum -c -
  bundle pinned.vsix "${dir}"
  rm -f pinned.vsix
done <<< "${PINNED}"

bundle "${THUZTRA_VSIX}" "thuztra.thuztra-0.2.1"
