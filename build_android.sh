#!/usr/bin/env bash
# Bash port of build_android.ps1 for Linux/macOS.
set -euo pipefail

usage() {
    echo "Usage: $0 --flavor <medterms|teas> [--run]" >&2
    exit 1
}

flavor=""
run_mode=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --flavor)
            flavor="$2"
            shift 2
            ;;
        --run)
            run_mode=true
            shift
            ;;
        *)
            usage
            ;;
    esac
done

[[ "$flavor" == "medterms" || "$flavor" == "teas" ]] || usage

MAIN_ACTIVITY_MEDTERMS="android/app/src/main/kotlin/com/reichardreviews/medterms/MainActivity.kt"
MAIN_ACTIVITY_TEAS="android/app/src/main/kotlin/com/reichardreviews/teassci26/MainActivity.kt"

write_main_activity() {
    local path="$1" package="$2"
    mkdir -p "$(dirname "$path")"
    cat > "$path" <<EOF
package $package

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
EOF
}

apply_medterms() {
    echo "Switching to MedTerms..."

    sed -i \
        -e 's/applicationId = "[^"]*"/applicationId = "com.reichardreviews.medterms"/' \
        -e 's/namespace = "[^"]*"/namespace = "com.reichardreviews.medterms"/' \
        android/app/build.gradle.kts

    sed -i 's/android:label="[^"]*"/android:label="Med Terms"/' \
        android/app/src/main/AndroidManifest.xml

    [[ -f "$MAIN_ACTIVITY_MEDTERMS" ]] || write_main_activity "$MAIN_ACTIVITY_MEDTERMS" "com.reichardreviews.medterms"
    rm -f "$MAIN_ACTIVITY_TEAS"

    sed -i \
        -e 's|image_path: "[^"]*"|image_path: "assets/icons/app_launcher_icon.png"|' \
        -e 's/adaptive_icon_background: "[^"]*"/adaptive_icon_background: "#1A6B5A"/' \
        -e 's|adaptive_icon_foreground: "[^"]*"|adaptive_icon_foreground: "assets/icons/app_launcher_icon.png"|' \
        pubspec.yaml

    dart run flutter_launcher_icons
    find android/app/src/main/res -iname "desktop.ini" -delete 2>/dev/null || true

    if $run_mode; then
        echo "Launching MedTerms in debug mode..."
        flutter run --target lib/main.dart
    else
        flutter build appbundle --release --target lib/main.dart
        cp build/app/outputs/bundle/release/app-release.aab build/app/outputs/bundle/release/medterms-release.aab
    fi
}

apply_teas() {
    echo "Switching to TEAS..."

    sed -i \
        -e 's/applicationId = "[^"]*"/applicationId = "com.reichardreviews.teassci26"/' \
        -e 's/namespace = "[^"]*"/namespace = "com.reichardreviews.teassci26"/' \
        android/app/build.gradle.kts

    sed -i 's/android:label="[^"]*"/android:label="TEAS Science"/' \
        android/app/src/main/AndroidManifest.xml

    write_main_activity "$MAIN_ACTIVITY_TEAS" "com.reichardreviews.teassci26"
    rm -f "$MAIN_ACTIVITY_MEDTERMS"

    sed -i \
        -e 's|image_path: "[^"]*"|image_path: "assets/icons/app_launcher_icon_TEAS.png"|' \
        -e 's/adaptive_icon_background: "[^"]*"/adaptive_icon_background: "#3D6491"/' \
        -e 's|adaptive_icon_foreground: "[^"]*"|adaptive_icon_foreground: "assets/icons/app_launcher_icon_TEAS.png"|' \
        pubspec.yaml

    dart run flutter_launcher_icons
    find android/app/src/main/res -iname "desktop.ini" -delete 2>/dev/null || true

    if $run_mode; then
        echo "Launching TEAS in debug mode..."
        flutter run --target lib/main_teas.dart
    else
        flutter build appbundle --release --target lib/main_teas.dart
        cp build/app/outputs/bundle/release/app-release.aab build/app/outputs/bundle/release/teas-release.aab
    fi
}

revert_to_medterms() {
    echo "Reverting to MedTerms defaults..."

    sed -i \
        -e 's/applicationId = "[^"]*"/applicationId = "com.reichardreviews.medterms"/' \
        -e 's/namespace = "[^"]*"/namespace = "com.reichardreviews.medterms"/' \
        android/app/build.gradle.kts

    sed -i 's/android:label="[^"]*"/android:label="Med Terms"/' \
        android/app/src/main/AndroidManifest.xml

    [[ -f "$MAIN_ACTIVITY_MEDTERMS" ]] || write_main_activity "$MAIN_ACTIVITY_MEDTERMS" "com.reichardreviews.medterms"
    rm -f "$MAIN_ACTIVITY_TEAS"

    sed -i \
        -e 's|image_path: "[^"]*"|image_path: "assets/icons/app_launcher_icon.png"|' \
        -e 's/adaptive_icon_background: "[^"]*"/adaptive_icon_background: "#1A6B5A"/' \
        -e 's|adaptive_icon_foreground: "[^"]*"|adaptive_icon_foreground: "assets/icons/app_launcher_icon.png"|' \
        pubspec.yaml

    echo "Reverted to MedTerms defaults."
}

trap revert_to_medterms EXIT

if [[ "$flavor" == "medterms" ]]; then
    apply_medterms
else
    apply_teas
fi

if ! $run_mode; then
    echo "Done! AAB is in build/app/outputs/bundle/release/${flavor}-release.aab"
fi
