# This Dockerfile is only for testing the desktop package installation
FROM ubuntu:24.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install make, sudo, and stow (required for installation)
RUN apt-get update && \
    apt-get install --no-install-recommends -y make sudo stow jq ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Allocate a free UID; Ubuntu 24.04 already assigns UID 1000 to ubuntu.
RUN useradd -m -s /bin/bash testuser && \
    usermod -aG sudo testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy the desktop package files
WORKDIR /tmp/desktop
COPY . .
RUN chown -R testuser:testuser /tmp/desktop

# Resolve the dynamically allocated UID inside this bootstrap-test image.
# hadolint ignore=DL3066
USER testuser
WORKDIR /tmp/desktop

# Set Wayland session for testing (skip the check)
ENV XDG_SESSION_TYPE=wayland

# Run the installation
RUN make packages && \
    make stow

# Verify installation
RUN command -v sway && \
    command -v bemenu && \
    command -v grim && \
    command -v slurp && \
    command -v wl-copy && \
    command -v i3status && \
    command -v pactl && \
    command -v pass && \
    command -v swaylock && \
    test -f ~/.config/sway/config

CMD ["/bin/bash"]
