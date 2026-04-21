#!/bin/bash
# ============================================
# 豆花记账 - 快速启动脚本 (macOS / Linux)
# ============================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$SCRIPT_DIR/server"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

banner() {
    echo ""
    echo -e "${CYAN}  🐶 豆花记账 DouHuaJiZhang${NC}"
    echo -e "${CYAN}  =========================${NC}"
    echo ""
}

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

check_deps() {
    echo "检查依赖..."
    command -v docker >/dev/null 2>&1 || error "未安装 Docker，请先安装: https://docs.docker.com/get-docker/"
    command -v docker compose >/dev/null 2>&1 || command -v docker-compose >/dev/null 2>&1 || error "未安装 Docker Compose"
    info "Docker 已就绪"
}

setup_env() {
    if [ ! -f "$SERVER_DIR/.env" ]; then
        cp "$SERVER_DIR/.env.example" "$SERVER_DIR/.env"
        warn "已从 .env.example 创建 .env，生产环境请修改 JWT_SECRET 和数据库密码！"
    else
        info ".env 文件已存在"
    fi
}

start_services() {
    echo ""
    echo "启动服务..."
    cd "$SERVER_DIR"

    if command -v docker compose >/dev/null 2>&1; then
        COMPOSE="docker compose"
    else
        COMPOSE="docker-compose"
    fi

    case "${1:-full}" in
        db)
            info "仅启动数据库 (PostgreSQL + Redis)..."
            $COMPOSE up -d postgres redis
            ;;
        full)
            info "启动全部服务 (PostgreSQL + Redis + API)..."
            $COMPOSE up -d --build
            ;;
        down)
            warn "停止所有服务..."
            $COMPOSE down
            info "服务已停止"
            exit 0
            ;;
        clean)
            warn "停止并清除所有数据..."
            $COMPOSE down -v
            info "服务已停止，数据已清除"
            exit 0
            ;;
        logs)
            $COMPOSE logs -f
            exit 0
            ;;
        *)
            echo "用法: $0 [full|db|down|clean|logs]"
            echo "  full   - 启动全部服务 (默认)"
            echo "  db     - 仅启动 PostgreSQL + Redis"
            echo "  down   - 停止服务"
            echo "  clean  - 停止并删除数据"
            echo "  logs   - 查看日志"
            exit 0
            ;;
    esac

    echo ""
    info "等待服务就绪..."
    sleep 3

    # Health check
    if curl -s http://localhost:8080/health >/dev/null 2>&1; then
        info "API 服务已就绪 ✓"
    elif [ "${1:-full}" = "db" ]; then
        info "数据库服务已就绪 ✓"
    else
        warn "API 尚在启动中，请稍候查看: docker compose logs api"
    fi
}

print_info() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  🌐 API 地址:     ${GREEN}http://localhost:8080${NC}"
    echo -e "  📡 健康检查:     ${GREEN}http://localhost:8080/health${NC}"
    echo -e "  🐘 PostgreSQL:   ${GREEN}localhost:5432${NC}"
    echo -e "  🔴 Redis:        ${GREEN}localhost:6379${NC}"
    echo -e "  🔌 WebSocket:    ${GREEN}ws://localhost:8080/ws${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  查看日志: ${YELLOW}cd server && docker compose logs -f${NC}"
    echo -e "  停止服务: ${YELLOW}./start.sh down${NC}"
    echo ""
}

# Main
banner
check_deps
setup_env
start_services "$1"
print_info
