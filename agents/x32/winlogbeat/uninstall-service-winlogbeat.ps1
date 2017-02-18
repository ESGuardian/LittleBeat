# delete service if it exists
if (Get-Service winlogbeat -ErrorAction SilentlyContinue) {
  $service = Get-WmiObject -Class Win32_Service -Filter "name='winlogbeat'"
  $service.delete()
}
