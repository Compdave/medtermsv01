param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("medterms", "teas")]
    [string]$flavor,
    [switch]$run
)

# MainActivity.kt paths
$mainActivityMedterms = "android\app\src\main\kotlin\com\reichardreviews\medterms\MainActivity.kt"
$mainActivityTeas     = "android\app\src\main\kotlin\com\reichardreviews\teassci26\MainActivity.kt"

if ($flavor -eq "medterms") {
    Write-Host "Switching to MedTerms..." -ForegroundColor Green

    # build.gradle.kts
    (Get-Content android\app\build.gradle.kts) `
        -replace 'applicationId = "[^"]*"', 'applicationId = "com.reichardreviews.medterms"' `
        -replace 'namespace = "[^"]*"', 'namespace = "com.reichardreviews.medterms"' `
        | Set-Content android\app\build.gradle.kts

    # AndroidManifest.xml
    (Get-Content android\app\src\main\AndroidManifest.xml) `
        -replace 'android:label="[^"]*"', 'android:label="medtermsv01"' `
        | Set-Content android\app\src\main\AndroidManifest.xml

    # MainActivity.kt
    if (-not (Test-Path $mainActivityMedterms)) {
        New-Item -ItemType Directory -Force -Path (Split-Path $mainActivityMedterms) | Out-Null
        Set-Content $mainActivityMedterms "package com.reichardreviews.medterms`n`nimport io.flutter.embedding.android.FlutterActivity`n`nclass MainActivity : FlutterActivity()`n"
    }
    if (Test-Path $mainActivityTeas) { Remove-Item $mainActivityTeas }

    # pubspec.yaml
    (Get-Content pubspec.yaml) `
        -replace 'image_path: "[^"]*"', 'image_path: "assets/icons/app_launcher_icon.png"' `
        -replace 'adaptive_icon_background: "[^"]*"', 'adaptive_icon_background: "#1A6B5A"' `
        -replace 'adaptive_icon_foreground: "[^"]*"', 'adaptive_icon_foreground: "assets/icons/app_launcher_icon.png"' `
        | Set-Content pubspec.yaml

    dart run flutter_launcher_icons

    if ($run) {
        Write-Host "Launching MedTerms in debug mode..." -ForegroundColor Cyan
        flutter run --target lib/main.dart
    } else {
        flutter build appbundle --release --target lib/main.dart
    }

} elseif ($flavor -eq "teas") {
    Write-Host "Switching to TEAS..." -ForegroundColor Blue

    # build.gradle.kts
    (Get-Content android\app\build.gradle.kts) `
        -replace 'applicationId = "[^"]*"', 'applicationId = "com.reichardreviews.teassci26"' `
        -replace 'namespace = "[^"]*"', 'namespace = "com.reichardreviews.teassci26"' `
        | Set-Content android\app\build.gradle.kts

    # AndroidManifest.xml
    (Get-Content android\app\src\main\AndroidManifest.xml) `
        -replace 'android:label="[^"]*"', 'android:label="teassci26"' `
        | Set-Content android\app\src\main\AndroidManifest.xml

    # MainActivity.kt
    New-Item -ItemType Directory -Force -Path (Split-Path $mainActivityTeas) | Out-Null
    Set-Content $mainActivityTeas "package com.reichardreviews.teassci26`n`nimport io.flutter.embedding.android.FlutterActivity`n`nclass MainActivity : FlutterActivity()`n"
    if (Test-Path $mainActivityMedterms) { Remove-Item $mainActivityMedterms }

    # pubspec.yaml
    (Get-Content pubspec.yaml) `
        -replace 'image_path: "[^"]*"', 'image_path: "assets/icons/app_launcher_icon_TEAS.png"' `
        -replace 'adaptive_icon_background: "[^"]*"', 'adaptive_icon_background: "#3D6491"' `
        -replace 'adaptive_icon_foreground: "[^"]*"', 'adaptive_icon_foreground: "assets/icons/app_launcher_icon_TEAS.png"' `
        | Set-Content pubspec.yaml

    dart run flutter_launcher_icons

    if ($run) {
        Write-Host "Launching TEAS in debug mode..." -ForegroundColor Cyan
        flutter run --target lib/main_teas.dart
    } else {
        flutter build appbundle --release --target lib/main_teas.dart
    }
}

if (-not $run) {
    Write-Host "Done! AAB is in build/app/outputs/bundle/release/" -ForegroundColor Green
}

# Revert all files back to MedTerms defaults after build/run
Write-Host "Reverting to MedTerms defaults..." -ForegroundColor Yellow

(Get-Content android\app\build.gradle.kts) `
    -replace 'applicationId = "[^"]*"', 'applicationId = "com.reichardreviews.medterms"' `
    -replace 'namespace = "[^"]*"', 'namespace = "com.reichardreviews.medterms"' `
    | Set-Content android\app\build.gradle.kts

(Get-Content android\app\src\main\AndroidManifest.xml) `
    -replace 'android:label="[^"]*"', 'android:label="medtermsv01"' `
    | Set-Content android\app\src\main\AndroidManifest.xml

if (-not (Test-Path $mainActivityMedterms)) {
    New-Item -ItemType Directory -Force -Path (Split-Path $mainActivityMedterms) | Out-Null
    Set-Content $mainActivityMedterms "package com.reichardreviews.medterms`n`nimport io.flutter.embedding.android.FlutterActivity`n`nclass MainActivity : FlutterActivity()`n"
}
if (Test-Path $mainActivityTeas) { Remove-Item $mainActivityTeas }

(Get-Content pubspec.yaml) `
    -replace 'image_path: "[^"]*"', 'image_path: "assets/icons/app_launcher_icon.png"' `
    -replace 'adaptive_icon_background: "[^"]*"', 'adaptive_icon_background: "#1A6B5A"' `
    -replace 'adaptive_icon_foreground: "[^"]*"', 'adaptive_icon_foreground: "assets/icons/app_launcher_icon.png"' `
    | Set-Content pubspec.yaml

Write-Host "Reverted to MedTerms defaults." -ForegroundColor Yellow
