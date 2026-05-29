# This Dockerfile is only for testing the core package installation
FROM ubuntu:24.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install make, sudo and build-essential (required for installation)
RUN apt-get update && \
    apt-get install --no-install-recommends -y make sudo build-essential ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create a test user with home directory and add to sudo group
RUN useradd -m -s /bin/bash testuser && \
    usermod -aG sudo testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy the core package files
WORKDIR /tmp/core
COPY . .
RUN chown -R testuser:testuser /tmp/core

# Switch to test user for installation
USER testuser
WORKDIR /home/testuser

# Add Cargo to PATH for installation
ENV PATH="/home/testuser/.local/bin:/home/testuser/.cargo/bin:${PATH}"

# Run the installation
RUN cd /tmp/core && \
    make apt-packages-install cargo-install && \
    rm -f ~/.profile && \
    make stow

# Set shell to zsh (if installation was successful)
SHELL ["/bin/zsh", "-c"]
RUN command -v uv && \
    command -v prek && \
    command -v starship && \
    command -v delta && \
    command -v zsh && \
    command -v tig && \
    test -f ~/.zshrc && \
    test -f ~/.bash_aliases

CMD ["/bin/zsh"]
