# VS Code Profile Kit

Declarative VS Code profile management using base profile + role deltas, with Make as the single interface.

## Quick Start

1. **Generate profile definitions**

   ```bash
   make base              # Generate base profile
   make role role=example # Generate example role profile
   make all               # Generate all profiles
   ```

2. **Create profile in VS Code**
   - Open Command Palette (Ctrl+Shift+P)
   - Select "Profiles: Create Profile"
   - Name it (e.g., "base", "example")

3. **Switch to the profile in VS Code**
   - Click profile icon in bottom-left corner
   - Select your profile

4. **Install extensions**

   ```bash
   make install-extensions profile=example
   ```

5. **Apply settings**
   - Open VS Code settings (Ctrl+,)
   - Click "Open Settings (JSON)" icon
   - Copy content from `.build/example-settings.json`

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
    - `merge_keybindings.py` — Merge base keybindings with role-specific delta
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
