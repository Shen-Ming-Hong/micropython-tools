@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM RT-Thread MicroPython CLI 自動安裝工具 (Windows 版本)

echo ===================================================================
echo 🚀 RT-Thread MicroPython CLI 自動安裝工具
echo ===================================================================
echo 此工具將自動安裝並配置 MicroPython CLI 開發環境
echo 包括：
echo   • Python 依賴套件安裝
echo   • CLI 工具建構
echo   • 環境驗證
echo ===================================================================
echo.

REM 檢查是否在正確的目錄
if not exist "cli.py" (
    echo ❌ 找不到 cli.py 檔案
    echo 請確保在 micropython-tools 目錄中執行此腳本
    pause
    exit /b 1
)

if not exist "ampy" (
    echo ❌ 找不到 ampy 目錄
    echo 請確保在 micropython-tools 目錄中執行此腳本
    pause
    exit /b 1
)

REM 檢測 Python
echo 🔍 檢測 Python 環境...

set PYTHON_CMD=
set PYTHON_VERSION=

REM 嘗試不同的 Python 命令
for %%p in (python python3 py) do (
    %%p --version >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "tokens=2" %%v in ('%%p --version 2^>^&1') do (
            set PYTHON_VERSION=%%v
            set PYTHON_CMD=%%p
            goto :python_found
        )
    )
)

echo ❌ 未找到 Python
echo 請先安裝 Python 3.6 或更高版本
echo 下載地址: https://www.python.org/downloads/
pause
exit /b 1

:python_found
echo ✅ 找到 Python: %PYTHON_CMD% %PYTHON_VERSION%

REM 檢查 Python 版本（簡單檢查）
%PYTHON_CMD% -c "import sys; exit(0 if sys.version_info >= (3, 6) else 1)" >nul 2>&1
if !errorlevel! neq 0 (
    echo ❌ Python 版本過舊，需要 3.6 或更高版本
    echo 當前版本: %PYTHON_VERSION%
    pause
    exit /b 1
)

echo ✅ Python 版本符合要求

REM 檢查 pip
echo 🔍 檢查 pip...
%PYTHON_CMD% -m pip --version >nul 2>&1
if !errorlevel! neq 0 (
    echo ❌ pip 不可用
    echo 正在嘗試安裝 pip...
    %PYTHON_CMD% -m ensurepip --upgrade
    if !errorlevel! neq 0 (
        echo ❌ pip 安裝失敗
        pause
        exit /b 1
    )
)

echo ✅ pip 可用

REM 升級 pip
echo 📦 升級 pip...
%PYTHON_CMD% -m pip install --upgrade pip --quiet
if !errorlevel! neq 0 (
    echo ⚠️  pip 升級失敗，但可以繼續
)

REM 安裝依賴套件
echo 📦 安裝 Python 依賴套件...

set packages=click pyserial python-dotenv pyinstaller

for %%p in (%packages%) do (
    echo 正在安裝 %%p...
    %PYTHON_CMD% -m pip install %%p --quiet
    if !errorlevel! neq 0 (
        echo ❌ %%p 安裝失敗
        pause
        exit /b 1
    )
    echo ✅ %%p 安裝成功
)

REM 驗證依賴
echo 🔍 驗證依賴套件...

set verify_packages=click serial dotenv PyInstaller

for %%p in (%verify_packages%) do (
    %PYTHON_CMD% -c "import %%p" >nul 2>&1
    if !errorlevel! neq 0 (
        echo ❌ %%p 驗證失敗
        pause
        exit /b 1
    )
    echo ✅ %%p 驗證通過
)

REM 測試 CLI Python 版本
echo 🧪 測試 CLI Python 版本...
%PYTHON_CMD% cli.py --help >nul 2>&1
if !errorlevel! neq 0 (
    echo ❌ CLI Python 版本測試失敗
    pause
    exit /b 1
)

echo ✅ CLI Python 版本功能正常

REM 嘗試建構導向腳本（在 Windows 上我們直接建立 bat 檔案）
echo 🔨 建立 CLI 導向腳本...

REM 創建 Windows 版本的導向腳本
echo @echo off > cli_redirect.bat
echo setlocal enabledelayedexpansion >> cli_redirect.bat
echo. >> cli_redirect.bat
echo REM RT-Thread MicroPython CLI 導向腳本 >> cli_redirect.bat
echo REM 此腳本將調用導向到 micropython-tools\cli.py >> cli_redirect.bat
echo. >> cli_redirect.bat
echo set SCRIPT_DIR=%%~dp0 >> cli_redirect.bat
echo for %%%%i in ("%%SCRIPT_DIR:~0,-1%%") do set PARENT_DIR=%%%%~dpi >> cli_redirect.bat
echo set CLI_PY_PATH=%%PARENT_DIR%%micropython-tools\cli.py >> cli_redirect.bat
echo. >> cli_redirect.bat
echo REM 檢測可用的 Python 命令 >> cli_redirect.bat
echo set PYTHON_CMD= >> cli_redirect.bat
echo for %%%%p in (python python3 py) do ( >> cli_redirect.bat
echo     %%%%p --version ^>nul 2^>^&1 >> cli_redirect.bat
echo     if ^^!errorlevel^^! equ 0 ( >> cli_redirect.bat
echo         %%%%p -c "import sys; exit(0 if sys.version_info ^>= (3, 6) else 1)" ^>nul 2^>^&1 >> cli_redirect.bat
echo         if ^^!errorlevel^^! equ 0 ( >> cli_redirect.bat
echo             set PYTHON_CMD=%%%%p >> cli_redirect.bat
echo             goto :python_found >> cli_redirect.bat
echo         ^) >> cli_redirect.bat
echo     ^) >> cli_redirect.bat
echo ^) >> cli_redirect.bat
echo. >> cli_redirect.bat
echo echo 錯誤: 找不到 Python 3.6 或更高版本 >> cli_redirect.bat
echo echo 請安裝 Python 3.6+ 或執行環境設置腳本 >> cli_redirect.bat
echo exit /b 1 >> cli_redirect.bat
echo. >> cli_redirect.bat
echo :python_found >> cli_redirect.bat
echo if not exist "%%CLI_PY_PATH%%" ( >> cli_redirect.bat
echo     echo 錯誤: 找不到 %%CLI_PY_PATH%% >> cli_redirect.bat
echo     echo 請確保 micropython-tools 目錄存在並包含 cli.py >> cli_redirect.bat
echo     exit /b 1 >> cli_redirect.bat
echo ^) >> cli_redirect.bat
echo. >> cli_redirect.bat
echo %%PYTHON_CMD%% "%%CLI_PY_PATH%%" %%* >> cli_redirect.bat

REM 複製到目標位置
if not exist "..\ampy" mkdir "..\ampy"
copy "cli_redirect.bat" "..\ampy\cli.bat" >nul
echo ✅ 導向腳本已建立為 ..\ampy\cli.bat

REM 清理暫存檔案
del "cli_redirect.bat" >nul

REM 執行環境檢查
echo 🔍 執行環境驗證...
if exist "check_environment.py" (
    %PYTHON_CMD% check_environment.py
) else (
    echo ⚠️  找不到環境檢查腳本，跳過詳細驗證
)

REM 測試串口掃描
echo 🧪 測試串口掃描功能...
%PYTHON_CMD% cli.py -p query portscan >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ 串口掃描測試通過
) else (
    echo ⚠️  串口掃描測試失敗（可能是沒有連接設備）
)

REM 顯示使用指南
echo.
echo ===================================================================
echo 🎉 安裝完成！使用指南：
echo ===================================================================
echo.
echo 1. 基本命令格式：
echo    %PYTHON_CMD% cli.py [選項] 命令
echo.
echo 2. 常用命令：
echo    掃描串口:     %PYTHON_CMD% cli.py -p query portscan
echo    進入 REPL:    %PYTHON_CMD% cli.py -p [串口] repl
echo    列出檔案:     %PYTHON_CMD% cli.py -p [串口] ls
echo    上傳檔案:     %PYTHON_CMD% cli.py -p [串口] put [本地檔案] [遠端檔案]
echo    下載檔案:     %PYTHON_CMD% cli.py -p [串口] get [遠端檔案] [本地檔案]
echo    執行檔案:     %PYTHON_CMD% cli.py -p [串口] run [檔案]

if exist "..\ampy\cli.bat" (
    echo.
    echo 3. 導向腳本（智能 Python 選擇）：
    echo    將上述命令中的 '%PYTHON_CMD% cli.py' 替換為 '..\ampy\cli.bat'
)

echo.
echo 4. 取得詳細說明：
echo    %PYTHON_CMD% cli.py --help
echo.
echo 5. 範例：
echo    # 掃描可用串口
echo    %PYTHON_CMD% cli.py -p query portscan
echo.
echo    # 連接到 COM3 並進入 REPL
echo    %PYTHON_CMD% cli.py -p COM3 repl
echo.
echo    # 上傳 main.py 到設備
echo    %PYTHON_CMD% cli.py -p COM3 put main.py main.py
echo.
echo ===================================================================
echo.

echo ✅ 🎉 RT-Thread MicroPython CLI 安裝完成！
echo.
pause