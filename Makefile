PROFILE_DIR := profiles
BUILD_DIR := .build

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
	@mkdir -p $(BUILD_DIR)
	@python3 scripts/jsonc_merge.py $(PROFILE_DIR)/base/settings.jsonc > $(BUILD_DIR)/base-settings.json
	@python3 scripts/jsonc_merge.py $(PROFILE_DIR)/base/keybindings.jsonc > $(BUILD_DIR)/base-keybindings.json
	@grep -v '^#' $(PROFILE_DIR)/base/extensions.txt | grep -v '^$$' > $(BUILD_DIR)/base-extensions.list
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
	@mkdir -p $(BUILD_DIR)
	@grep -v '^#' $(PROFILE_DIR)/base/extensions.txt | grep -v '^$$' > $(BUILD_DIR)/$(role)-extensions.list
	@grep -v '^#' $(PROFILE_DIR)/$(role)/extensions.delta.txt | grep -v '^$$' >> $(BUILD_DIR)/$(role)-extensions.list
	@python3 scripts/jsonc_merge.py $(PROFILE_DIR)/base/settings.jsonc $(PROFILE_DIR)/$(role)/settings.delta.jsonc > $(BUILD_DIR)/$(role)-settings.json
	@if [ -f $(PROFILE_DIR)/$(role)/keybindings.delta.jsonc ]; then \
		python3 scripts/jsonc_merge.py $(PROFILE_DIR)/base/keybindings.jsonc $(PROFILE_DIR)/$(role)/keybindings.delta.jsonc > $(BUILD_DIR)/$(role)-keybindings.json; \
	else \
		python3 scripts/jsonc_merge.py $(PROFILE_DIR)/base/keybindings.jsonc > $(BUILD_DIR)/$(role)-keybindings.json; \
	fi
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
	@for dir in $(PROFILE_DIR)/*/; do \
		profile=$$(basename $$dir); \
		if [ "$$profile" != "base" ]; then \
			echo ""; \
			$(MAKE) role role=$$profile; \
		fi \
	done
	@echo ""
	@echo "All profile definitions generated in $(BUILD_DIR)/"

install-extensions:
ifndef profile
	$(error profile=<name> is required)
endif
	@echo "Installing extensions for profile '$(profile)'..."
	@if [ ! -f $(BUILD_DIR)/$(profile)-extensions.list ]; then \
		echo "Error: $(BUILD_DIR)/$(profile)-extensions.list not found."; \
		echo "Run 'make base' or 'make role role=$(profile)' first."; \
		exit 1; \
	fi
	@echo "Make sure you have switched to the '$(profile)' profile in VS Code!"
	@read -p "Press Enter to continue (Ctrl+C to cancel)..." dummy
	@cat $(BUILD_DIR)/$(profile)-extensions.list | xargs -r -I{} code --install-extension {}
	@echo ""
	@echo "Extensions installed to current VS Code profile."
	@echo "If you need to reinstall, switch to the profile and run this command again."

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@echo "Build directory cleaned."
