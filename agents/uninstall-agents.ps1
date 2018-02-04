# delete service if it exists
if (Get-Service LittleBeat -ErrorAction SilentlyContinue) {
  $service = Get-WmiObject -Class Win32_Service -Filter "name='LittleBeat'"
  $service.delete()
}
