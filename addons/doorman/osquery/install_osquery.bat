@echo off
cd \ProgramData\osquery
PowerShell.exe Invoke-WebRequest -Uri "http://littlebeat/doorman/logstash.crt" -OutFile "\ProgramData\osquery\logstash.crt" 
PowerShell.exe -ExecutionPolicy Bypass -File .\set_acl.ps1
rem wevtutil im C:\ProgramData\osquery\osquery.man
sc.exe create osqueryd type=own start=auto error=normal binpath="C:\ProgramData\osquery\osqueryd\osqueryd.exe --flagfile=\ProgramData\osquery\osquery.flags" displayname=osqueryd
