# ============================================================
#  SnapShop Windows 本地一键部署脚本
#
#  用法:
#    方式1 (本地已有项目):
#      cd "f:\AI Shopping" ; .\bootstrap.ps1
#
#    方式2 (远程一键):
#      git clone https://github.com/For2006/SnapShop.git "f:\AI Shopping"
#      cd "f:\AI Shopping" ; .\bootstrap.ps1
#
#  选项:
#    -ProjectDir PATH      项目目录 (默认: f:\AI Shopping)
#    -SkipClone            跳过克隆，使用已有项目
#    -BuildOnly            仅构建，不启动
# ============================================================

param(
    [string]$ProjectDir = "f:\AI Shopping",
    [switch]$SkipClone = $false,
    [switch]$BuildOnly = $false
)

$ErrorActionPreference = "Stop"
$BackendDir = Join-Path $ProjectDir "backend"
$EnvFile = Join-Path $BackendDir ".env"
$EnvTemplate = Join-Path $BackendDir ".env.example"

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  SnapShop - Windows 本地一键部署" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 0. 检查前提条件
# ============================================================
Write-Host "[0/7] 检查前提条件..." -ForegroundColor Green

$AllOk = $true

if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Host "  [x] Git 未安装, 请从 https://git-scm.com/download/win 下载安装" -ForegroundColor Red
    $AllOk = $false
} else {
    Write-Host "  [+] Git $(git --version)" -ForegroundColor Green
}

if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "  [x] Docker 未安装, 请从 https://www.docker.com/products/docker-desktop/ 下载安装" -ForegroundColor Red
    $AllOk = $false
} else {
    try {
        docker ps | Out-Null
        Write-Host "  [+] Docker $(docker --version)" -ForegroundColor Green
    } catch {
        Write-Host "  [x] Docker Desktop 未运行, 请启动后重试" -ForegroundColor Red
        $AllOk = $false
    }
}

if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
    Write-Host "  [!] Python 未安装 (仅影响 JWT 密钥生成, 不影响部署)" -ForegroundColor Yellow
    Write-Host "      可从 https://www.python.org/downloads/ 下载安装" -ForegroundColor Yellow
}

if (-not $AllOk) {
    Write-Host "`n请先解决以上问题后重试" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================================
# 1. 克隆/定位项目
# ============================================================
Write-Host "[1/7] 准备项目代码..." -ForegroundColor Green

if (-not $SkipClone) {
    if (-not (Test-Path $ProjectDir)) {
        Write-Host "  克隆项目: https://github.com/For2006/SnapShop.git" -ForegroundColor Gray
        git clone https://github.com/For2006/SnapShop.git $ProjectDir
    } elseif (Test-Path (Join-Path $ProjectDir ".git")) {
        Write-Host "  项目已存在于 $ProjectDir" -ForegroundColor Gray
        Push-Location $ProjectDir
        try {
            git pull origin main 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  [!] git pull 失败, 使用现有代码继续" -ForegroundColor Yellow
            }
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "  目录已存在但不是 git 仓库, 使用现有代码继续" -ForegroundColor Yellow
    }
}

if (-not (Test-Path $BackendDir)) {
    Write-Host "  [x] 项目目录 $BackendDir 不存在" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================================
# 2. 配置 .env
# ============================================================
Write-Host "[2/7] 配置环境变量..." -ForegroundColor Green

if (Test-Path $EnvFile) {
    Write-Host "  $EnvFile 已存在, 保留现有配置" -ForegroundColor Gray
} else {
    if (-not (Test-Path $EnvTemplate)) {
        Write-Host "  [x] 模板文件 $EnvTemplate 不存在" -ForegroundColor Red
        exit 1
    }

    Copy-Item $EnvTemplate $EnvFile

    $PgPass = -join ((48..57) + (97..122)) * 2 | Get-Random -Count 16 | ForEach-Object { [char]$_ }
    $MinioPass = -join ((48..57) + (97..122)) * 2 | Get-Random -Count 16 | ForEach-Object { [char]$_ }

    try {
        $JwtSecret = python -c "import secrets; print(secrets.token_urlsafe(32))" 2>$null
    } catch {
        $JwtSecret = -join ((48..57) + (65..90) + (97..122)) * 3 | Get-Random -Count 43 | ForEach-Object { [char]$_ }
        Write-Host "  [!] Python 不可用, 使用 PowerShell 生成随机密钥" -ForegroundColor Yellow
    }
    $JwtSecret = $JwtSecret.Trim()

    $Content = Get-Content $EnvFile -Raw -Encoding UTF8

    $Content = $Content -replace 'DATABASE_URL=sqlite\+aiosqlite:///\./snapshop\.db', "DATABASE_URL=postgresql+asyncpg://snapshop:${PgPass}@localhost:5432/snapshop"
    $Content = $Content -replace 'POSTGRES_PASSWORD=.*', "POSTGRES_PASSWORD=${PgPass}"
    $Content = $Content -replace '# MINIO_ENDPOINT=localhost:9000', "MINIO_ENDPOINT=localhost:9000"
    $Content = $Content -replace '^MINIO_ENDPOINT=.*', "MINIO_ENDPOINT=localhost:9000"
    $Content = $Content -replace '# MINIO_ACCESS_KEY=你的MinIO用户名', "MINIO_ACCESS_KEY=snapshop_admin"
    $Content = $Content -replace '^MINIO_ACCESS_KEY=.*', "MINIO_ACCESS_KEY=snapshop_admin"
    $Content = $Content -replace '# MINIO_SECRET_KEY=你的MinIO密码', "MINIO_SECRET_KEY=${MinioPass}"
    $Content = $Content -replace '^MINIO_SECRET_KEY=.*', "MINIO_SECRET_KEY=${MinioPass}"
    $Content = $Content -replace 'MINIO_ROOT_USER=.*', "MINIO_ROOT_USER=snapshop_admin"
    $Content = $Content -replace 'MINIO_ROOT_PASSWORD=.*', "MINIO_ROOT_PASSWORD=${MinioPass}"
    $Content = $Content -replace 'JWT_SECRET=.*', "JWT_SECRET=${JwtSecret}"
    $Content = $Content -replace 'REDIS_URL=.*', "REDIS_URL=redis://localhost:6379/0"

    if ($Content -notmatch "ARK_API_KEY=你的" -and $Content -match "ARK_API_KEY=$") {
        Write-Host "  未检测到 AI 密钥, 自动开启 Mock 模式" -ForegroundColor Gray
        $Content = $Content -replace 'AI_MOCK_MODE=.*', "AI_MOCK_MODE=true"
    }

    [System.IO.File]::WriteAllText($EnvFile, $Content, [System.Text.UTF8Encoding]::new($false))

    Write-Host ""
    Write-Host "  [+] 已自动生成配置并写入 $EnvFile" -ForegroundColor Green
    Write-Host ""
    Write-Host "  ========== 配置信息 (请妥善保存) ==========" -ForegroundColor Yellow
    Write-Host "  POSTGRES_PASSWORD:    $PgPass" -ForegroundColor White
    Write-Host "  MINIO_ROOT_PASSWORD:  $MinioPass" -ForegroundColor White
    Write-Host "  JWT_SECRET:           $JwtSecret" -ForegroundColor White
    Write-Host "  AI_MOCK_MODE:         true (无 AI 密钥时使用 Mock 模式)" -ForegroundColor Gray
    Write-Host "  ===========================================" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================
# 3. 配置 Docker 镜像加速
# ============================================================
Write-Host "[3/7] 检查 Docker 镜像加速..." -ForegroundColor Green

$DockerConfigPath = "$env:USERPROFILE\.docker\daemon.json"

if (Test-Path $DockerConfigPath) {
    $DockerConfig = Get-Content $DockerConfigPath -Raw | ConvertFrom-Json
    if (-not $DockerConfig.'registry-mirrors' -or $DockerConfig.'registry-mirrors'.Count -eq 0) {
        Write-Host "  [!] 未配置镜像加速, 拉取镜像可能很慢" -ForegroundColor Yellow
        Write-Host "      建议在 Docker Desktop → Settings → Docker Engine 中添加镜像源" -ForegroundColor Yellow
    } else {
        Write-Host "  [+] 已配置 Docker 镜像加速" -ForegroundColor Green
    }
} else {
    Write-Host "  [!] 未配置镜像加速, 拉取镜像可能很慢" -ForegroundColor Yellow
    Write-Host "      建议在 Docker Desktop → Settings → Docker Engine 中添加:" -ForegroundColor Yellow
    Write-Host '      "registry-mirrors": ["https://docker.m.daocloud.io"]' -ForegroundColor Gray
}

Write-Host ""

# ============================================================
# 4. 启动 Docker 服务
# ============================================================
Write-Host "[4/7] 启动 Docker 服务..." -ForegroundColor Green

Push-Location $BackendDir
try {
    docker compose down --remove-orphans 2>$null | Out-Null

    Write-Host "  构建并启动容器 (首次约需 3-10 分钟)..." -ForegroundColor Gray
    docker compose build --no-cache backend 2>&1 | ForEach-Object {
        if ($_ -match "Step|Successfully|ERROR") { Write-Host "  $_" -ForegroundColor Gray }
    }

    docker compose up -d

    Write-Host "  [+] 容器已启动, 等待服务就绪..." -ForegroundColor Green
    $MaxWait = 120
    $Elapsed = 0
    do {
        Start-Sleep -Seconds 5
        $Elapsed += 5
        $Status = docker compose ps --format json 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue

        $AllHealthy = $true
        $TotalServices = 0
        $HealthyServices = 0
        foreach ($Svc in $Status) {
            $TotalServices++
            if ($Svc.State -eq "running" -or $Svc.Health -eq "healthy") {
                $HealthyServices++
            } else {
                $AllHealthy = $false
            }
        }
        Write-Host "  等待中... ($Elapsed`s / $MaxWait`s) $HealthyServices / $TotalServices 就绪" -ForegroundColor Gray
    } while (-not $AllHealthy -and $Elapsed -lt $MaxWait)

    Write-Host ""
    Write-Host "  容器状态:" -ForegroundColor Green
    docker compose ps
    Write-Host ""
} finally {
    Pop-Location
}

# ============================================================
# 5. MinIO 存储桶
# ============================================================
Write-Host "[5/7] 检查 MinIO 存储桶..." -ForegroundColor Green

Push-Location $BackendDir
try {
    $BucketCreated = $false
    for ($i = 0; $i -lt 15; $i++) {
        $Logs = docker compose logs minio-init 2>$null
        if ($Logs -match "snapshop-images ready") {
            Write-Host "  [+] MinIO 存储桶 snapshop-images 已就绪 (minio-init 自动创建)" -ForegroundColor Green
            $BucketCreated = $true
            break
        }
        Start-Sleep -Seconds 2
    }

    if (-not $BucketCreated) {
        Write-Host "  [!] minio-init 可能尚未完成, 尝试手动创建..." -ForegroundColor Yellow
        $MinioPass = Select-String -Path $EnvFile -Pattern 'MINIO_ROOT_PASSWORD=(.*)' | ForEach-Object { $_.Matches.Groups[1].Value }
        docker run --rm --network backend_default `
            --env MINIO_ROOT_USER=snapshop_admin `
            --env "MINIO_ROOT_PASSWORD=$MinioPass" `
            minio/mc `
            sh -c "mc config host add snapshop http://minio:9000 snapshop_admin '$MinioPass' && mc mb --ignore-existing snapshop/snapshop-images" 2>$null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [+] MinIO 存储桶 snapshop-images 已就绪" -ForegroundColor Green
        } else {
            Write-Host "  [!] 自动创建存储桶失败, 请稍后手动创建:" -ForegroundColor Yellow
            Write-Host "      访问 http://localhost:9001 → 登录 → Buckets → Create Bucket" -ForegroundColor Yellow
            Write-Host "      Bucket Name: snapshop-images" -ForegroundColor Yellow
        }
    }
} finally {
    Pop-Location
}

Write-Host ""

# ============================================================
# 6. 数据库迁移
# ============================================================
Write-Host "[6/7] 运行数据库迁移..." -ForegroundColor Green

Push-Location $BackendDir
try {
    docker compose exec -T backend alembic upgrade head 2>&1 | ForEach-Object {
        if ($_ -match "ERROR") {
            Write-Host "  $_" -ForegroundColor Red
        } else {
            Write-Host "  $_" -ForegroundColor Gray
        }
    }
    Write-Host "  [+] 数据库迁移完成" -ForegroundColor Green
} finally {
    Pop-Location
}

Write-Host ""

# ============================================================
# 7. 验证
# ============================================================
Write-Host "[7/7] 验证部署..." -ForegroundColor Green

Start-Sleep -Seconds 3

try {
    $Response = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method Get -TimeoutSec 10
    if ($Response.status -eq "healthy") {
        Write-Host "  [+] 后端健康检查通过: $($Response | ConvertTo-Json -Compress)" -ForegroundColor Green
    }
} catch {
    Write-Host "  [!] 健康检查失败, 后端可能尚未完全就绪, 请稍后重试:" -ForegroundColor Yellow
    Write-Host "      curl http://localhost:8000/health" -ForegroundColor Gray
}

Write-Host ""

# ============================================================
# 完成
# ============================================================
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  部署完成!" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  后端健康检查: curl http://localhost:8000/health" -ForegroundColor White
Write-Host "  Swagger 文档: http://localhost:8000/docs" -ForegroundColor White
Write-Host "  MinIO 控制台: http://localhost:9001" -ForegroundColor White
Write-Host ""
Write-Host "  启动前端:" -ForegroundColor White
Write-Host "    cd $(Join-Path $ProjectDir 'snapshop')" -ForegroundColor Gray
Write-Host "    flutter pub get" -ForegroundColor Gray
Write-Host "    flutter run" -ForegroundColor Gray
Write-Host ""
Write-Host "  常用命令:" -ForegroundColor White
Write-Host "    docker compose ps                         查看容器状态" -ForegroundColor Gray
Write-Host "    docker compose logs -f backend            查看后端日志" -ForegroundColor Gray
Write-Host "    docker compose down                       停止所有服务" -ForegroundColor Gray
Write-Host "    docker compose up -d                      重新启动服务" -ForegroundColor Gray
Write-Host ""

if ($BuildOnly) {
    Write-Host "  [BuildOnly 模式] 服务未启动, 手动执行:" -ForegroundColor Yellow
    Write-Host "    cd $BackendDir" -ForegroundColor Gray
    Write-Host "    docker compose up -d" -ForegroundColor Gray
}
