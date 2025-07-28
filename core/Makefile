.PHONY: install update test clean
.PHONY: install-uv install-bun install-stow
.PHONY: node-packages-install node-packages-update apt-packages-install apt-packages-update uv-tools-install uv-tools-update

install: install-stow apt-packages-install install-uv install-bun node-packages-install uv-tools-install stow

update: apt-packages-update node-packages-update uv-tools-update
	@echo "Checking for UV updates..."
	@command -v uv >/dev/null 2>&1 && uv self update || echo "UV not installed yet"
	@echo "Checking for Bun updates..."
	@export PATH="$$HOME/.bun/bin:$$PATH" && command -v bun >/dev/null 2>&1 && bun upgrade || echo "Bun not installed yet"

# =======================================================================================

install-stow:
	@if ! command -v stow >/dev/null 2>&1; then \
		echo "Installing stow..."; \
		sudo apt-get update && sudo apt-get install -y stow; \
	else \
		echo "Stow is already installed"; \
	fi

install-uv:
	@echo "Checking for UV installation..."
	@if ! command -v uv >/dev/null 2>&1; then \
		echo "Installing UV..."; \
		curl -LsSf https://astral.sh/uv/install.sh | sh; \
		export PATH="$$HOME/.local/bin:$$PATH"; \
	else \
		echo "UV is already installed"; \
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

node-packages-install: install-bun
	@echo "Installing Node packages via Bun..."
	@export PATH="$$HOME/.bun/bin:$$PATH" && \
		jq -r '.npm[]' packages.json | xargs -I {} bun install -g {}

node-packages-update: install-bun
	@echo "Updating Node packages via Bun..."
	@export PATH="$$HOME/.bun/bin:$$PATH" && \
		jq -r '.npm[]' packages.json | xargs -I {} bun update -g {}

apt-packages-install:
	@echo "Installing core APT packages..."
	@jq -c '.apt[]' packages.json | while read -r item; do \
		if echo "$$item" | jq -e 'type == "array"' >/dev/null 2>&1; then \
			echo "$$item" | jq -r '.[]' | while read -r pkg; do \
				if sudo apt-get install -y "$$pkg" 2>/dev/null; then \
					echo "Successfully installed $$pkg"; \
					break; \
				fi; \
			done; \
		else \
			pkg=$$(echo "$$item" | jq -r '.'); \
			sudo apt-get install -y "$$pkg"; \
		fi; \
	done

apt-packages-update:
	@echo "Updating APT package lists..."
	@sudo apt-get update
	@echo "Upgrading installed packages..."
	@sudo apt-get upgrade -y

uv-tools-install: install-uv
	@echo "Installing UV tools..."
	@export PATH="$$HOME/.local/bin:$$PATH" && \
		jq -r '.["uv-tool"][]' packages.json | while read -r tool; do \
			echo "Installing $$tool..."; \
			uv tool install $$tool; \
		done

uv-tools-update: install-uv
	@echo "Updating UV tools..."
	@export PATH="$$HOME/.local/bin:$$PATH" && \
		jq -r '.["uv-tool"][]' packages.json | while read -r tool; do \
			echo "Updating $$tool..."; \
			uv tool upgrade $$tool || uv tool install --upgrade $$tool; \
		done

STOW_FLAGS ?=
stow:
	@echo "Stowing core dotfiles..."
	@stow -v -d . -t $(HOME) --no-folding $(STOW_FLAGS) home

clean:
	@echo "Unstowing core dotfiles..."
	@stow -v -D -d . -t $(HOME) home

test:
	@echo "Building Docker image for testing..."
	@docker build -t core-dotfiles-test .
	@echo "Test build completed successfully!"
	@echo "To run the container: docker run -it --rm core-dotfiles-test"
