@echo off
cd "\ProgramData\osquery"
sc.exe stop osqueryd
ping 127.0.0.1 -n 11 > nul
sc.exe delete osqueryd
del \ProgramData\osquery\logstash.crt
del \ProgramData\osquery\osqueryd.pidfile
rmdir /s /q \ProgramData\osquery\osquery.db
