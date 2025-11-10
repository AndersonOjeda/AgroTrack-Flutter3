param(
    [string]$Device = "emulator-5554"
)

# Set a local Gradle user home to avoid conflicts under C:\Users
$env:GRADLE_USER_HOME = "$PSScriptRoot\..\.gradle_user_home"
if (-not (Test-Path $env:GRADLE_USER_HOME)) {
    New-Item -ItemType Directory -Path $env:GRADLE_USER_HOME | Out-Null
}
Write-Host "GRADLE_USER_HOME set to $env:GRADLE_USER_HOME"

# Clean and run on the selected device
pushd "$PSScriptRoot\.." | Out-Null
flutter clean
flutter pub get
flutter run -d $Device
popd | Out-Null