# 多阶段构建 - 构建阶段
FROM rust:1.88-slim AS builder

# 安装构建依赖，包含完整的 OpenSSL 开发库
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libssl3 \
    openssl \
    ca-certificates \
    musl-tools \
    musl-dev \
    && rm -rf /var/lib/apt/lists/*

# 添加 musl 目标
RUN rustup target add x86_64-unknown-linux-musl

# 设置工作目录
WORKDIR /app

# 复制源代码
COPY Cargo.toml Cargo.lock ./
COPY src ./src

# 设置 OpenSSL 环境变量和编译选项
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV OPENSSL_STATIC=1
ENV OPENSSL_DIR=/usr
ENV RUSTFLAGS="-C link-arg=-s -C opt-level=z -C target-feature=+crt-static"

# 静态链接编译 - 使用 musl 目标
RUN touch src/main.rs && \
    cargo build --release --target x86_64-unknown-linux-musl

# 运行阶段 - 使用scratch
FROM scratch

LABEL maintainer="AptS:1547 <apts-1547@esaps.net>"
LABEL description="A next-generation hardware system for Rust"
LABEL version="0.0.1"
LABEL homepage="https://github.com/The-ESAP-Project/rust-hwsystem-next"
LABEL license="MIT"

# 从构建阶段复制二进制文件 (使用 musl 目标路径)
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/rust-hwsystem-next /rust-hwsystem-next

VOLUME ["/data", "/socket"]

# 暴露端口
EXPOSE 8080

# 设置环境变量
ENV DOCKER_ENV=1
ENV SERVER_HOST=0.0.0.0
ENV SERVER_PORT=8080
ENV DATABASE_URL=/data/hwsystem.db
ENV RUST_LOG=info

# 启动命令
ENTRYPOINT ["/rust-hwsystem-next"]
