# Use a stable Ubuntu base image
FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install core dependencies and add Neovim stable PPA
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    ca-certificates \
    unzip \
    build-essential \
    locales \
    software-properties-common \
    gpg-agent \
    && add-apt-repository -y ppa:neovim-ppa/stable \
    && apt-get update \
    && apt-get install -y --no-install-recommends neovim \
    && rm -rf /var/lib/apt/lists/*

# Set up locales for correct terminal character encoding
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install the Antigravity CLI (agy)
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash

# Add agy binary directory to PATH
ENV PATH="/root/.local/bin:${PATH}"

# Set up Neovim configuration directory and automatic plugin loading
RUN mkdir -p /root/.config/nvim
RUN mkdir -p /root/.local/share/nvim/site/pack/plugins/start/antigravity.nvim

# Copy the plugin source code into the auto-load path
COPY lua/ /root/.local/share/nvim/site/pack/plugins/start/antigravity.nvim/lua/
COPY plugin/ /root/.local/share/nvim/site/pack/plugins/start/antigravity.nvim/plugin/

# Create a test workspace directory
WORKDIR /workspace

# Copy the repository code into the workspace for testing
COPY . /workspace

# Default command is to open Neovim
CMD ["nvim"]
