from prometheus_fastapi_instrumentator import Instrumentator, metrics

# Prometheus 指标配置
instrumentator = Instrumentator()

# 添加标准指标
instrumentator.add(
    metrics.request_size()
).add(
    metrics.response_size()
).add(
    metrics.latency()
).add(
    metrics.requests()
)
