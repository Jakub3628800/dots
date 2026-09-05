# This Dockerfile is only for testing the core package installation
FROM ubuntu:24.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install make, sudo and build-essential (required for installation)
RUN apt-get update && \
    apt-get install --no-install-recommends -y make sudo build-essential ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Allocate a free UID; Ubuntu 24.04 already assigns UID 1000 to ubuntu.
RUN useradd -m -s /bin/bash testuser && \
    usermod -aG sudo testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy the core package files
WORKDIR /tmp/core
COPY . .
RUN chown -R testuser:testuser /tmp/core

# Resolve the dynamically allocated UID inside this bootstrap-test image.
# hadolint ignore=DL3066
USER testuser
WORKDIR /tmp/core

# Add Cargo to PATH for installation
ENV PATH="/home/testuser/.local/bin:/home/testuser/.cargo/bin:${PATH}"

# Run the installation
RUN make packages && \
    make stow

# Verify installation
RUN command -v uv && \
    command -v prek && \
    command -v starship && \
    command -v delta && \
    command -v zsh && \
    command -v tig && \
    test -f ~/.profile && \
    test -f ~/.zshrc && \
    test -f ~/.bash_aliases

CMD ["/bin/zsh"]
