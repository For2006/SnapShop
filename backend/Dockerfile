FROM python:3.12-slim AS builder

WORKDIR /build

# 设置环境变量
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com

# 最终镜像
FROM python:3.12-slim

WORKDIR /app

# 从 builder 复制安装的包
COPY --from=builder /install /usr/local
COPY app/ ./app/

# 设置用户
RUN useradd -m -u 1000 snapshop
USER snapshop

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
