# delete service if it already exists
if (Get-Service LittleBeat -ErrorAction SilentlyContinue) {
  $service = Get-WmiObject -Class Win32_Service -Filter "name='LittleBeat'"
  $service.StopService()
  Start-Sleep -s 1
  $service.delete()
}

$workdir = "C:\Program Files\LittleBeat Agent"

# create new service
New-Service -name LittleBeat `
  -displayName LittleBeat `
  -binaryPathName "`"$workdir\winlogbeat.exe`" -c `"$workdir\winlogbeat.yml`" -path.home `"$workdir`" -path.data `"C:\ProgramData\LittleBeat`" -path.logs `"C:\ProgramData\LittleBeat\logs`""
# start service
Start-Sleep -s 5
Start-Service -Name LittleBeat

