###############################################################################
# Script de desinstallation automatique pour Meta Quest (PowerShell)
# Detecte l'APK et desinstalle l'app avec suppression des OBB
###############################################################################

# Arret en cas d'erreur
$ErrorActionPreference = "Continue"

# Fonction d'affichage des erreurs
function Write-Error-Exit {
    param([string]$Message)
    Write-Host "[ERREUR] $Message" -ForegroundColor Red
    exit 1
}

# Fonction d'affichage des informations
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

# Fonction d'affichage des succes
function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

# Fonction d'affichage des avertissements
function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

###############################################################################
# ETAPE 1 : DETECTION DE L'APK
###############################################################################
Write-Info "Recherche du fichier APK..."

$apkFiles = Get-ChildItem -Filter "*.apk" -File -ErrorAction SilentlyContinue
if ($apkFiles.Count -eq 0) {
    Write-Error-Exit "Aucun fichier APK trouve dans le repertoire courant."
}

$APK_FILE = $apkFiles[0].Name
Write-Success "APK detecte : $APK_FILE"

###############################################################################
# ETAPE 2 : CREATION DU PACKAGE_NAME A PARTIR DU NOM DU FICHIER APK
###############################################################################
# Exemple : monjeu.apk -> monjeu
$PACKAGE_NAME = [System.IO.Path]::GetFileNameWithoutExtension($APK_FILE)
Write-Info "PACKAGE_NAME derive du fichier APK : $PACKAGE_NAME"

###############################################################################
# ETAPE 3 : CONFIGURATION
###############################################################################
$OBB_DIR = "/sdcard/Android/obb/$PACKAGE_NAME"

###############################################################################
# ETAPE 4 : VERIFICATION DE LA CONNEXION ADB
###############################################################################
Write-Info "Verification de la connexion ADB..."

# Verifie si ADB est disponible
try {
    $null = Get-Command adb -ErrorAction Stop
} catch {
    Write-Error-Exit "ADB n'est pas installe ou n'est pas dans le PATH."
}

# Affiche les appareils connectes
adb devices

# Verifie qu'au moins un appareil est connecte
$devicesOutput = adb devices | Select-String "device$"
if ($devicesOutput.Count -eq 0) {
    Write-Error-Exit "Aucun appareil Quest detecte. Verifiez la connexion USB et les autorisations."
}

Write-Success "Appareil Quest detecte"

###############################################################################
# ETAPE 5 : DESINSTALLATION DE L'APK
###############################################################################
Write-Info "Desinstallation de l'application..."

$uninstallResult = adb uninstall "$PACKAGE_NAME" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Warning-Custom "ATTENTION : la desinstallation peut avoir echoue."
    Write-Warning-Custom "L'application n'etait peut-etre pas installee."
} else {
    Write-Success "Application desinstallee"
}

###############################################################################
# ETAPE 6 : SUPPRESSION DU DOSSIER OBB SUR LE QUEST
###############################################################################
Write-Info "Suppression du dossier OBB sur le Quest..."

adb shell "rm -rf '$OBB_DIR'" 2>&1 | Out-Null
Write-Success "Dossier OBB supprime"

###############################################################################
# RESUME FINAL
###############################################################################
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Success "Desinstallation terminee avec succes !"
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Details :"
Write-Host "  - Application desinstallee : $PACKAGE_NAME"
Write-Host "  - Dossier OBB supprime     : $OBB_DIR"
Write-Host ""
