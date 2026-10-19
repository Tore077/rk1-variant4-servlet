param([switch]$SetupOnly)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-Location $PSScriptRoot
$runtime = Join-Path $PSScriptRoot '.runtime'
New-Item -ItemType Directory -Force $runtime | Out-Null
$jdk = Get-ChildItem $runtime -Directory -Filter 'jdk-*' | Select-Object -First 1
if (-not $jdk) {
 Write-Host 'Downloading portable JDK 17...'
 & curl.exe -fL --retry 3 --connect-timeout 20 --max-time 600 -o "$runtime/jdk.zip" 'https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse'
 if ($LASTEXITCODE -ne 0) { throw 'JDK download failed' }
 Expand-Archive -LiteralPath "$runtime/jdk.zip" -DestinationPath $runtime -Force
 $jdk = Get-ChildItem $runtime -Directory -Filter 'jdk-*' | Select-Object -First 1
}
$tomcat = Join-Path $runtime 'apache-tomcat-9.0.121'
if (-not (Test-Path "$tomcat/lib/servlet-api.jar")) {
 Write-Host 'Downloading Apache Tomcat 9...'
 & curl.exe -fL --retry 3 --connect-timeout 20 --max-time 600 -o "$runtime/tomcat.zip" 'https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.121/bin/apache-tomcat-9.0.121.zip'
 if ($LASTEXITCODE -ne 0) { throw 'Tomcat download failed' }
 Expand-Archive -LiteralPath "$runtime/tomcat.zip" -DestinationPath $runtime -Force
}
$env:JAVA_HOME = $jdk.FullName
$env:CATALINA_HOME = $tomcat
$env:CATALINA_BASE = $tomcat
$env:CATALINA_TMPDIR = $env:TEMP
$env:CATALINA_OPTS = "-Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8"
# NIO2 avoids Windows AF_UNIX selector failures.
$serverConfig = Join-Path $tomcat 'conf/server.xml'
$config = [IO.File]::ReadAllText($serverConfig)
$config = $config.Replace('protocol="HTTP/1.1"', 'protocol="org.apache.coyote.http11.Http11Nio2Protocol"')
[IO.File]::WriteAllText($serverConfig, $config)
$classes = Join-Path $PSScriptRoot 'build/classes'
New-Item -ItemType Directory -Force $classes | Out-Null
$sources = @(Get-ChildItem 'src/main/java' -Recurse -Filter '*.java' | ForEach-Object { $_.FullName })
& "$env:JAVA_HOME/bin/javac.exe" -encoding UTF-8 --release 17 -cp "$tomcat/lib/servlet-api.jar" -d $classes @sources
if ($LASTEXITCODE -ne 0) { throw 'Compilation failed' }
$deploy = Join-Path $tomcat 'webapps/rk4'
New-Item -ItemType Directory -Force $deploy | Out-Null
Copy-Item 'src/main/webapp/*' $deploy -Recurse -Force
New-Item -ItemType Directory -Force "$deploy/WEB-INF/classes" | Out-Null
Copy-Item "$classes/*" "$deploy/WEB-INF/classes" -Recurse -Force
Write-Host 'Ready: http://localhost:8080/rk4/'
if (-not $SetupOnly) { & "$tomcat/bin/catalina.bat" run }

