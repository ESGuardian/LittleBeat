@echo off
cd "\Program Files\LittleBeat Agent"
PowerShell.exe Set-ExecutionPolicy Bypass -Force
PowerShell.exe .\uninstall-agents.ps1
PowerShell.exe Set-ExecutionPolicy Restricted -Force

