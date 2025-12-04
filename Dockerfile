FROM buildpack-deps:trixie AS base

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash-completion \
    cmake \
    clang \
    python3 \
    qemu-system && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Install Musl toolchains for all supported architectures
# Download prebuilt toolchains from arceos-org/setup-musl (prebuilt release)
RUN mkdir -p /opt && \
    cd /opt && \
    for arch in x86_64 aarch64 riscv64 loongarch64; do \
        curl -f -L "https://github.com/arceos-org/setup-musl/releases/download/prebuilt/${arch}-linux-musl-cross.tgz" -O && \
        tar -xvzf "${arch}-linux-musl-cross.tgz" && \
        rm "${arch}-linux-musl-cross.tgz" && \
        echo "export PATH=/opt/${arch}-linux-musl-cross/bin:\$PATH" >> /etc/profile.d/musl-toolchains.sh; \
    done

ENV PATH="/opt/x86_64-linux-musl-cross/bin:/opt/aarch64-linux-musl-cross/bin:/opt/riscv64-linux-musl-cross/bin:/opt/loongarch64-linux-musl-cross/bin:${PATH}"

# Setup Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    --profile default \
    --default-toolchain nightly-2025-05-20 \
    --target x86_64-unknown-none,riscv64gc-unknown-none-elf,aarch64-unknown-none-softfloat,loongarch64-unknown-none-softfloat \
    --component rust-src,rustfmt,clippy,llvm-tools

ENV PATH=/root/.cargo/bin:$PATH

# Install binary dependencies
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    cargo install cargo-binutils cargo-axplat axconfig-gen

CMD ["bash", "-l"]
