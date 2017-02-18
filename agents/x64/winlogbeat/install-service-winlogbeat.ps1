# delete service if it already exists
if (Get-Service winlogbeat -ErrorAction SilentlyContinue) {
  $service = Get-WmiObject -Class Win32_Service -Filter "name='winlogbeat'"
  $service.StopService()
  Start-Sleep -s 1
  $service.delete()
}

$workdir = Split-Path $MyInvocation.MyCommand.Path

# create new service
New-Service -name winlogbeat `
  -displayName winlogbeat `
  -binaryPathName "`"$workdir\\winlogbeat.exe`" -c `"$workdir\\winlogbeat.yml`" -path.home `"$workdir`" -path.data `"C:\\ProgramData\\winlogbeat`""
