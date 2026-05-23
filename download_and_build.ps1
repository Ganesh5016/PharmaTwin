# PharmaTwin AI - Full Automatic SDK Setup & APK Build Script
# This script will download Flutter SDK, set up environment paths, restore platform files, and build the APK.

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   Starting Automated Flutter Setup & APK Build   " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

$workspaceRoot = $PSScriptRoot
$zipPath = "$workspaceRoot\flutter_temp.zip"
$sdkPath = "$workspaceRoot\flutter_sdk"
$apkDest = "$workspaceRoot\pharmatwin_release.apk"

# Step 1: Check Java JDK
Write-Host "[1/7] Verifying Java Installation..." -ForegroundColor Yellow
$javaCmd = Get-Command java -ErrorAction SilentlyContinue
if (-not $javaCmd) {
    Write-Host "[ERROR] Java is not detected in your PATH." -ForegroundColor Red
    Exit 1
}
Write-Host "[OK] Java detected in PATH." -ForegroundColor Green

# Step 2: Download Flutter SDK
Write-Host ""
Write-Host "[2/7] Downloading Flutter SDK 3.44.0 (approx. 1GB)..." -ForegroundColor Yellow
Write-Host "This might take a couple of minutes depending on your internet connection." -ForegroundColor Cyan
if (Test-Path $zipPath) {
    Write-Host "[OK] Found existing download zip. Skipping download." -ForegroundColor Green
} else {
    try {
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
            Write-Host "Attempting download using curl.exe..." -ForegroundColor Cyan
            curl.exe -L -o $zipPath "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.44.0-stable.zip"
            if ($LASTEXITCODE -ne 0) { throw "curl.exe exited with code $LASTEXITCODE" }
        } else {
            throw "curl.exe not found in PATH"
        }
    } catch {
        Write-Host "curl.exe failed or not found. Error: $_" -ForegroundColor Yellow
        try {
            Write-Host "Attempting download using BitsTransfer..." -ForegroundColor Cyan
            Import-Module BitsTransfer
            Start-BitsTransfer -Source "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.44.0-stable.zip" -Destination $zipPath
        } catch {
            Write-Host "BitsTransfer failed or is disabled. Falling back to Invoke-WebRequest..." -ForegroundColor Yellow
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.44.0-stable.zip" -OutFile $zipPath
        }
    }
    Write-Host "[OK] Download complete!" -ForegroundColor Green
}

# Step 3: Extract Flutter SDK
Write-Host ""
Write-Host "[3/7] Extracting Flutter SDK (this may take 1-2 minutes)..." -ForegroundColor Yellow
if (Test-Path "$sdkPath\flutter\bin\flutter.bat") {
    Write-Host "[OK] Flutter SDK already extracted." -ForegroundColor Green
} else {
    if (Test-Path $sdkPath) { Remove-Item -Path $sdkPath -Recurse -Force -ErrorAction SilentlyContinue }
    Expand-Archive -Path $zipPath -DestinationPath $sdkPath -Force
    Write-Host "[OK] Extraction complete!" -ForegroundColor Green
}

# Step 4: Configure Environment Variables
Write-Host ""
Write-Host "[4/7] Configuring build environment..." -ForegroundColor Yellow
$env:PATH = "$sdkPath\flutter\bin;" + $env:PATH
$env:ANDROID_HOME = "C:\Users\ganes_pof59a1\AppData\Local\Android\Sdk"

# Disable telemetry and check licenses
flutter config --no-analytics | Out-Null
Write-Host "[OK] Paths configured. Flutter version:" -ForegroundColor Green
flutter --version

# Step 5: Regenerate Android platform build scripts
Write-Host ""
Write-Host "[5/7] Restoring platform Gradle files..." -ForegroundColor Yellow
cd "$workspaceRoot\frontend"
flutter create --platforms=android .
Write-Host "[OK] Android project files successfully restored!" -ForegroundColor Green

# Step 6: Fetch dependencies and compile APK
Write-Host ""
Write-Host "[6/7] Resolving Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "Compiling Release Android APK..." -ForegroundColor Cyan
flutter build apk --release

# Step 7: Clean up and deliver
Write-Host ""
Write-Host "[7/7] Finalizing build and cleanup..." -ForegroundColor Yellow
$compiledApk = "$workspaceRoot\frontend\build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $compiledApk) {
    Copy-Item -Path $compiledApk -Destination $apkDest -Force
    # Clean zip file to save disk space
    if (Test-Path $zipPath) { Remove-Item -Path $zipPath -Force }
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host "[SUCCESS] APK BUILT SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "Your APK is ready at: $apkDest" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
} else {
    Write-Host "[ERROR] APK file was not created. Please review compilation logs." -ForegroundColor Red
    Exit 1
}
