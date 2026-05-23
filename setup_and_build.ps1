# PharmaTwin AI - Android APK Setup & Build Helper Script
# This script guides you through checking prerequisites, configuring paths, and building the Android APK.

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   PharmaTwin AI - APK Build Assistant   " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check Java JDK
Write-Host "[1/6] Checking Java Installation..." -ForegroundColor Yellow
$javaInstalled = $false
try {
    $javaVer = java -version 2>&1
    if ($LASTEXITCODE -eq 0 -or $javaVer -match "version") {
        Write-Host "✔ Java is installed." -ForegroundColor Green
        $javaInstalled = $true
    }
} catch {
    Write-Host "✘ Java is not detected in your PATH." -ForegroundColor Red
}

if (-not $javaInstalled) {
    Write-Host "Please install Java JDK 17 (Temurin OpenJDK is recommended) before continuing." -ForegroundColor Yellow
    Write-Host "You can install it via: winget install Eclipse.Temurin.JDK.17" -ForegroundColor Cyan
    Exit
}

# 2. Check Android SDK
Write-Host ""
Write-Host "[2/6] Checking Android SDK..." -ForegroundColor Yellow
$androidSdkPath = "C:\Users\ganes_pof59a1\AppData\Local\Android\Sdk"
if (Test-Path $androidSdkPath) {
    Write-Host "✔ Android SDK found at: $androidSdkPath" -ForegroundColor Green
    $env:ANDROID_HOME = $androidSdkPath
} else {
    Write-Host "✘ Android SDK not found at default location ($androidSdkPath)." -ForegroundColor Red
    Write-Host "Please install Android Studio to configure the Android SDK." -ForegroundColor Yellow
    Exit
}

# 3. Check Flutter SDK
Write-Host ""
Write-Host "[3/6] Checking Flutter SDK..." -ForegroundColor Yellow
$flutterInstalled = $false
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source

if ($flutterPath) {
    Write-Host "✔ Flutter found in PATH: $flutterPath" -ForegroundColor Green
    $flutterInstalled = $true
} else {
    # Check other common paths
    $commonPaths = @(
        "C:\src\flutter\bin\flutter.bat",
        "C:\flutter\bin\flutter.bat",
        "C:\tools\flutter\bin\flutter.bat",
        "C:\Users\ganes_pof59a1\flutter\bin\flutter.bat"
    )
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            Write-Host "✔ Flutter found at: $path" -ForegroundColor Green
            # Add to temporary path for this session
            $flutterDir = Split-Path $path -Parent
            $env:PATH = "$flutterDir;" + $env:PATH
            $flutterInstalled = $true
            break
        }
    }
}

if (-not $flutterInstalled) {
    Write-Host "✘ Flutter SDK is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Would you like to install Flutter automatically using WinGet? (Y/N)" -ForegroundColor Yellow
    $ans = Read-Host
    if ($ans -eq 'Y' -or $ans -eq 'y') {
        Write-Host "Installing Flutter via WinGet..." -ForegroundColor Cyan
        winget install Flutter.Flutter
        Write-Host "Flutter has been installed! Please restart your terminal/VS Code and run this script again." -ForegroundColor Green
        Exit
    } else {
        Write-Host "Please install Flutter manually from https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
        Exit
    }
}

# 4. Check Firebase google-services.json
Write-Host ""
Write-Host "[4/6] Verifying Firebase Configuration..." -ForegroundColor Yellow
$servicesJson = "frontend\android\app\google-services.json"
if (Test-Path $servicesJson) {
    Write-Host "✔ google-services.json is present." -ForegroundColor Green
} else {
    Write-Host "✘ google-services.json is missing in frontend\android\app\" -ForegroundColor Red
    Write-Host "Please download it from your Firebase Console and place it there before building." -ForegroundColor Yellow
    Exit
}

# 5. Regenerate Android Platform Files
Write-Host ""
Write-Host "[5/6] Restoring Android platform files..." -ForegroundColor Yellow
cd frontend
flutter create --platforms=android .
if ($LASTEXITCODE -ne 0) {
    Write-Host "✘ Failed to recreate Android platform files." -ForegroundColor Red
    Exit
}
Write-Host "✔ Android platform files successfully restored!" -ForegroundColor Green

# 6. Build the APK
Write-Host ""
Write-Host "[6/6] Fetching dependencies and building APK..." -ForegroundColor Yellow
Write-Host "Running: flutter pub get" -ForegroundColor Cyan
flutter pub get

Write-Host "Building APK in Release Mode..." -ForegroundColor Cyan
flutter build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "✔ APK Built successfully!" -ForegroundColor Green
    Write-Host "Location: frontend\build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
} else {
    Write-Host "✘ APK Build failed. Please check the logs above for details." -ForegroundColor Red
}
