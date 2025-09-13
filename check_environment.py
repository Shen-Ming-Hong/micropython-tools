#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RT-Thread MicroPython CLI 環境檢測工具
用於檢查系統環境是否符合 cli.py 執行要求
"""

import sys
import os
import platform
import subprocess
import importlib.util
from pathlib import Path

class EnvironmentChecker:
    def __init__(self):
        self.python_version = sys.version_info
        self.platform_system = platform.system()
        self.required_packages = [
            'click', 'pyserial', 'dotenv', 'pyinstaller'
        ]
        self.issues = []
        self.recommendations = []
        
    def check_python_version(self):
        """檢查 Python 版本"""
        print(f"🔍 檢查 Python 版本: {sys.version}")
        
        if self.python_version.major < 3:
            self.issues.append("❌ Python 版本過舊，需要 Python 3.6 或更高版本")
            self.recommendations.append("請升級到 Python 3.6 或更高版本")
            return False
        elif self.python_version.minor < 6:
            self.issues.append("❌ Python 版本過舊，需要 Python 3.6 或更高版本")
            self.recommendations.append("請升級到 Python 3.6 或更高版本")
            return False
        else:
            print("✅ Python 版本符合要求")
            return True
    
    def check_pip(self):
        """檢查 pip 是否可用"""
        print("🔍 檢查 pip...")
        try:
            subprocess.run([sys.executable, '-m', 'pip', '--version'], 
                         check=True, capture_output=True)
            print("✅ pip 可用")
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            self.issues.append("❌ pip 不可用")
            self.recommendations.append("請安裝 pip: python -m ensurepip --upgrade")
            return False
    
    def check_required_packages(self):
        """檢查必要的 Python 套件"""
        print("🔍 檢查必要套件...")
        missing_packages = []
        
        for package in self.required_packages:
            if package == 'dotenv':
                package_name = 'python-dotenv'
            else:
                package_name = package
                
            spec = importlib.util.find_spec(package)
            if spec is None:
                missing_packages.append(package_name)
                print(f"❌ 缺少套件: {package_name}")
            else:
                print(f"✅ 套件已安裝: {package_name}")
        
        if missing_packages:
            self.issues.append(f"❌ 缺少必要套件: {', '.join(missing_packages)}")
            self.recommendations.append(f"請安裝缺少的套件: pip install {' '.join(missing_packages)}")
            return False
        
        return True
    
    def check_serial_permissions(self):
        """檢查序列埠權限（Linux/macOS）"""
        if self.platform_system in ['Linux', 'Darwin']:
            print("🔍 檢查序列埠權限...")
            
            # 檢查 /dev 目錄下的串口設備
            try:
                import serial.tools.list_ports
                ports = list(serial.tools.list_ports.comports())
                
                if not ports:
                    print("⚠️  未發現任何串口設備")
                    self.recommendations.append("請確保設備已連接")
                else:
                    print(f"✅ 發現 {len(ports)} 個串口設備")
                    for port in ports[:3]:  # 只顯示前3個
                        print(f"   - {port.device}")
                
                # Linux 特定檢查
                if self.platform_system == 'Linux':
                    import grp
                    try:
                        dialout_group = grp.getgrnam('dialout')
                        current_user = os.getlogin()
                        if current_user not in dialout_group.gr_mem:
                            self.recommendations.append(
                                f"建議將使用者 {current_user} 加入 dialout 群組: "
                                f"sudo usermod -aG dialout {current_user}"
                            )
                    except (KeyError, OSError):
                        pass
                        
                return True
                
            except ImportError:
                self.recommendations.append("無法檢查串口設備，pyserial 可能未正確安裝")
                return False
        
        return True
    
    def check_cli_files(self):
        """檢查 CLI 相關檔案"""
        print("🔍 檢查 CLI 檔案...")
        
        current_dir = Path(__file__).parent
        cli_py = current_dir / 'cli.py'
        ampy_dir = current_dir / 'ampy'
        
        if not cli_py.exists():
            self.issues.append("❌ 找不到 cli.py 檔案")
            return False
        else:
            print("✅ cli.py 檔案存在")
        
        if not ampy_dir.exists():
            self.issues.append("❌ 找不到 ampy 目錄")
            return False
        else:
            print("✅ ampy 目錄存在")
            
        return True
    
    def test_cli_basic_function(self):
        """測試 CLI 基本功能"""
        print("🔍 測試 CLI 基本功能...")
        
        try:
            current_dir = Path(__file__).parent
            cli_py = current_dir / 'cli.py'
            
            # 測試 --help
            result = subprocess.run([
                sys.executable, str(cli_py), '--help'
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0 and 'ampy' in result.stdout:
                print("✅ CLI 基本功能正常")
                return True
            else:
                self.issues.append("❌ CLI 基本功能異常")
                print(f"錯誤輸出: {result.stderr}")
                return False
                
        except (subprocess.TimeoutExpired, FileNotFoundError, Exception) as e:
            self.issues.append(f"❌ CLI 測試失敗: {str(e)}")
            return False
    
    def generate_setup_script(self):
        """生成自動安裝腳本"""
        print("\n📝 正在生成自動安裝腳本...")
        
        if self.platform_system == 'Windows':
            script_name = 'setup_environment.bat'
            script_content = self._generate_windows_script()
        else:
            script_name = 'setup_environment.sh'
            script_content = self._generate_unix_script()
        
        current_dir = Path(__file__).parent
        script_path = current_dir / script_name
        
        with open(script_path, 'w', encoding='utf-8') as f:
            f.write(script_content)
        
        if self.platform_system != 'Windows':
            os.chmod(script_path, 0o755)
        
        print(f"✅ 自動安裝腳本已生成: {script_path}")
        return script_path
    
    def _generate_windows_script(self):
        """生成 Windows 批次檔"""
        return """@echo off
chcp 65001 >nul
echo ===================================
echo RT-Thread MicroPython CLI 環境設置
echo ===================================

echo 正在檢查 Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python 未安裝或不在 PATH 中
    echo 請先安裝 Python 3.6 或更高版本
    pause
    exit /b 1
)

echo ✅ Python 已安裝

echo 正在安裝必要套件...
python -m pip install --upgrade pip
python -m pip install click pyserial python-dotenv pyinstaller

echo 正在測試 CLI 功能...
python cli.py --help >nul 2>&1
if errorlevel 1 (
    echo ❌ CLI 測試失敗
    pause
    exit /b 1
)

echo ✅ 環境設置完成！
echo 您現在可以使用以下命令測試:
echo   python cli.py -p query portscan
pause
"""
    
    def _generate_unix_script(self):
        """生成 Unix shell 腳本"""
        return """#!/bin/bash
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
"""
    
    def run_full_check(self):
        """執行完整檢查"""
        print("🚀 開始 RT-Thread MicroPython CLI 環境檢查...\n")
        
        checks = [
            self.check_python_version,
            self.check_pip,
            self.check_required_packages,
            self.check_serial_permissions,
            self.check_cli_files,
            self.test_cli_basic_function
        ]
        
        all_passed = True
        for check in checks:
            if not check():
                all_passed = False
            print()  # 空行分隔
        
        # 顯示結果
        print("=" * 50)
        if all_passed:
            print("🎉 所有檢查都通過！環境已準備就緒。")
        else:
            print("⚠️  發現一些問題需要解決:")
            for issue in self.issues:
                print(f"  {issue}")
            
            if self.recommendations:
                print("\n💡 建議解決方案:")
                for rec in self.recommendations:
                    print(f"  • {rec}")
        
        # 無論如何都生成安裝腳本
        self.generate_setup_script()
        
        return all_passed

def main():
    checker = EnvironmentChecker()
    success = checker.run_full_check()
    
    if not success:
        print(f"\n💡 建議執行自動安裝腳本來解決環境問題")
        
    return 0 if success else 1

if __name__ == '__main__':
    sys.exit(main())