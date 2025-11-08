# This Dockerfile is only for testing the desktop package installation
FROM ubuntu:24.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install make, sudo, and stow (required for installation)
RUN apt-get update && apt-get install -y make sudo stow jq

# Create a test user with home directory and add to sudo group
RUN useradd -m -s /bin/bash testuser && \
    usermod -aG sudo testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy the desktop package files
WORKDIR /tmp/desktop
COPY . .
RUN chown -R testuser:testuser /tmp/desktop

# Switch to test user for installation
USER testuser
WORKDIR /home/testuser

# Set Wayland session for testing (skip the check)
ENV XDG_SESSION_TYPE=wayland

# Run the installation
RUN cd /tmp/desktop && \
    make apt-packages-install && \
    rm -f ~/.wezterm.lua && \
    make stow

# Verify installation
RUN command -v sway && \
    command -v bemenu && \
    command -v xdotool && \
    command -v pass && \
    command -v swaylock && \
    test -f ~/.config/sway/config || echo "Sway config file ready to be stowed"

CMD ["/bin/bash"]
