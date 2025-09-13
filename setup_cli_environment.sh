#!/bin/bash
set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 輔助函數
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${CYAN}🔄 $1${NC}"
}

# 顯示橫幅
show_banner() {
    echo -e "${CYAN}"
    echo "=================================================================="
    echo "🚀 RT-Thread MicroPython CLI 自動安裝工具"
    echo "=================================================================="
    echo "此工具將自動安裝並配置 MicroPython CLI 開發環境"
    echo "包括："
    echo "  • Python 依賴套件安裝"
    echo "  • CLI 工具建構"
    echo "  • 環境驗證"
    echo "  • 串口權限設定（Linux）"
    echo "=================================================================="
    echo -e "${NC}"
}

# 檢測作業系統
detect_os() {
    log_step "檢測作業系統..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        log_info "檢測到 Linux 系統"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        log_info "檢測到 macOS 系統"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS_TYPE="windows"
        log_info "檢測到 Windows 系統（通過 MSYS/Cygwin）"
    else
        OS_TYPE="unknown"
        log_warning "未知的作業系統類型: $OSTYPE"
    fi
}

# 檢測 Python
detect_python() {
    log_step "檢測 Python 環境..."
    
    PYTHON_CMD=""
    
    # 按優先順序嘗試不同的 Python 命令
    for cmd in python3 python python3.11 python3.10 python3.9 python3.8 python3.7; do
        if command -v $cmd &> /dev/null; then
            # 檢查版本
            VERSION=$($cmd -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "0.0")
            MAJOR=$(echo $VERSION | cut -d. -f1)
            MINOR=$(echo $VERSION | cut -d. -f2)
            
            if [[ $MAJOR -eq 3 ]] && [[ $MINOR -ge 6 ]]; then
                PYTHON_CMD=$cmd
                PYTHON_VERSION=$VERSION
                log_success "找到合適的 Python: $cmd (版本 $VERSION)"
                break
            else
                log_warning "$cmd 版本過舊 ($VERSION)，需要 Python 3.6+"
            fi
        fi
    done
    
    if [[ -z "$PYTHON_CMD" ]]; then
        log_error "未找到合適的 Python 版本 (需要 3.6+)"
        echo "請先安裝 Python 3.6 或更高版本："
        case $OS_TYPE in
            "linux")
                echo "  Ubuntu/Debian: sudo apt update && sudo apt install python3 python3-pip"
                echo "  CentOS/RHEL: sudo yum install python3 python3-pip"
                echo "  Arch: sudo pacman -S python python-pip"
                ;;
            "macos")
                echo "  使用 Homebrew: brew install python"
                echo "  或從 https://www.python.org/downloads/ 下載"
                ;;
            "windows")
                echo "  從 https://www.python.org/downloads/ 下載安裝"
                ;;
        esac
        exit 1
    fi
}

# 檢查 pip
check_pip() {
    log_step "檢查 pip..."
    
    if ! $PYTHON_CMD -m pip --version &> /dev/null; then
        log_warning "pip 不可用，嘗試安裝..."
        
        # 嘗試安裝 pip
        if ! $PYTHON_CMD -m ensurepip --upgrade &> /dev/null; then
            log_error "無法安裝 pip，請手動安裝"
            exit 1
        fi
    fi
    
    log_success "pip 可用"
    
    # 升級 pip
    log_info "升級 pip 到最新版本..."
    $PYTHON_CMD -m pip install --upgrade pip --quiet
}

# 安裝 Python 依賴
install_dependencies() {
    log_step "安裝 Python 依賴套件..."
    
    local packages=("click" "pyserial" "python-dotenv" "pyinstaller")
    
    for package in "${packages[@]}"; do
        log_info "安裝 $package..."
        if $PYTHON_CMD -m pip install "$package" --quiet; then
            log_success "$package 安裝成功"
        else
            log_error "$package 安裝失敗"
            exit 1
        fi
    done
}

# 驗證依賴
verify_dependencies() {
    log_step "驗證依賴套件..."
    
    local packages=("click" "serial" "dotenv" "PyInstaller")
    local failed=false
    
    for package in "${packages[@]}"; do
        local import_name="$package"
        if [[ "$package" == "python-dotenv" ]]; then
            import_name="dotenv"
        elif [[ "$package" == "pyserial" ]]; then
            import_name="serial"
        fi
        
        if $PYTHON_CMD -c "import $import_name" 2>/dev/null; then
            log_success "$package 驗證通過"
        else
            log_error "$package 驗證失敗"
            failed=true
        fi
    done
    
    if [[ "$failed" == "true" ]]; then
        log_error "部分依賴驗證失敗"
        exit 1
    fi
}

# 測試 CLI 基本功能
test_cli_python() {
    log_step "測試 CLI Python 版本..."
    
    if [[ ! -f "cli.py" ]]; then
        log_error "找不到 cli.py 檔案"
        exit 1
    fi
    
    if $PYTHON_CMD cli.py --help > /dev/null 2>&1; then
        log_success "CLI Python 版本功能正常"
    else
        log_error "CLI Python 版本測試失敗"
        exit 1
    fi
}

# 建構 CLI 導向腳本
build_cli_script() {
    log_step "建構 CLI 導向腳本..."
    
    if [[ -f "build_cli.sh" ]]; then
        chmod +x build_cli.sh
        if ./build_cli.sh; then
            log_success "CLI 導向腳本建構成功"
            return 0
        else
            log_warning "CLI 導向腳本建構失敗，將使用 Python 版本"
            return 1
        fi
    else
        log_warning "找不到 build_cli.sh，跳過導向腳本建構"
        return 1
    fi
}

# 設定串口權限（Linux）
setup_serial_permissions() {
    if [[ "$OS_TYPE" == "linux" ]]; then
        log_step "設定 Linux 串口權限..."
        
        # 檢查 dialout 群組是否存在
        if getent group dialout >/dev/null 2>&1; then
            # 檢查當前使用者是否在 dialout 群組中
            if groups "$USER" | grep -q "\bdialout\b"; then
                log_success "使用者已在 dialout 群組中"
            else
                log_warning "使用者不在 dialout 群組中"
                echo "為了獲得串口存取權限，建議執行以下命令："
                echo "  sudo usermod -aG dialout $USER"
                echo "執行後需要重新登入才會生效"
                echo
                read -p "是否現在執行此命令？(y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    if sudo usermod -aG dialout "$USER"; then
                        log_success "已將使用者加入 dialout 群組"
                        log_warning "請重新登入以使權限生效"
                    else
                        log_error "加入 dialout 群組失敗"
                    fi
                fi
            fi
        else
            log_warning "系統中沒有 dialout 群組"
        fi
    fi
}

# 執行環境驗證
run_environment_check() {
    log_step "執行完整環境驗證..."
    
    if [[ -f "check_environment.py" ]]; then
        if $PYTHON_CMD check_environment.py; then
            log_success "環境驗證通過"
        else
            log_warning "環境驗證發現問題，但安裝可能仍然成功"
        fi
    else
        log_warning "找不到環境檢查腳本，跳過詳細驗證"
    fi
}

# 測試串口掃描
test_port_scan() {
    log_step "測試串口掃描功能..."
    
    log_info "使用 Python 版本測試..."
    if $PYTHON_CMD cli.py -p query portscan 2>/dev/null; then
        log_success "串口掃描測試通過"
    else
        log_warning "串口掃描測試失敗（可能是沒有連接設備）"
    fi
    
    # 如果有導向腳本，也測試一下
    if [[ -f "../ampy/cli" ]]; then
        log_info "使用導向腳本測試..."
        if ../ampy/cli -p query portscan 2>/dev/null; then
            log_success "導向腳本串口掃描測試通過"
        else
            log_warning "導向腳本串口掃描測試失敗"
        fi
    fi
}

# 顯示使用說明
show_usage_guide() {
    echo
    echo -e "${CYAN}=================================================================="
    echo "🎉 安裝完成！使用指南："
    echo "=================================================================="
    echo -e "${NC}"
    
    echo "1. 基本命令格式："
    echo "   $PYTHON_CMD cli.py [選項] 命令"
    echo
    
    echo "2. 常用命令："
    echo "   掃描串口:     $PYTHON_CMD cli.py -p query portscan"
    echo "   進入 REPL:    $PYTHON_CMD cli.py -p [串口] repl"
    echo "   列出檔案:     $PYTHON_CMD cli.py -p [串口] ls"
    echo "   上傳檔案:     $PYTHON_CMD cli.py -p [串口] put [本地檔案] [遠端檔案]"
    echo "   下載檔案:     $PYTHON_CMD cli.py -p [串口] get [遠端檔案] [本地檔案]"
    echo "   執行檔案:     $PYTHON_CMD cli.py -p [串口] run [檔案]"
    echo "   同步資料夾:   $PYTHON_CMD cli.py -p [串口] sync -l [本地路徑] -i [快取檔案]"
    echo
    
    if [[ -f "../ampy/cli" ]]; then
        echo "3. 導向腳本（智能 Python 選擇）："
        echo "   將上述命令中的 '$PYTHON_CMD cli.py' 替換為 '../ampy/cli'"
        echo
    fi
    
    echo "4. 取得詳細說明："
    echo "   $PYTHON_CMD cli.py --help"
    echo
    
    if [[ "$OS_TYPE" == "linux" ]] && ! groups "$USER" | grep -q "\bdialout\b"; then
        echo -e "${YELLOW}⚠️  注意事項："
        echo "   在 Linux 系統上，如果遇到串口權限問題，請執行："
        echo "   sudo usermod -aG dialout $USER"
        echo "   然後重新登入"
        echo -e "${NC}"
    fi
    
    echo "5. 範例："
    echo "   # 掃描可用串口"
    echo "   $PYTHON_CMD cli.py -p query portscan"
    echo
    echo "   # 連接到 /dev/ttyUSB0 並進入 REPL"
    echo "   $PYTHON_CMD cli.py -p /dev/ttyUSB0 repl"
    echo
    echo "   # 上傳 main.py 到設備"
    echo "   $PYTHON_CMD cli.py -p /dev/ttyUSB0 put main.py main.py"
    echo
    
    echo -e "${CYAN}=================================================================="
    echo -e "${NC}"
}

# 主要安裝流程
main() {
    show_banner
    
    # 確保在正確的目錄
    cd "$(dirname "$0")"
    
    # 檢查是否在 micropython-tools 目錄
    if [[ ! -f "cli.py" ]] || [[ ! -d "ampy" ]]; then
        log_error "請在 micropython-tools 目錄中執行此腳本"
        exit 1
    fi
    
    # 執行安裝步驟
    detect_os
    detect_python
    check_pip
    install_dependencies
    verify_dependencies
    test_cli_python
    
    # 嘗試建構導向腳本（可選）
    build_cli_script || true
    
    # Linux 特定設置
    setup_serial_permissions
    
    # 執行環境驗證
    run_environment_check
    
    # 測試功能
    test_port_scan
    
    # 顯示使用指南
    show_usage_guide
    
    log_success "🎉 RT-Thread MicroPython CLI 安裝完成！"
}

# 錯誤處理
trap 'log_error "安裝過程中發生錯誤，正在退出..."; exit 1' ERR

# 檢查是否為 root 使用者（不建議）
if [[ $EUID -eq 0 ]]; then
    log_warning "不建議以 root 使用者執行此腳本"
    read -p "是否確定要繼續？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 執行主要流程
main "$@"