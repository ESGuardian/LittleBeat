@echo off
cd "C:\Program Files\winlogbeat"
PowerShell.exe Set-ExecutionPolicy Unrestricted -Force
PowerShell.exe Unblock-File -Path 'C:\Program Files\winlogbeat\uninstall-service-winlogbeat.ps1'
PowerShell.exe .\uninstall-service-winlogbeat.ps1
PowerShell.exe Set-ExecutionPolicy Restricted -Force
del "C:\Program Files\winlogbeat\winlogbeat.exe"
del "C:\Program Files\winlogbeat\winlogbeat.yml"

