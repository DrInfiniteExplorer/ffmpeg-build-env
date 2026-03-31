# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04

# Install build tools
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y \
    autoconf automake autopoint build-essential libarchive-tools \
    cmake git-core gperf g++-mingw-w64 libssl-dev libtool \
    libunwind-dev mercurial meson nasm pkg-config python3-lxml \
    ragel subversion texinfo yasm wget win-iconv-mingw-w64-dev \
    rsync

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y curl build-essential musl-tools

# Rust: keep TMPDIR under RUSTUP_HOME so rustup never rename(2)s across filesystems (fixes EXDEV in Docker).
ENV RUSTUP_HOME=/root/.rustup
ENV CARGO_HOME=/root/.cargo
ENV TMPDIR=/root/.rustup/tmp

# Install Rust toolchain in one step
RUN mkdir -p /root/.rustup/tmp && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . $HOME/.cargo/env && \
    rustup install 1.93.0 && \
    rustup default 1.93.0 && \
    cargo install --version 0.10.20+cargo-0.94.0 cargo-c && \
    rustup target add x86_64-pc-windows-gnu x86_64-unknown-linux-musl

# Native host (GNU) Rust toolchain — separate channel from the pinned default; stacks with cross targets.
# Default remains 1.93.0; use e.g. `cargo +stable build` for stable-channel native builds.
RUN mkdir -p /root/.rustup/tmp && \
    . $HOME/.cargo/env && \
    rustup toolchain install stable

WORKDIR /ffmpeg


# CMD ffmpeg-cxc-mingw64


