# RT-Thread MicroPython CLI 快速環境建構指南

## 概述

當您將 `micropython-tools` 資料夾放入 RT-Thread 擴充元件資料夾後，可以使用以下自動化工具來快速建構適合 `cli.py` 執行的環境。

## 自動化工具

### 1. 環境檢測工具 - `check_environment.py`

**用途**: 檢查系統環境是否符合 CLI 執行要求

**使用方法**:
```bash
# 在 micropython-tools 目錄中執行
python3 check_environment.py
```

**功能**:
- ✅ 檢查 Python 版本 (需要 3.6+)
- ✅ 檢查 pip 可用性
- ✅ 檢查必要 Python 套件
- ✅ 檢查串口權限 (Linux/macOS)
- ✅ 驗證 CLI 檔案完整性
- ✅ 測試 CLI 基本功能
- 🔧 自動生成對應平台的安裝腳本

### 2. 一鍵安裝工具

#### Linux/macOS: `setup_cli_environment.sh`

**使用方法**:
```bash
# 在 micropython-tools 目錄中執行
chmod +x setup_cli_environment.sh
./setup_cli_environment.sh
```

#### Windows: `setup_cli_environment.bat`

**使用方法**:
```cmd
REM 在 micropython-tools 目錄中執行
setup_cli_environment.bat
```

**功能**:
- 🔍 自動檢測 Python 環境
- 📦 安裝所有必要依賴套件
- 🔨 建構 CLI 二進位版本
- 🧪 執行功能測試
- ⚙️  設定串口權限 (Linux)
- 📋 提供詳細使用指南

### 3. CLI 建構工具 - `build_cli.sh`

**用途**: 專門用於建構 CLI 導向腳本

**使用方法**:
```bash
chmod +x build_cli.sh
./build_cli.sh
```

**功能**:
- 🛠️  建立智能 CLI 導向腳本
- � 自動檢測最佳 Python 環境
- ✅ 自動測試建構結果
- 📁 自動部署到 `../ampy/cli`

## 快速開始

### 情境：全新電腦環境

1. **將 `micropython-tools` 資料夾放入擴充元件目錄**:
   ```
   .vscode/extensions/rt-thread.rt-thread-micropython-x.x.x/micropython-tools/
   ```

2. **執行一鍵安裝** (推薦):
   
   **Linux/macOS**:
   ```bash
   cd micropython-tools
   chmod +x setup_cli_environment.sh
   ./setup_cli_environment.sh
   ```
   
   **Windows**:
   ```cmd
   cd micropython-tools
   setup_cli_environment.bat
   ```

3. **驗證安裝**:
   ```bash
   # 掃描可用串口
   python3 cli.py -p query portscan
   
   # 顯示幫助信息
   python3 cli.py --help
   ```

### 情境：只想檢查環境

```bash
cd micropython-tools
python3 check_environment.py
```

### 情境：只需要建構導向腳本

```bash
cd micropython-tools
chmod +x build_cli.sh
./build_cli.sh
```

## 系統需求

### 最低需求
- **Python**: 3.6 或更高版本
- **pip**: 可用的 pip 包管理器
- **儲存空間**: 至少 100MB 用於依賴套件

### 推薦配置
- **Python**: 3.8 或更高版本
- **作業系統**: 
  - Linux: Ubuntu 18.04+ / CentOS 7+ / Arch Linux
  - macOS: 10.14+ 
  - Windows: 10+

## 依賴套件

以下套件會自動安裝：

- **click**: 命令列介面框架
- **pyserial**: 串口通訊
- **python-dotenv**: 環境變數管理
- **pyinstaller**: 二進位建構工具

## 故障排除

### Python 版本問題
```bash
# 檢查 Python 版本
python3 --version

# 如果版本過舊，安裝新版本
# Ubuntu/Debian:
sudo apt update && sudo apt install python3.8

# CentOS/RHEL:
sudo yum install python3

# macOS (Homebrew):
brew install python

# Windows: 
# 從 https://www.python.org/downloads/ 下載安裝
```

### 串口權限問題 (Linux)
```bash
# 將使用者加入 dialout 群組
sudo usermod -aG dialout $USER

# 重新登入後檢查
groups $USER
```

### PyInstaller 建構失敗
```bash
# 手動安裝 PyInstaller
pip3 install --upgrade pyinstaller

# 清理快取並重試
pip3 cache purge
./build_cli.sh
```

### 套件安裝失敗
```bash
# 升級 pip
python3 -m pip install --upgrade pip

# 使用清華源安裝
pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple click pyserial python-dotenv pyinstaller
```

## 使用範例

### 基本連線測試
```bash
# 1. 掃描可用串口
python3 cli.py -p query portscan

# 2. 連接設備進入 REPL (以 /dev/ttyUSB0 為例)
python3 cli.py -p /dev/ttyUSB0 repl
# 使用 Ctrl+X 退出 REPL

# 3. 列出設備上的檔案
python3 cli.py -p /dev/ttyUSB0 ls -l
```

### 檔案操作
```bash
# 上傳本地檔案到設備
python3 cli.py -p /dev/ttyUSB0 put main.py main.py

# 從設備下載檔案
python3 cli.py -p /dev/ttyUSB0 get boot.py local_boot.py

# 執行設備上的檔案
python3 cli.py -p /dev/ttyUSB0 run main.py
```

### 資料夾同步
```bash
# 同步本地資料夾到設備
python3 cli.py -p /dev/ttyUSB0 sync -l ./my_project -i ./sync_cache.json
```

## 進階設定

### 使用環境變數
建立 `.ampy` 檔案於專案根目錄：
```bash
# .ampy 檔案內容
AMPY_PORT=/dev/ttyUSB0
AMPY_BAUD=115200
AMPY_DELAY=0
```

### 導向腳本優勢
建構成功後，可使用導向腳本獲得智能 Python 環境選擇：
```bash
# 使用導向腳本 (在 ampy 目錄中)
../ampy/cli -p /dev/ttyUSB0 repl
```

導向腳本會自動：
- 🔍 檢測最佳可用的 Python 版本
- ✅ 驗證 Python 環境是否符合要求
- 🚀 自動調用正確的 cli.py 路徑

## 技術支援

如果遇到問題：

1. **先執行環境檢查**: `python3 check_environment.py`
2. **查看詳細錯誤**: 大部分腳本都會顯示具體的錯誤信息和建議
3. **檢查 README.md**: 查看原始專案文檔
4. **手動安裝**: 如果自動化失敗，可以手動執行各個步驟

## 檔案結構

安裝後的目錄結構：
```
micropython-tools/
├── cli.py                      # 主要 CLI 腳本
├── ampy/                       # CLI 核心模組
├── check_environment.py        # 環境檢測工具 ✨
├── setup_cli_environment.sh    # Linux/macOS 一鍵安裝 ✨
├── setup_cli_environment.bat   # Windows 一鍵安裝 ✨
├── build_cli.sh                # 建構工具 (已優化) ✨
├── README.md                   # 原始說明文檔
└── SETUP_GUIDE.md             # 本文檔 ✨

../ampy/
└── cli                         # 建構的導向腳本 ✨
```

**✨ 標記的檔案為新增的自動化工具**