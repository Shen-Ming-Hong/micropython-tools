# PyInstaller 打包 CLI 工具指南

## 問題分析

通過檢查代碼變更，發現原因如下：

1. **從二進制轉為 Python 腳本**：項目已從使用預編譯的二進制文件（如 `ampy/cli`）改為直接調用 Python 腳本 `micropython-tools/cli.py`
2. **複雜的依賴關係**：`cli.py` 依賴多個模組，包括自定義的 `ampy` 模組和第三方庫
3. **動態導入**：代碼中使用了動態導入，PyInstaller 難以自動檢測

## 解決方案

### 方法1：使用提供的打包腳本（推薦）

```bash
cd /Users/user/.vscode-insiders/extensions/rt-thread.rt-thread-micropython-1.0.11/micropython-tools
./build_cli.sh
```

### 方法2：手動打包步驟

1. **安裝依賴**：
```bash
pip3 install pyinstaller click python-dotenv pyserial
```

2. **進入目錄**：
```bash
cd /Users/user/.vscode-insiders/extensions/rt-thread.rt-thread-micropython-1.0.11/micropython-tools
```

3. **使用 spec 文件打包**：
```bash
pyinstaller build_cli.spec
```

4. **或使用命令行參數**：
```bash
pyinstaller \
    --onefile \
    --name cli \
    --add-data "ampy:ampy" \
    --hidden-import ampy \
    --hidden-import ampy.files \
    --hidden-import ampy.pyboard \
    --hidden-import ampy.getch \
    --hidden-import ampy.file_sync \
    --hidden-import click \
    --hidden-import dotenv \
    --hidden-import serial \
    --hidden-import serial.tools.list_ports \
    --console \
    cli.py
```

### 方法3：檢查並修復現有問題

如果打包後的 `cli` 無法正常工作，可能是因為：

1. **缺少隱藏依賴**：
   - 運行打包後的程序，查看錯誤信息
   - 添加缺少的模組到 `hiddenimports` 列表

2. **路徑問題**：
   - 確保 `ampy` 模組能被正確找到
   - 檢查相對路徑是否正確

3. **權限問題**：
   ```bash
   chmod +x dist/cli
   ```

## 測試打包結果

1. **基本功能測試**：
```bash
./dist/cli --help
./dist/cli portscan
```

2. **串口功能測試**：
```bash
./dist/cli -p /dev/ttyUSB0 repl -q rtt
```

## 常見問題及解決方案

### 問題1：`ModuleNotFoundError`
**解決方案**：添加缺少的模組到 `hiddenimports` 或使用 `--hidden-import`

### 問題2：`No module named 'ampy'`
**解決方案**：確保使用了 `--add-data "ampy:ampy"` 參數

### 問題3：串口權限問題
**解決方案**：
```bash
sudo chmod 666 /dev/ttyUSB*
# 或將用戶添加到 dialout 組
sudo usermod -a -G dialout $USER
```

### 問題4：macOS 安全限制
**解決方案**：
```bash
# 允許執行未簽名的二進制文件
xattr -cr dist/cli
```

## 驗證成功標準

打包成功的 CLI 工具應該能夠：
1. 顯示幫助信息（`--help`）
2. 掃描串口（`portscan`）
3. 連接並與 MicroPython 設備通信
4. 執行文件同步操作

如果以上功能都正常，說明打包成功且功能完整。