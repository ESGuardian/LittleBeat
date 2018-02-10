@echo off
cd "\ProgramData\osquery"
sc.exe delete osqueryd
del \ProgramData\osquery\logstash.crt
del osqueryd.pidfile
rmdir osquery.db
wevtutil um C:\ProgramData\osquery\osquery.man