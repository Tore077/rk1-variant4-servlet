$env:CATALINA_HOME = Join-Path $PSScriptRoot '.runtime/apache-tomcat-9.0.121'
$env:CATALINA_BASE = $env:CATALINA_HOME
$env:JAVA_HOME = (Get-ChildItem (Join-Path $PSScriptRoot '.runtime') -Directory -Filter 'jdk-*' | Select-Object -First 1).FullName
& "$env:CATALINA_HOME/bin/catalina.bat" stop
