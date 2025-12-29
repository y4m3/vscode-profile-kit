# VS Code Profile Kit

Declarative VS Code profile management using base profile + role deltas, with Make as the single interface.

## Prerequisites

- **Python 3.8+**: Required for running build scripts
- **VS Code CLI**: The `code` command must be available in your PATH
  - Install via VS Code: Open Command Palette (`Ctrl+Shift+P`) → "Shell Command: Install 'code' command in PATH"
  - Or see [VS Code CLI documentation](https://code.visualstudio.com/docs/editor/command-line)
- **typing_extensions** (optional): Recommended for PEP 727 compliance
  - Install with: `pip install typing_extensions`
  - Scripts will work without it, but with reduced type annotation support

## Quick Start

1. **Generate profile definitions**

   ```bash
   make base              # Generate base profile
   make role role=python  # Generate python role profile
   make all               # Generate all profiles
   ```

2. **Create profile in VS Code**
   - Open Command Palette (Ctrl+Shift+P)
   - Select "Profiles: Create Profile"
   - Name it (e.g., "base", "python")

3. **Switch to the profile in VS Code**
   - Click profile icon in bottom-left corner
   - Select your profile

4. **Install extensions**

   ```bash
   make install-extensions profile=python
   ```

5. **Apply settings and keybindings**
   - **Settings**: Open VS Code settings (Ctrl+,)
     - Click "Open Settings (JSON)" icon
     - Copy content from `.build/python-settings.json`
   - **Keybindings**: Open Command Palette (`Ctrl+Shift+P`)
     - Select "Preferences: Open Keyboard Shortcuts (JSON)"
     - Copy content from `.build/python-keybindings.json`

## Repository Structure

- `profiles/base/` — Base profile shared by all roles
    - `extensions.txt` — Required extensions for all profiles (categorized by functionality)
    - `settings.jsonc` — Common settings (JSONC, comments allowed)
    - `keybindings.jsonc` — Keyboard shortcuts (Ctrl+Space commands, explorer operations)
- `profiles/<role>/` — Role-specific deltas
    - `extensions.delta.txt` — Additional extensions for this role
    - `settings.delta.jsonc` — Role-specific settings (JSONC, comments allowed, merged with base)
    - `keybindings.delta.jsonc` — Role-specific keybindings (optional, replaces base if provided)
- `profiles/python/` — Python data science profile (example role)
    - Includes: Ruff, uv, marimo, Jupyter extensions
    - Settings: Python inlay hints, pytest, notebook configurations
- `workspace-templates/` — Local settings templates (Git managed)
    - `settings.local.sample.jsonc` — Machine-specific settings sample (fonts, UI scale)
    - `theme.sample.jsonc` — Color theme examples
    - `local/` — Local output directory (gitignored)
- `scripts/` — Build utilities
    - `jsonc_merge.py` — Deep merge JSONC files (PEP 727 compliant)
    - `filter_extensions.py` — Filter and merge extension list files (ignore comments/blank lines)
    - `merge_keybindings.py` — Merge base keybindings with role-specific delta (depends on `jsonc_merge.py` for `strip_jsonc` function)
- `.build/` — Generated profile definitions (gitignored)

## Make Targets

- `make` or `make help` — Show usage help
- `make base` — Generate base profile definitions
- `make role role=python` (or any role name) — Generate role profile definitions (base + delta merged)
    - Required parameter: `role=<name>` must be specified explicitly
- `make all` — Generate all profile definitions for base and all roles
- `make install-extensions profile=python` (or any profile name) — Install extensions for current session
    - Required parameter: `profile=<name>` must be specified explicitly
- `make clean` — Remove build artifacts

## Design Principles

1. **Declarative Management**: Git manages only definitions, not VS Code internals
2. **Base + Delta Model**: Base is common foundation, roles add deltas
3. **Make as Interface**: All operations via Make, no manual steps in workflow
4. **Profile Isolation**: Each role is a complete, independent VS Code profile

See `dev_memo/design_doc.md` for detailed design documentation (Japanese).

## Example Workflow

```bash
# Generate all profile definitions
make all

# Create "python" profile in VS Code UI
# Switch to "python" profile

# Install extensions
make install-extensions profile=python

# Apply settings from .build/python-settings.json
# Apply keybindings from .build/python-keybindings.json
```

## Key Features

### Base Profile

- **Vim Integration**: VSCodeVim with accelerated cursor movement (j/k acceleration)
- **Keybindings**: Ctrl+Space command palette, NERDTree-style explorer (a/m/d/y/p)
- **AI & Copilot**: GitHub Copilot with Japanese locale and MCP server support
- **Markdown**: MarkdownLint, preview enhanced, table of contents
- **Code Quality**: ErrorLens, spell checker, better comments highlighting
- **Development Tools**: Docker, EditorConfig, Remote extensions, Makefile tools
- **Appearance**: Section 9 theme, Nomo Dark icons, indent guide colors

### Python Profile (Example Role)

- **Linting & Formatting**: Ruff (fast Python linter/formatter)
- **Notebooks**: Marimo, Jupyter with renderers
- **Package Management**: uv (fast Python package installer)
- **Type Hints**: Comprehensive inlay hints for variables, parameters, returns
- **Testing**: Pytest integration with default configuration

## Notes

### Local Overrides (Developer Experience)

Base profiles intentionally avoid machine-specific settings. For per-machine tuning (fonts, UI scale, etc.), use the local template:

- Template: [workspace-templates/settings.local.sample.jsonc](workspace-templates/settings.local.sample.jsonc)
- Copy relevant lines into your VS Code User settings (do not commit personal overrides).

Examples included:

- Editor fonts (`editor.fontFamily`, ligatures, size)
- Terminal / Debug Console / Notebook fonts
- UI scale (`window.zoomLevel`), cursor preferences

Tip: Keep local-only changes out of Git to preserve portability.

### Platform Differences

**Native VS Code (Windows/macOS/Linux)**

- Supports `--profile` option for direct profile management
- Can automate profile creation: `code --profile <name> --install-extension <ext>`
- More streamlined workflow possible

**VS Code in WSL**

- `--profile` option not available in WSL CLI
- Requires manual profile creation/switching in UI
- Extensions install to currently active profile only

**Cursor**

- Cursor cannot directly access VS Code Marketplace
- `make install-extensions` does not work with Cursor (requires VS Code CLI)
- **Workflow for Cursor users:**
  1. Generate profile definitions as usual: `make base` or `make role role=python`
  2. Create and switch to the profile in Cursor UI
  3. For each extension in `.build/<profile>-extensions.list`:
     - Download VSIX file using the Marketplace URL format:
       ```
       https://marketplace.visualstudio.com/_apis/public/gallery/publishers/{publisher}/vsextensions/{extension}/{version}/vspackage
       ```
     - Find the version on [Marketplace](https://marketplace.visualstudio.com/items?itemName={publisher}.{extension})
     - Example for `y4m3.section9-theme` (version 0.0.1):
       ```
       https://marketplace.visualstudio.com/_apis/public/gallery/publishers/y4m3/vsextensions/section9-theme/0.0.1/vspackage
       ```
     - Install in Cursor: Command Palette (`Ctrl+Shift+P`) → "Extensions: Install from VSIX..." → Select the VSIX file
  4. Apply settings and keybindings as described in Quick Start
- Alternative: Build VSIX from source using `vsce package` if the extension repository is available

### Extension List Format

- Extensions are organized by category (Editor, AI, Markdown, Git, etc.)
- Comments starting with `#` in `.txt` files are ignored
- Empty lines in `.txt` files are ignored
- One extension ID per line (format: `publisher.extension`)
- Base extensions include common tools; role extensions add specialized functionality

### Settings & Keybindings Merge

- **Settings**: Defined as JSONC; comments are allowed in `*.jsonc`
    - Merge is done via `scripts/jsonc_merge.py` (PEP 727 compliant with type annotations)
    - Delta overwrites base; arrays are replaced (not merged)
    - Output JSON is emitted to `.build/<name>-settings.json`
- **Keybindings**: Managed separately in `keybindings.jsonc` files
    - Base keybindings: `profiles/base/keybindings.jsonc`
    - Role-specific keybindings (optional): `profiles/<role>/keybindings.delta.jsonc`
    - Merge is done via `scripts/merge_keybindings.py`
    - If role has `keybindings.delta.jsonc`, it replaces base keybindings; otherwise base keybindings are used
    - Output JSON is emitted to `.build/<name>-keybindings.json`

### Color Themes

Use VS Code's built-in color theme system instead of workspace color customizations:

- Set `workbench.colorTheme` in your profile settings or User settings
- Browse themes: Command Palette → "Preferences: Color Theme"
- Install theme extensions from the Marketplace as needed

## Troubleshooting

### `code` command not found

- **VS Code**: Install CLI via Command Palette → "Shell Command: Install 'code' command in PATH"
- **WSL**: The `code` command may not be available. Use manual extension installation or switch to native VS Code
- **Cursor**: The `code` command is not available. Use VSIX file installation method (see Platform Differences)

### Extension installation fails

- Ensure you're using the correct profile name (case-sensitive)
- Verify the profile exists in VS Code: Check bottom-left corner for profile name
- For Cursor users: Use VSIX file installation method instead of `make install-extensions`
- Check that `.build/<profile>-extensions.list` exists (run `make base` or `make role role=<name>` first)

### Profile not found

- Create the profile in VS Code UI first: Command Palette → "Profiles: Create Profile"
- Ensure the profile name matches exactly (case-sensitive)
- Switch to the profile before running `make install-extensions`

### Python script execution errors

- Verify Python 3.8+ is installed: `python --version` or `python3 --version`
- Check script permissions: Scripts should be executable (`chmod +x scripts/*.py` on Unix)
- For `typing_extensions` import warnings: Install with `pip install typing_extensions` (optional but recommended)
- Ensure scripts are run from the repository root directory
