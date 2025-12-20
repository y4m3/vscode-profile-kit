PROFILE_DIR := profiles
BUILD_DIR := .build
PYTHON ?= python

.DEFAULT_GOAL := help

.PHONY: help base role all color clean install-extensions

help:
	@echo "Available targets:"
	@echo "  make base                    # Generate base profile definitions"
	@echo "  make role role=<name>        # Generate role profile definitions"
	@echo "  make all                     # Generate all profile definitions"
	@echo "  make install-extensions profile=<name>  # Install extensions to active profile"
	@echo "  make clean                   # Remove build artifacts"
	@echo ""
	@echo "Workflow:"
	@echo "  1. make base (or make role role=<name>)"
	@echo "  2. Create profile in VS Code UI (Ctrl+Shift+P -> Profiles: Create Profile)"
	@echo "  3. Switch to the new profile in VS Code"
	@echo "  4. make install-extensions profile=<name>"
	@echo "  5. Apply settings from .build/<name>-settings.json in VS Code"
	@echo ""
	@echo "Note: On native VS Code (non-WSL), you can use --profile option."
	@echo "      See README for platform-specific instructions."

base:
	@echo "Generating base profile definitions..."
	@$(PYTHON) -c "from pathlib import Path; Path('$(BUILD_DIR)').mkdir(parents=True, exist_ok=True)"
	@$(PYTHON) scripts/jsonc_merge.py $(PROFILE_DIR)/base/settings.jsonc > $(BUILD_DIR)/base-settings.json
	@$(PYTHON) scripts/jsonc_merge.py $(PROFILE_DIR)/base/keybindings.jsonc > $(BUILD_DIR)/base-keybindings.json
	@$(PYTHON) scripts/filter_extensions.py $(BUILD_DIR)/base-extensions.list $(PROFILE_DIR)/base/extensions.txt
	@echo ""
	@echo "Base profile definitions generated:"
	@echo "  Extensions: $(BUILD_DIR)/base-extensions.list"
	@echo "  Settings:   $(BUILD_DIR)/base-settings.json"
	@echo "  Keybindings: $(BUILD_DIR)/base-keybindings.json"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Create 'base' profile in VS Code (Ctrl+Shift+P -> Profiles: Create Profile)"
	@echo "  2. Switch to 'base' profile"
	@echo "  3. Run: make install-extensions profile=base"
	@echo "  4. Apply settings from $(BUILD_DIR)/base-settings.json"
	@echo "  5. Apply keybindings from $(BUILD_DIR)/base-keybindings.json"

role:
ifndef role
	$(error role=<name> is required)
endif
	@echo "Generating profile '$(role)' definitions..."
	@$(PYTHON) -c "from pathlib import Path; Path('$(BUILD_DIR)').mkdir(parents=True, exist_ok=True)"
	@$(PYTHON) scripts/filter_extensions.py $(BUILD_DIR)/$(role)-extensions.list $(PROFILE_DIR)/base/extensions.txt $(PROFILE_DIR)/$(role)/extensions.delta.txt
	@$(PYTHON) scripts/jsonc_merge.py $(PROFILE_DIR)/base/settings.jsonc $(PROFILE_DIR)/$(role)/settings.delta.jsonc > $(BUILD_DIR)/$(role)-settings.json
	@$(PYTHON) scripts/merge_keybindings.py $(PROFILE_DIR)/base/keybindings.jsonc $(PROFILE_DIR)/$(role)/keybindings.delta.jsonc $(BUILD_DIR)/$(role)-keybindings.json
	@echo ""
	@echo "Profile '$(role)' definitions generated:"
	@echo "  Extensions: $(BUILD_DIR)/$(role)-extensions.list"
	@echo "  Settings:   $(BUILD_DIR)/$(role)-settings.json"
	@echo "  Keybindings: $(BUILD_DIR)/$(role)-keybindings.json"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Create '$(role)' profile in VS Code (Ctrl+Shift+P -> Profiles: Create Profile)"
	@echo "  2. Switch to '$(role)' profile"
	@echo "  3. Run: make install-extensions profile=$(role)"
	@echo "  4. Apply settings from $(BUILD_DIR)/$(role)-settings.json"
	@echo "  5. Apply keybindings from $(BUILD_DIR)/$(role)-keybindings.json"

all:
	@echo "Generating all profile definitions..."
	@$(MAKE) base
	@$(PYTHON) -c "import pathlib, subprocess; roles=[p.name for p in pathlib.Path('$(PROFILE_DIR)').iterdir() if p.is_dir() and p.name!='base']; [subprocess.run(['$(MAKE)', 'role', f'role={r}'], check=True) for r in roles]"
	@echo ""
	@echo "All profile definitions generated in $(BUILD_DIR)/"

install-extensions:
ifndef profile
	$(error Error: profile=<name> is required. Usage: make install-extensions profile=base)
endif
	@echo "Installing extensions for profile '$(profile)'..."
	@$(PYTHON) -c "from pathlib import Path; import sys; p=Path('$(BUILD_DIR)/$(profile)-extensions.list'); sys.exit(0) if p.exists() else sys.exit(sys.stderr.write(f'Error: {p} not found.\\nRun \"make base\" or \"make role role=$(profile)\" first.\\n') or 1)"
	@echo "Installing extensions for profile '$(profile)'..."
	@$(PYTHON) -c "import pathlib, subprocess, shutil, sys; code_exe=shutil.which('code'); exts=[l.strip() for l in pathlib.Path('$(BUILD_DIR)/$(profile)-extensions.list').read_text(encoding='utf-8').splitlines() if l.strip()]; sys.exit(sys.stderr.write('Error: VS Code CLI (code) not found in PATH.\\nEnsure VS Code is installed and \"code\" command is available.\\n') or 1) if not code_exe else [subprocess.run([code_exe,'--install-extension', e, '--profile', '$(profile)'], check=False) for e in exts]"
	@echo ""
	@echo "Extensions installed to profile '$(profile)'."
	@echo "Reload VS Code window to see the changes."

clean:
	@echo "Cleaning build artifacts..."
	@$(PYTHON) -c "import shutil; shutil.rmtree('$(BUILD_DIR)', ignore_errors=True)"
	@echo "Build directory cleaned."
