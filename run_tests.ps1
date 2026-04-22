<#
.SYNOPSIS
    豆花记账 - 测试运行脚本 (Windows PowerShell)
.DESCRIPTION
    一键运行 Swift (iOS) 和 Go (后端) 单元测试
.EXAMPLE
    .\run_tests.ps1              # 运行全部测试
    .\run_tests.ps1 go           # 仅 Go 测试
    .\run_tests.ps1 go cover     # Go 测试 + 覆盖率
    .\run_tests.ps1 go tests     # 仅 tests/ 目录
    .\run_tests.ps1 swift        # 仅 Swift 测试
#>

param(
    [ValidateSet("all", "swift", "go", "help")]
    [string]$Command = "all",

    [ValidateSet("all", "tests", "cover")]
    [string]$GoOption = "all"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ServerDir = Join-Path $ScriptDir "server"

$SwiftResult = 0
$GoResult = 0

function Write-Banner {
    Write-Host ""
    Write-Host "  🐶 豆花记账 — 测试运行器" -ForegroundColor Cyan
    Write-Host "  ========================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Info($msg) { Write-Host "[✓] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "[✗] $msg" -ForegroundColor Red }

function Test-SwiftTests {
    Write-Host ""
    Write-Host "━━━ Swift (iOS) 单元测试 ━━━" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Get-Command swift -ErrorAction SilentlyContinue)) {
        Write-Warn "Swift 未安装，跳过 iOS 测试"
        return
    }

    Push-Location $ScriptDir
    try {
        swift test
        if ($LASTEXITCODE -eq 0) {
            Write-Info "Swift 测试全部通过"
        } else {
            $script:SwiftResult = 1
            Write-Err "Swift 测试失败"
        }
    } catch {
        $script:SwiftResult = 1
        Write-Err "Swift 测试失败: $_"
    } finally {
        Pop-Location
    }
}

function Test-GoTests {
    param([string]$Option = "all")

    Write-Host ""
    Write-Host "━━━ Go (后端) 单元测试 ━━━" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        Write-Warn "Go 未安装，跳过后端测试"
        return
    }

    Push-Location $ServerDir
    try {
        switch ($Option) {
            "all" {
                Write-Host "运行所有 Go 测试..."
                go test ./... -v -count=1
                if ($LASTEXITCODE -eq 0) {
                    Write-Info "Go 测试全部通过"
                } else {
                    $script:GoResult = 1
                    Write-Err "Go 测试失败"
                }
            }
            "tests" {
                Write-Host "仅运行 tests/ 目录下的测试..."
                go test ./tests/... -v -count=1
                if ($LASTEXITCODE -eq 0) {
                    Write-Info "tests/ 测试全部通过"
                } else {
                    $script:GoResult = 1
                    Write-Err "tests/ 测试失败"
                }
            }
            "cover" {
                Write-Host "运行测试并生成覆盖率报告..."
                go test ./... -coverprofile=coverage.out -count=1
                if ($LASTEXITCODE -eq 0) {
                    go tool cover -func=coverage.out
                    go tool cover -html=coverage.out -o coverage.html
                    Write-Info "覆盖率报告已生成: server/coverage.html"
                } else {
                    $script:GoResult = 1
                    Write-Err "Go 测试失败"
                }
            }
        }
    } catch {
        $script:GoResult = 1
        Write-Err "Go 测试失败: $_"
    } finally {
        Pop-Location
    }
}

function Write-Summary {
    Write-Host ""
    Write-Host "━━━ 测试摘要 ━━━" -ForegroundColor Cyan
    Write-Host ""

    if ($SwiftResult -eq 0) {
        Write-Info "Swift (iOS):  通过 ✓"
    } else {
        Write-Err "Swift (iOS):  失败 ✗"
    }

    if ($GoResult -eq 0) {
        Write-Info "Go (后端):    通过 ✓"
    } else {
        Write-Err "Go (后端):    失败 ✗"
    }

    Write-Host ""

    if ($SwiftResult -ne 0 -or $GoResult -ne 0) {
        exit 1
    }
}

# ---- Main ----
Write-Banner

switch ($Command) {
    "swift" {
        Test-SwiftTests
    }
    "go" {
        Test-GoTests -Option $GoOption
    }
    "all" {
        Test-SwiftTests
        Test-GoTests -Option $GoOption
        Write-Summary
    }
    "help" {
        Write-Host "用法: .\run_tests.ps1 [命令] [选项]"
        Write-Host ""
        Write-Host "命令:"
        Write-Host "  all        运行所有测试 (默认)"
        Write-Host "  swift      仅运行 Swift (iOS) 测试"
        Write-Host "  go         仅运行 Go (后端) 测试"
        Write-Host ""
        Write-Host "Go 选项 (-GoOption):"
        Write-Host "  all        运行所有 Go 测试 (默认)"
        Write-Host "  tests      仅运行 tests/ 目录测试"
        Write-Host "  cover      运行并生成覆盖率报告"
        Write-Host ""
        Write-Host "示例:"
        Write-Host "  .\run_tests.ps1                  # 运行全部测试"
        Write-Host "  .\run_tests.ps1 go               # 仅 Go 测试"
        Write-Host "  .\run_tests.ps1 go -GoOption cover  # Go + 覆盖率"
        Write-Host "  .\run_tests.ps1 go -GoOption tests  # 仅 tests/"
        Write-Host "  .\run_tests.ps1 swift             # 仅 Swift 测试"
    }
}
