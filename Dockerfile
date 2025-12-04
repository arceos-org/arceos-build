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
RUN mkdir -p /opt/toolchains && \
    cd /opt/toolchains && \
    for arch in x86_64 aarch64 riscv64 loongarch64; do \
    curl -f -L "https://github.com/arceos-org/setup-musl/releases/download/prebuilt/${arch}-linux-musl-cross.tgz" -o "${arch}-linux-musl-cross.tgz" && \
    tar -xzf "${arch}-linux-musl-cross.tgz" && \
    rm "${arch}-linux-musl-cross.tgz" && \
    echo "export PATH=/opt/toolchains/${arch}-linux-musl-cross/bin:\$PATH" >> /etc/profile.d/musl-toolchains.sh; \
    done

# Setup Rust toolchain
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    --profile default \
    --default-toolchain nightly-2025-05-20 \
    --target x86_64-unknown-none,riscv64gc-unknown-none-elf,aarch64-unknown-none-softfloat,loongarch64-unknown-none-softfloat \
    --component rust-src,rustfmt,clippy,llvm-tools && \
    rustup show

# Install binary dependencies
RUN cargo install cargo-binutils axconfig-gen cargo-axplat

# Set working directory
WORKDIR /workspace

CMD ["bash", "-l"]
