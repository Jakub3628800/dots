# ============================ CONFIGURATION =============================
# Package lists
NODE_PACKAGES := @anthropic-ai/claude-code wrangler @google/gemini-cli
APT_PACKAGES := zsh vim tig gh curl unzip jq direnv python3-virtualenv tmux ripgrep fzf bat nodejs gnupg2
CARGO_PACKAGES := starship
UV_TOOL_PACKAGES := git+https://github.com/Jakub3628800/py-scripts pre-commit

# Helper variables
BUN_PATH_EXPORT := export PATH="$$HOME/.bun/bin:$$PATH"

# ============================ PHONY TARGETS =============================
.PHONY: install update clean test stow
.PHONY: install-stow install-bun install-rust install-uv
.PHONY: node-packages-install node-packages-update
.PHONY: apt-packages-install apt-packages-update
.PHONY: cargo-install cargo-update
.PHONY: uv-tools-install uv-tools-update

# ============================ MAIN TARGETS ==============================

install: apt-packages-install node-packages-install cargo-install uv-tools-install stow

update: apt-packages-update node-packages-update cargo-update uv-tools-update
	@echo "Checking for Rustup updates..."
	@. $$HOME/.cargo/env 2>/dev/null; command -v rustup >/dev/null 2>&1 && rustup update || echo "Rustup not installed yet"
	@echo "Checking for UV updates..."
	@command -v uv >/dev/null 2>&1 && uv self update || echo "UV not installed yet"
	@echo "Checking for Bun updates..."
	@$(BUN_PATH_EXPORT) && command -v bun >/dev/null 2>&1 && bun upgrade || echo "Bun not installed yet"

clean:
	@echo "Unstowing core dotfiles..."
	@stow -v -D -d . -t $(HOME) --no-folding home

test:
	@echo "Building Docker image for testing..."
	@docker build -t core-dotfiles-test .
	@echo "Test build completed successfully!"

stow: install-stow
	@echo "Stowing core dotfiles..."
	@stow -v -d . -t $(HOME) --no-folding home

# ============================ BASE INSTALLERS ===========================

install-stow:
	@echo "Checking for Stow installation..."
	@if ! command -v stow >/dev/null 2>&1; then \
		echo "Installing stow..."; \
		sudo apt-get update && sudo apt-get install -y stow; \
	else \
		echo "Stow is already installed"; \
	fi

install-bun:
	@echo "Checking for Bun installation..."
	@if ! command -v bun >/dev/null 2>&1; then \
		echo "Installing Bun..."; \
		curl -fsSL https://bun.sh/install | bash; \
		export PATH="$$HOME/.bun/bin:$$PATH"; \
	else \
		echo "Bun is already installed"; \
	fi

install-rust:
	@echo "Checking for Rust installation..."
	@if ! command -v rustup >/dev/null 2>&1; then \
		echo "Installing Rust..."; \
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
		. $$HOME/.cargo/env; \
	else \
		echo "Rust is already installed"; \
	fi

install-uv:
	@echo "Checking for UV installation..."
	@if ! command -v uv >/dev/null 2>&1; then \
		echo "Installing UV..."; \
		curl -LsSf https://astral.sh/uv/install.sh | sh; \
	else \
		echo "UV is already installed"; \
	fi

# ============================ NODE PACKAGES =============================

node-packages-install: install-bun
	@echo "Installing Node packages via Bun..."
	@$(BUN_PATH_EXPORT) && bun install -g $(NODE_PACKAGES)

node-packages-update: install-bun
	@echo "Updating Node packages via Bun..."
	@$(BUN_PATH_EXPORT) && bun update -g $(NODE_PACKAGES)

# ============================ APT PACKAGES ==============================

apt-packages-install:
	@sudo apt-get update
	@sudo apt-get install -y $(APT_PACKAGES)

apt-packages-update:
	@sudo apt-get update
	@sudo apt-get upgrade -y

# ============================ RUST PACKAGES =============================

cargo-install: install-rust
	@. $$HOME/.cargo/env && \
		for pkg in $(CARGO_PACKAGES); do \
			if ! command -v $$pkg >/dev/null 2>&1; then \
				echo "Installing $$pkg..."; \
				cargo install $$pkg --locked; \
			else \
				echo "$$pkg is already installed"; \
			fi; \
		done

cargo-update: install-rust
	@. $$HOME/.cargo/env && \
		for pkg in $(CARGO_PACKAGES); do \
			echo "Updating $$pkg..."; \
			cargo install $$pkg --locked --force; \
		done

# ============================ UV TOOLS ==================================

uv-tools-install: install-uv
	@for tool in $(UV_TOOL_PACKAGES); do \
		uv tool install $$tool || { echo "Failed to install $$tool"; exit 1; }; \
	done

uv-tools-update: install-uv
	@uv tool upgrade --all || echo "Failed to upgrade UV tools"
