@echo off
mkdir "C:\Program Files\winlogbeat"
copy *.* "C:\Program Files\winlogbeat"
cd "C:\Program Files\winlogbeat"
PowerShell.exe Set-ExecutionPolicy Unrestricted -Force
PowerShell.exe Unblock-File -Path 'C:\Program Files\winlogbeat\install-service-winlogbeat.ps1'
PowerShell.exe .\install-service-winlogbeat.ps1
PowerShell.exe Set-ExecutionPolicy Restricted -Force
net start winlogbeat
