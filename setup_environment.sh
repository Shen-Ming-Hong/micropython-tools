#!/bin/bash
set -e

echo "==================================="
echo "RT-Thread MicroPython CLI 環境設置"
echo "==================================="

# 檢查 Python
echo "🔍 檢查 Python..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安裝"
    echo "請先安裝 Python 3.6 或更高版本"
    exit 1
fi

PYTHON_CMD=python3
echo "✅ Python3 已安裝: $(python3 --version)"

# 檢查 pip
echo "🔍 檢查 pip..."
if ! $PYTHON_CMD -m pip --version &> /dev/null; then
    echo "❌ pip 不可用"
    echo "正在嘗試安裝 pip..."
    $PYTHON_CMD -m ensurepip --upgrade
fi

echo "✅ pip 可用"

# 安裝必要套件
echo "📦 安裝必要套件..."
$PYTHON_CMD -m pip install --upgrade pip
$PYTHON_CMD -m pip install click pyserial python-dotenv pyinstaller

# Linux 特定設置
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Linux 系統特定設置..."
    
    # 檢查 dialout 群組
    if groups $USER | grep -q dialout; then
        echo "✅ 使用者已在 dialout 群組中"
    else
        echo "⚠️  建議將使用者加入 dialout 群組以獲得串口權限:"
        echo "   sudo usermod -aG dialout $USER"
        echo "   執行後需要重新登入"
    fi
fi

# 測試 CLI 功能
echo "🧪 測試 CLI 功能..."
if $PYTHON_CMD cli.py --help > /dev/null 2>&1; then
    echo "✅ CLI 功能正常"
else
    echo "❌ CLI 測試失敗"
    exit 1
fi

# 嘗試建構二進位檔案
echo "🔨 嘗試建構 CLI 二進位檔案..."
if [ -f "build_cli.sh" ]; then
    chmod +x build_cli.sh
    if ./build_cli.sh; then
        echo "✅ CLI 二進位檔案建構成功"
    else
        echo "⚠️  二進位檔案建構失敗，但 Python 版本仍可使用"
    fi
else
    echo "⚠️  未找到 build_cli.sh，跳過二進位檔案建構"
fi

echo ""
echo "🎉 環境設置完成！"
echo ""
echo "您現在可以使用以下命令測試:"
echo "  $PYTHON_CMD cli.py -p query portscan   # 掃描可用串口"
echo "  $PYTHON_CMD cli.py --help              # 顯示幫助信息"
echo ""

if [[ "$OSTYPE" == "linux-gnu"* ]] && ! groups $USER | grep -q dialout; then
    echo "⚠️  注意: 如果串口權限有問題，請執行:"
    echo "   sudo usermod -aG dialout $USER"
    echo "   然後重新登入"
fi
