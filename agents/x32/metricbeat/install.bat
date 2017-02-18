@echo off
mkdir "C:\Program Files\metricbeat"
copy *.* "C:\Program Files\metricbeat"
cd "C:\Program Files\metricbeat"
PowerShell.exe Set-ExecutionPolicy Unrestricted -Force
PowerShell.exe Unblock-File -Path 'C:\Program Files\metricbeat\install-service-metricbeat.ps1'
PowerShell.exe .\install-service-metricbeat.ps1
PowerShell.exe Set-ExecutionPolicy Restricted -Force
net start metricbeat
