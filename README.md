# MicroPython Tools

一個功能強大的 MicroPython 開發工具集，用於通過串口與 MicroPython 設備進行通信、文件管理和代碼執行。本專案原本為 [RT-Thread MicroPython IDE](https://marketplace.visualstudio.com/items?itemName=RT-Thread.rt-thread-micropython) 的後端命令行工具，現已擴展支持更廣泛的 MicroPython 設備。

## ✨ 主要特性

- 🔌 **多平台串口通信**: 支持 Windows、Linux、macOS
- 📁 **完整文件管理**: 上傳、下載、創建、刪除文件和目錄
- ⚡ **智能文件同步**: 基於 CRC32 校驗的增量同步
- 🖥️ **交互式 REPL**: 直接在終端中執行 MicroPython 代碼
- 🎯 **設備掃描**: 自動掃描可用串口設備
- 🔧 **一鍵環境配置**: 自動化環境檢測與配置工具

## 🚀 快速開始

### 自動化安裝（推薦）

我們提供了自動化工具來快速配置開發環境：

```bash
# 1. 首先檢查環境是否符合要求
python3 check_environment.py

# 2. 使用一鍵安裝腳本
# Linux/macOS:
chmod +x setup_cli_environment.sh
./setup_cli_environment.sh

# Windows:
setup_cli_environment.bat
```

### 手動安裝

如果您偏好手動安裝，請執行：

```bash
# 安裝必要依賴
python -m pip install click pyserial python-dotenv pyinstaller

# 驗證安裝
python cli.py --help
```

## 🔧 基本用法

### 掃描可用串口

在連接設備之前，先掃描系統中可用的串口：

```bash
python cli.py -p query portscan
```

### 連接設備

所有操作都需要指定串口，例如：

```bash
# Linux/macOS
python cli.py -p /dev/ttyUSB0 [命令]

# Windows
python cli.py -p COM3 [命令]
```

### 進入 REPL 模式

連接設備並進入交互式 Python 解釋器：

```bash
python cli.py -p /dev/ttyUSB0 repl
```

**提示**: 在 REPL 模式中使用 `Ctrl+X` 退出

## 📁 文件系統操作

### 瀏覽文件和目錄

| 命令 | 功能 |
|------|------|
| `ls` | 列出根目錄中的文件 |
| `ls -r` | 遞歸列出所有文件和目錄 |
| `ls -r -l` | 遞歸列出文件並顯示 CRC 校驗值 |
| `ls /path` | 列出指定路徑中的文件 |

```bash
# 列出設備根目錄內容
python cli.py -p /dev/ttyUSB0 ls

# 遞歸列出所有文件，並顯示詳細信息
python cli.py -p /dev/ttyUSB0 ls -r -l

# 列出特定目錄內容
python cli.py -p /dev/ttyUSB0 ls /scripts
```

### 創建和刪除操作

| 命令 | 功能 |
|------|------|
| `mkdir <目錄名>` | 創建目錄 |
| `rmdir <目錄名>` | 遞歸刪除目錄及其內容 |
| `rm <文件名>` | 刪除指定文件 |

```bash
# 創建目錄
python cli.py -p /dev/ttyUSB0 mkdir my_project

# 刪除文件
python cli.py -p /dev/ttyUSB0 rm old_file.py

# 遞歸刪除目錄
python cli.py -p /dev/ttyUSB0 rmdir old_project
```

## 📤📥 文件傳輸

### 基本文件操作

| 命令 | 功能 |
|------|------|
| `get <遠程文件> [本地文件]` | 從設備下載文件 |
| `put <本地文件> [遠程文件]` | 上傳文件到設備 |
| `put <本地目錄> <遠程目錄>` | 上傳整個目錄 |

```bash
# 下載文件到本地
python cli.py -p /dev/ttyUSB0 get main.py local_main.py

# 上傳文件到設備
python cli.py -p /dev/ttyUSB0 put local_file.py remote_file.py

# 上傳整個目錄
python cli.py -p /dev/ttyUSB0 put ./my_project /remote_project
```

**注意**: 上傳的文件必須是 Unix 格式（LF 行結束符）

### 智能文件同步

對於大型專案，建議使用同步功能：

```bash
python cli.py -p /dev/ttyUSB0 sync -l "./local_project" -i "./sync_cache.json"
```

參數說明：
- `-l`: 本地項目目錄路徑
- `-i`: 本地緩存文件路徑（用於存儲同步狀態）

同步功能會：
- 🔍 計算文件 CRC32 校驗值
- ⚡ 只傳輸變更的文件
- 🗑️ 自動刪除設備上的冗餘文件
- 💾 緩存設備文件狀態以提高效率

## ▶️ 代碼執行

### 運行 Python 腳本

| 命令 | 功能 |
|------|------|
| `run <本地文件>` | 執行本地 Python 文件 |
| `run none -d <設備文件>` | 執行設備上的 Python 文件 |
| `run --no-output <文件>` | 執行文件但不等待輸出 |

```bash
# 執行本地文件
python cli.py -p /dev/ttyUSB0 run test.py

# 執行設備上的文件
python cli.py -p /dev/ttyUSB0 run none -d main.py

# 執行包含無限循環的程序（不等待輸出）
python cli.py -p /dev/ttyUSB0 run --no-output server.py
```

**提示**: 對於包含 `while True` 循環或長時間運行的程序，務必使用 `--no-output` 選項

## ⚙️ 高級功能

### 環境變數配置

在專案根目錄創建 `.ampy` 文件來設定默認參數：

```bash
# .ampy 文件內容
AMPY_PORT=/dev/ttyUSB0
AMPY_BAUD=115200
AMPY_DELAY=0
```

設置後可以省略 `-p` 參數：

```bash
# 不再需要 -p 參數
python cli.py ls
python cli.py repl
```

### REPL 高級控制

在 REPL 模式中，有一些特殊控制字符：

- 發送 `0xe8` (232): 關閉回顯
- 發送 `0xe9` (233): 開啟回顯  
- `Ctrl+E`: 進入粘貼模式
- `Ctrl+X`: 退出 REPL

### 設備重置

```bash
# 軟重置（進入 REPL）
python cli.py -p /dev/ttyUSB0 reset --repl

# 硬重置（運行 init.py）
python cli.py -p /dev/ttyUSB0 reset --hard
```

## 🔨 打包和部署

### 構建可執行文件

為了在不同系統上分發，可以將 CLI 工具打包成可執行文件：

#### 自動構建（推薦）

```bash
# 使用提供的構建腳本
chmod +x build_cli.sh
./build_cli.sh
```

#### 手動構建

```bash
# Windows
pyinstaller.exe -F cli.py -p ampy

# Linux/macOS
pyinstaller -F cli.py -p ampy
```

構建成功後，可執行文件位於 `dist/` 目錄中。

### VS Code 擴展集成

如果您正在開發 VS Code 擴展，可以將構建的工具放置在：

```
.vscode/extensions/your-extension/ampy/cli
```

### 跨平台部署

本專案包含了針對不同平台的優化：

- **Go 輔助工具**: `go/mac/` 目錄包含 macOS 專用的串口掃描工具
- **Python 核心**: 跨平台兼容的主要功能
- **自動化腳本**: 各平台的環境配置腳本

## 🐛 故障排除

### 常見問題

#### 1. 串口權限問題（Linux）

```bash
# 將使用者加入 dialout 群組
sudo usermod -aG dialout $USER

# 重新登入後驗證
groups $USER
```

#### 2. Python 版本問題

確保使用 Python 3.6 或更高版本：

```bash
python3 --version
```

#### 3. 依賴套件問題

重新安裝所有依賴：

```bash
pip install --upgrade click pyserial python-dotenv pyinstaller
```

#### 4. 串口連接失敗

檢查設備連接和串口權限：

```bash
# 掃描可用串口
python cli.py -p query portscan

# Linux: 檢查串口設備
ls -la /dev/tty*

# 檢查設備是否被其他程序佔用
sudo lsof /dev/ttyUSB0
```

#### 5. 文件同步問題

- 刪除緩存文件重新同步：`rm sync_cache.json`
- 檢查文件編碼格式（應使用 UTF-8）
- 確保本地文件使用 Unix 行結束符（LF）

### 環境檢測

使用內建的環境檢測工具：

```bash
python3 check_environment.py
```

此工具會自動檢查：
- ✅ Python 版本兼容性
- ✅ 必要套件安裝狀態  
- ✅ 串口權限配置
- ✅ CLI 基本功能測試

## 📊 項目結構

```
micropython-tools/
├── cli.py                       # 主要 CLI 入口點
├── ampy/                        # 核心功能模組
│   ├── __init__.py
│   ├── files.py                 # 文件操作核心
│   ├── pyboard.py              # 設備通信核心
│   ├── file_sync.py            # 文件同步邏輯
│   └── getch.py                # 跨平台字符輸入
├── go/                          # Go 輔助工具
│   └── mac/                     # macOS 專用工具
│       ├── mac_ports_scan.go    # 串口掃描
│       └── mac_query_if_right.go
├── sync/                        # 同步功能模組
│   ├── __download.py
│   └── __upload.py
├── check_environment.py         # 環境檢測工具 ✨
├── setup_cli_environment.sh     # Linux/macOS 安裝腳本 ✨
├── setup_cli_environment.bat    # Windows 安裝腳本 ✨
├── build_cli.sh                 # 構建腳本 ✨
├── SETUP_GUIDE.md              # 詳細安裝指南 ✨
└── README.md                   # 本文檔
```

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request！

### 開發環境設置

1. 克隆項目：
```bash
git clone <repository-url>
cd micropython-tools
```

2. 安裝開發依賴：
```bash
pip install -r requirements.txt  # 如果存在
# 或者
pip install click pyserial python-dotenv pyinstaller
```

3. 運行測試：
```bash
python3 check_environment.py
```

### 代碼貢獻指南

- 遵循 PEP 8 代碼風格
- 添加適當的註釋和文檔
- 確保跨平台兼容性
- 提交前運行環境檢測工具

## 📄 許可證

本項目基於 MIT 許可證開源。詳見 [LICENSE](LICENSE) 文件。

## 🙏 致謝

- 基於 [Adafruit MicroPython Tool (ampy)](https://github.com/scientifichackers/ampy) 開發
- 原始項目由 Tony DiCola 創建
- RT-Thread 團隊的改進和擴展
- 感謝所有貢獻者的努力

## 📞 支持

如需幫助：

1. 📖 查看 [SETUP_GUIDE.md](SETUP_GUIDE.md) 獲取詳細安裝指南
2. 🔧 運行 `python3 check_environment.py` 診斷環境問題  
3. 🐛 在 GitHub Issues 中報告問題
4. 💬 加入相關社區討論

---

**快樂的 MicroPython 開發！** 🐍✨
