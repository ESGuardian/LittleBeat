@echo off
cd "\ProgramData\osquery"
sc.exe stop osqueryd
ping 127.0.0.1 -n 6 > nul
sc.exe delete osqueryd
if exist \ProgramData\osquery\osqueryd.pidfile del \ProgramData\osquery\osqueryd.pidfile
wevtutil um C:\ProgramData\osquery\osquery.man
if exist \ProgramData\osquery\osquery.db rmdir /s /q \ProgramData\osquery\osquery.db
