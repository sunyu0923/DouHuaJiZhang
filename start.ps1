<# 
.SYNOPSIS
    豆花记账 - Windows 快速启动脚本
.DESCRIPTION
    一键部署后端服务 (PostgreSQL + Redis + Go API)
.EXAMPLE
    .\start.ps1            # 启动全部服务
    .\start.ps1 db         # 仅启动数据库
    .\start.ps1 down       # 停止服务
    .\start.ps1 clean      # 停止并清除数据
    .\start.ps1 logs       # 查看日志
    .\start.ps1 dev        # 本地开发模式 (仅DB + 本地Go)
#>

param(
    [ValidateSet("full", "db", "down", "clean", "logs", "dev")]
    [string]$Action = "full"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ServerDir = Join-Path $ScriptDir "server"

function Write-Banner {
    Write-Host ""
    Write-Host "  🐶 豆花记账 DouHuaJiZhang" -ForegroundColor Cyan
    Write-Host "  =========================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Info($msg) { Write-Host "[✓] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "[✗] $msg" -ForegroundColor Red; exit 1 }

function Test-Docker {
    Write-Host "检查依赖..."
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Err "未安装 Docker Desktop，请先安装: https://docs.docker.com/desktop/install/windows-install/"
    }
    # Test docker daemon
    try { docker info 2>&1 | Out-Null } catch { Write-Err "Docker 未运行，请启动 Docker Desktop" }
    Write-Info "Docker 已就绪"
}

function Initialize-Env {
    $envFile = Join-Path $ServerDir ".env"
    $envExample = Join-Path $ServerDir ".env.example"
    if (-not (Test-Path $envFile)) {
        Copy-Item $envExample $envFile
        Write-Warn "已从 .env.example 创建 .env，生产环境请修改 JWT_SECRET 和数据库密码!"
    } else {
        Write-Info ".env 文件已存在"
    }
}

function Get-ComposeCmd {
    # docker compose (V2) vs docker-compose (V1)
    try { docker compose version 2>&1 | Out-Null; return "docker compose" } catch {}
    try { docker-compose version 2>&1 | Out-Null; return "docker-compose" } catch {}
    Write-Err "未安装 Docker Compose"
}

function Start-Services {
    Push-Location $ServerDir
    $compose = Get-ComposeCmd

    switch ($Action) {
        "db" {
            Write-Info "仅启动数据库 (PostgreSQL + Redis)..."
            Invoke-Expression "$compose up -d postgres redis"
        }
        "full" {
            Write-Info "启动全部服务 (PostgreSQL + Redis + API)..."
            Invoke-Expression "$compose up -d --build"
        }
        "down" {
            Write-Warn "停止所有服务..."
            Invoke-Expression "$compose down"
            Write-Info "服务已停止"
            Pop-Location; return
        }
        "clean" {
            Write-Warn "停止并清除所有数据..."
            Invoke-Expression "$compose down -v"
            Write-Info "服务已停止，数据已清除"
            Pop-Location; return
        }
        "logs" {
            Invoke-Expression "$compose logs -f"
            Pop-Location; return
        }
        "dev" {
            Write-Info "开发模式: 启动数据库 + 本地运行 Go..."
            Invoke-Expression "$compose up -d postgres redis"
            Write-Host ""
            Write-Info "数据库已启动，请在 server/ 目录运行:"
            Write-Host '  $env:DATABASE_URL="postgres://douhua:douhua_secret_2026@localhost:5432/douhuajizhang?sslmode=disable"' -ForegroundColor Yellow
            Write-Host '  go run ./cmd/api' -ForegroundColor Yellow
            Pop-Location; return
        }
    }

    Write-Host ""
    Write-Info "等待服务就绪..."
    Start-Sleep -Seconds 5

    # Health check
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200) { Write-Info "API 服务已就绪 ✓" }
    } catch {
        if ($Action -eq "db") {
            Write-Info "数据库服务已就绪 ✓"
        } else {
            Write-Warn "API 尚在启动中，请稍候查看: docker compose logs api"
        }
    }

    Pop-Location
}

function Show-Info {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  🌐 API 地址:     " -NoNewline; Write-Host "http://localhost:8080" -ForegroundColor Green
    Write-Host "  📡 健康检查:     " -NoNewline; Write-Host "http://localhost:8080/health" -ForegroundColor Green
    Write-Host "  🐘 PostgreSQL:   " -NoNewline; Write-Host "localhost:5432" -ForegroundColor Green
    Write-Host "  🔴 Redis:        " -NoNewline; Write-Host "localhost:6379" -ForegroundColor Green
    Write-Host "  🔌 WebSocket:    " -NoNewline; Write-Host "ws://localhost:8080/ws" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  查看日志: " -NoNewline; Write-Host ".\start.ps1 logs" -ForegroundColor Yellow
    Write-Host "  停止服务: " -NoNewline; Write-Host ".\start.ps1 down" -ForegroundColor Yellow
    Write-Host ""
}

# Main
Write-Banner
Test-Docker
Initialize-Env
Start-Services
if ($Action -eq "full" -or $Action -eq "db") { Show-Info }
