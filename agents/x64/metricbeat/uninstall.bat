@echo off
cd "C:\Program Files\metricbeat"
PowerShell.exe Set-ExecutionPolicy Unrestricted -Force
PowerShell.exe Unblock-File -Path 'C:\Program Files\metricbeat\uninstall-service-metricbeat.ps1'
PowerShell.exe .\uninstall-service-metricbeat.ps1
PowerShell.exe Set-ExecutionPolicy Restricted -Force
del "C:\Program Files\metricbeat\metricbeat.exe"
del "C:\Program Files\metricbeat\metricbeat.yml"

