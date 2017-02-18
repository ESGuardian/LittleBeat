# delete service if it exists
if (Get-Service metricbeat -ErrorAction SilentlyContinue) {
  $service = Get-WmiObject -Class Win32_Service -Filter "name='metricbeat'"
  $service.delete()
}
