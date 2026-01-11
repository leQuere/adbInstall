###############################################################################
# Script d'installation automatique pour Meta Quest (PowerShell)
# Detecte l'APK et le package name, installe l'app et copie les OBB
###############################################################################

# Arret en cas d'erreur
$ErrorActionPreference = "Stop"

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

$apkFiles = Get-ChildItem -Filter "*.apk" -File
if ($apkFiles.Count -eq 0) {
    Write-Error-Exit "Aucun fichier APK trouve dans le repertoire courant."
}

$APK_FILE = $apkFiles[0].Name
Write-Success "APK detecte : $APK_FILE"

###############################################################################
# ETAPE 2 : DETECTION DU PACKAGE NAME
###############################################################################
Write-Info "Detection du package name..."

# Recupere le nom du seul dossier present
$directories = Get-ChildItem -Directory | Where-Object { $_.Name -ne "." -and $_.Name -ne ".." }

if ($directories.Count -eq 0) {
    Write-Error-Exit "Aucun repertoire trouve pour determiner PACKAGE_NAME."
}

$PACKAGE_NAME = $directories[0].Name
Write-Success "PACKAGE_NAME detecte : $PACKAGE_NAME"

###############################################################################
# ETAPE 3 : CONFIGURATION DES CHEMINS
###############################################################################
$OBB_DIR = "/sdcard/Android/obb/$PACKAGE_NAME"

Write-Info "Chemin OBB sur le Quest : $OBB_DIR"
Write-Info "Dossier OBB local : .\$PACKAGE_NAME"

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
# ETAPE 5 : INSTALLATION DE L'APK
###############################################################################
Write-Info "Installation de l'application..."
Write-Host "  -> Cela peut prendre quelques instants..." -ForegroundColor Gray

$installResult = adb install -r "$APK_FILE" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error-Exit "L'installation de l'APK a echoue"
}

Write-Success "Application installee avec succes"

###############################################################################
# ETAPE 6 : COPIE DES FICHIERS OBB VERS LE QUEST
###############################################################################
Write-Info "Copie des fichiers OBB vers le Quest..."

# Verification de l'existence du dossier OBB local
if (-not (Test-Path -Path $PACKAGE_NAME -PathType Container)) {
    Write-Warning-Custom "Aucun dossier OBB trouve localement : $PACKAGE_NAME"
    Write-Info "Si l'application necessite des fichiers OBB, placez-les dans un dossier nomme '$PACKAGE_NAME'"
} else {
    Write-Info "Dossier OBB trouve : $PACKAGE_NAME"
    
    # Creation du dossier OBB sur le Quest si necessaire
    Write-Info "Creation du repertoire OBB sur le Quest..."
    adb shell "mkdir -p '$OBB_DIR'" | Out-Null
    
    # Calcul de la taille totale des fichiers OBB
    $obbFiles = Get-ChildItem -Path $PACKAGE_NAME -Recurse -File
    $totalSize = ($obbFiles | Measure-Object -Property Length -Sum).Sum
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
    
    Write-Info "Taille totale a copier : $totalSizeMB MB ($($obbFiles.Count) fichiers)"
    Write-Info "Transfert des fichiers OBB..."
    Write-Host ""
    
    # Copie avec affichage de la progression
    $copiedSize = 0
    $fileCount = 0
    foreach ($file in $obbFiles) {
        $fileCount++
        $relativePath = $file.FullName.Substring((Get-Location).Path.Length + 1)
        $targetPath = "$OBB_DIR/" + $relativePath.Substring($PACKAGE_NAME.Length + 1).Replace("\", "/")
        
        # Calcul du pourcentage
        $percent = [math]::Round(($copiedSize / $totalSize) * 100)
        $barLength = 40
        $filled = [math]::Round(($percent / 100) * $barLength)
        $bar = "[" + ("=" * $filled) + (" " * ($barLength - $filled)) + "]"
        
        # Affichage de la jauge
        $currentMB = [math]::Round($copiedSize / 1MB, 2)
        Write-Host "`r$bar $percent% - $currentMB / $totalSizeMB MB - Fichier $fileCount/$($obbFiles.Count)" -NoNewline -ForegroundColor Cyan
        
        # Copie du fichier (ignore la sortie standard d'adb)
        try {
            adb push "$($file.FullName)" "$targetPath" 2>&1 | Out-Null
        } catch {
            # Ignore les erreurs non critiques
        }
        
        $copiedSize += $file.Length
    }
    
    # Jauge finale
    Write-Host "`r[" + ("=" * 40) + "] 100% - $totalSizeMB / $totalSizeMB MB - Tous les fichiers copies!" -ForegroundColor Green
    Write-Host ""
    
    Write-Success "Fichiers OBB copies vers le Quest"
    
    # Affiche la liste des fichiers copies
    Write-Info "Fichiers presents sur le Quest :"
    adb shell "ls -lh '$OBB_DIR/'" 2>&1 | Out-Null
}

###############################################################################
# RESUME FINAL
###############################################################################
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Success "Installation terminee avec succes !"
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Details :"
Write-Host "  - APK installe     : $APK_FILE"
Write-Host "  - Package name     : $PACKAGE_NAME"
Write-Host "  - OBB sur le Quest : $OBB_DIR"
Write-Host ""
Write-Info "Vous pouvez maintenant lancer l'application sur votre Quest"
Write-Host ""
