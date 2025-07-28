# This Dockerfile is only for testing the core package installation
FROM ubuntu:24.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install make and sudo (required for installation)
RUN apt-get update && apt-get install -y make sudo

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

# Run the installation (install everything except stow first)
RUN cd /tmp/core && \
    make install-stow apt-packages-install install-uv install-bun node-packages-install uv-tools-install && \
    rm -f ~/.profile ~/.zshrc ~/.bashrc && \
    make stow

# Set shell to zsh (if installation was successful)
SHELL ["/bin/zsh", "-c"]

# Add UV and Bun to PATH and verify installation
ENV PATH="/home/testuser/.local/bin:/home/testuser/.bun/bin:${PATH}"
RUN command -v uv && \
    command -v bun && \
    command -v claude && \
    command -v zsh && \
    command -v tig && \
    test -f ~/.vimrc && \
    test -f ~/.zshrc && \
    test -f ~/.bash_aliases

CMD ["/bin/zsh"]