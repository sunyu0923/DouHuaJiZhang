#!/bin/bash
# ============================================
# 豆花记账 - 测试运行脚本 (macOS / Linux)
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
    echo -e "${CYAN}  🐶 豆花记账 — 测试运行器${NC}"
    echo -e "${CYAN}  ========================${NC}"
    echo ""
}

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

SWIFT_RESULT=0
GO_RESULT=0

run_swift_tests() {
    echo ""
    echo -e "${CYAN}━━━ Swift (iOS) 单元测试 ━━━${NC}"
    echo ""

    if ! command -v swift &>/dev/null; then
        warn "Swift 未安装，跳过 iOS 测试"
        return
    fi

    cd "$SCRIPT_DIR"
    if swift test 2>&1; then
        info "Swift 测试全部通过"
    else
        SWIFT_RESULT=1
        error "Swift 测试失败"
    fi
}

run_go_tests() {
    echo ""
    echo -e "${CYAN}━━━ Go (后端) 单元测试 ━━━${NC}"
    echo ""

    if ! command -v go &>/dev/null; then
        warn "Go 未安装，跳过后端测试"
        return
    fi

    cd "$SERVER_DIR"

    case "${1:-all}" in
        all)
            echo "运行所有 Go 测试..."
            if go test ./... -v -count=1 2>&1; then
                info "Go 测试全部通过"
            else
                GO_RESULT=1
                error "Go 测试失败"
            fi
            ;;
        tests)
            echo "仅运行 tests/ 目录下的测试..."
            if go test ./tests/... -v -count=1 2>&1; then
                info "tests/ 测试全部通过"
            else
                GO_RESULT=1
                error "tests/ 测试失败"
            fi
            ;;
        cover)
            echo "运行测试并生成覆盖率报告..."
            if go test ./... -coverprofile=coverage.out -count=1 2>&1; then
                go tool cover -func=coverage.out
                go tool cover -html=coverage.out -o coverage.html
                info "覆盖率报告已生成: server/coverage.html"
            else
                GO_RESULT=1
                error "Go 测试失败"
            fi
            ;;
    esac
}

print_summary() {
    echo ""
    echo -e "${CYAN}━━━ 测试摘要 ━━━${NC}"
    echo ""

    if [ $SWIFT_RESULT -eq 0 ]; then
        info "Swift (iOS):  通过 ✓"
    else
        error "Swift (iOS):  失败 ✗"
    fi

    if [ $GO_RESULT -eq 0 ]; then
        info "Go (后端):    通过 ✓"
    else
        error "Go (后端):    失败 ✗"
    fi

    echo ""

    if [ $SWIFT_RESULT -ne 0 ] || [ $GO_RESULT -ne 0 ]; then
        exit 1
    fi
}

# ---- Main ----
banner

case "${1:-all}" in
    swift)
        run_swift_tests
        ;;
    go)
        run_go_tests "${2:-all}"
        ;;
    all)
        run_swift_tests
        run_go_tests "${2:-all}"
        print_summary
        ;;
    help|--help|-h)
        echo "用法: ./run_tests.sh [命令] [选项]"
        echo ""
        echo "命令:"
        echo "  all        运行所有测试 (默认)"
        echo "  swift      仅运行 Swift (iOS) 测试"
        echo "  go [选项]  仅运行 Go (后端) 测试"
        echo ""
        echo "Go 选项:"
        echo "  all        运行所有 Go 测试 (默认)"
        echo "  tests      仅运行 tests/ 目录测试"
        echo "  cover      运行并生成覆盖率报告"
        echo ""
        echo "示例:"
        echo "  ./run_tests.sh              # 运行全部测试"
        echo "  ./run_tests.sh go           # 仅 Go 测试"
        echo "  ./run_tests.sh go cover     # Go 测试 + 覆盖率"
        echo "  ./run_tests.sh go tests     # 仅 tests/ 目录"
        echo "  ./run_tests.sh swift        # 仅 Swift 测试"
        ;;
    *)
        echo "未知命令: $1"
        echo "使用 ./run_tests.sh help 查看帮助"
        exit 1
        ;;
esac
