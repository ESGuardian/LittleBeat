@echo off
cd \ProgramData\osquery
rem PowerShell.exe Invoke-WebRequest -Uri "http://littlebeat/doorman/logstash.crt" -OutFile "\ProgramData\osquery\logstash.crt" 
PowerShell.exe -ExecutionPolicy Bypass -File .\set_acl.ps1
wevtutil im C:\ProgramData\osquery\osquery.man
sc.exe create osqueryd type=own start=auto error=normal binpath="C:\ProgramData\osquery\osqueryd\osqueryd.exe --flagfile=\ProgramData\osquery\osquery_no_tls.flags" displayname=osqueryd
ping 127.0.0.1 -n 6 > nul
sc.exe start osqueryd
sc.exe stop LittleBeat
ping 127.0.0.1 -n 6 > nul
del "\Program Files\LittleBeat Agent\winlogbeat.yml"
copy \ProgramData\osquery\winlogbeat.yml "\Program Files\LittleBeat Agent\winlogbeat.yml"
sc.exe start LittleBeat

