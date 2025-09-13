#!/bin/bash
set -e  # 遇到錯誤時立即退出

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 檢測 Python 命令
detect_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        log_error "未找到 Python 命令"
        exit 1
    fi
    
    # 檢查 Python 版本
    PYTHON_VERSION=$(${PYTHON_CMD} -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    log_info "使用 Python 版本: ${PYTHON_VERSION}"
    
    # 檢查是否為 Python 3.6+
    if [[ $(echo "${PYTHON_VERSION} >= 3.6" | bc 2>/dev/null || echo "0") -eq 1 ]]; then
        log_success "Python 版本符合要求"
    else
        log_warning "Python 版本可能過舊，建議使用 3.6 或更高版本"
    fi
}

# 檢查並安裝依賴
check_and_install_dependencies() {
    log_info "檢查並安裝必要依賴..."
    
    # 升級 pip
    ${PYTHON_CMD} -m pip install --upgrade pip
    
    # 安裝必要套件
    local packages=("click" "pyserial" "python-dotenv" "pyinstaller")
    
    for package in "${packages[@]}"; do
        if ${PYTHON_CMD} -c "import ${package/python-/}" &> /dev/null; then
            log_success "套件 ${package} 已安裝"
        else
            log_info "正在安裝 ${package}..."
            ${PYTHON_CMD} -m pip install "${package}"
        fi
    done
}

# 建立 CLI 導向腳本
build_cli_script() {
    log_info "建立 CLI 導向腳本..."
    
    # 確保在正確的目錄
    cd "$(dirname "$0")"
    
    # 檢查必要檔案
    if [ ! -f "cli.py" ]; then
        log_error "找不到 cli.py 檔案"
        exit 1
    fi
    
    if [ ! -d "ampy" ]; then
        log_error "找不到 ampy 目錄"
        exit 1
    fi
    
    # 創建 CLI 導向腳本內容
    log_info "建立 CLI 導向腳本內容..."
    
    cat > cli_script.sh << 'EOF'
#!/bin/bash

# RT-Thread MicroPython CLI 導向腳本
# 此腳本將調用導向到 micropython-tools/cli.py

# 取得腳本所在目錄的父目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
CLI_PY_PATH="$PARENT_DIR/micropython-tools/cli.py"

# 檢測可用的 Python 命令
PYTHON_CMD=""
for cmd in python3 python python3.11 python3.10 python3.9 python3.8; do
    if command -v "$cmd" &> /dev/null; then
        # 檢查版本是否為 Python 3.6+
        if "$cmd" -c "import sys; exit(0 if sys.version_info >= (3, 6) else 1)" 2>/dev/null; then
            PYTHON_CMD="$cmd"
            break
        fi
    fi
done

# 如果找不到合適的 Python，顯示錯誤
if [ -z "$PYTHON_CMD" ]; then
    echo "錯誤: 找不到 Python 3.6 或更高版本"
    echo "請安裝 Python 3.6+ 或執行環境設置腳本"
    exit 1
fi

# 檢查 cli.py 是否存在
if [ ! -f "$CLI_PY_PATH" ]; then
    echo "錯誤: 找不到 $CLI_PY_PATH"
    echo "請確保 micropython-tools 目錄存在並包含 cli.py"
    exit 1
fi

# 執行 cli.py 並傳遞所有參數
exec "$PYTHON_CMD" "$CLI_PY_PATH" "$@"
EOF
    
    # 設定執行權限
    chmod +x cli_script.sh
    
    log_success "CLI 導向腳本建立完成"
}

# 測試建構的導向腳本
test_script() {
    log_info "測試建構的導向腳本..."
    
    if [ -f "cli_script.sh" ]; then
        # 測試基本功能
        if ./cli_script.sh --help > /dev/null 2>&1; then
            log_success "導向腳本測試通過"
            
            # 顯示腳本資訊
            echo "建構的導向腳本資訊："
            ls -lh cli_script.sh
            
            return 0
        else
            log_error "導向腳本測試失敗"
            return 1
        fi
    else
        log_error "找不到建構的導向腳本"
        return 1
    fi
}

# 複製到目標位置
deploy_script() {
    log_info "部署導向腳本..."
    
    local target_dir="../ampy"
    
    # 確保目標目錄存在
    if [ ! -d "${target_dir}" ]; then
        log_warning "目標目錄 ${target_dir} 不存在，建立中..."
        mkdir -p "${target_dir}"
    fi
    
    # 複製導向腳本
    if cp cli_script.sh "${target_dir}/cli"; then
        log_success "導向腳本已複製到 ${target_dir}/cli"
        
        # 設定執行權限
        chmod +x "${target_dir}/cli"
        
        # 測試複製後的檔案
        if "${target_dir}/cli" --help > /dev/null 2>&1; then
            log_success "部署的導向腳本測試通過"
        else
            log_warning "部署的導向腳本測試失敗"
        fi
    else
        log_error "複製導向腳本失敗"
        return 1
    fi
}

# 清理建置檔案
cleanup() {
    log_info "清理暫存檔案..."
    rm -rf build/ dist/ *.spec cli_script.sh
    log_success "清理完成"
}

# 主要流程
main() {
    echo "======================================"
    echo "🚀 RT-Thread MicroPython CLI 建構工具"
    echo "======================================"
    echo
    
    detect_python
    check_and_install_dependencies
    build_cli_script
    
    if test_script; then
        deploy_script
        cleanup
        
        echo
        log_success "🎉 建構完成！"
        echo
        echo "您現在可以使用以下方式執行 CLI："
        echo "  1. Python 版本：${PYTHON_CMD} cli.py --help"
        echo "  2. 導向腳本：../ampy/cli --help"
        echo "  3. 測試串口掃描：${PYTHON_CMD} cli.py -p query portscan"
        echo
    else
        cleanup
        log_warning "建構完成但測試失敗，請檢查錯誤資訊"
        exit 1
    fi
}

# 錯誤處理
trap 'log_error "建構過程中發生錯誤，退出中..."' ERR

# 執行主要流程
main "$@"