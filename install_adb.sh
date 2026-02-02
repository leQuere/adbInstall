#!/bin/bash
###############################################################################
# Script d'installation automatique pour Meta Quest (Bash)
# Detecte l'APK et le package name, installe l'app et copie les OBB
###############################################################################

# Arret en cas d'erreur
set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonction d'affichage des erreurs
error_exit() {
    echo -e "${RED}[ERREUR] $1${NC}" >&2
    exit 1
}

# Fonction d'affichage des informations
info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Fonction d'affichage des succes
success() {
    echo -e "${GREEN}[OK] $1${NC}"
}

# Fonction d'affichage des avertissements
warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

###############################################################################
# ETAPE 1 : DETECTION DE L'APK
###############################################################################
info "Recherche du fichier APK..."

APK_FILES=(*.apk)
if [ ! -f "${APK_FILES[0]}" ]; then
    error_exit "Aucun fichier APK trouve dans le repertoire courant."
fi

APK_FILE="${APK_FILES[0]}"
success "APK detecte : $APK_FILE"

###############################################################################
# ETAPE 2 : DETECTION DU PACKAGE NAME
###############################################################################
info "Detection du package name..."

# Recupere le nom du seul dossier present
DIRS=($(find . -maxdepth 1 -type d ! -name "." ! -name ".." ! -name ".*" -printf "%f\n"))

if [ ${#DIRS[@]} -eq 0 ]; then
    error_exit "Aucun repertoire trouve pour determiner PACKAGE_NAME."
fi

PACKAGE_NAME="${DIRS[0]}"
success "PACKAGE_NAME detecte : $PACKAGE_NAME"

###############################################################################
# ETAPE 3 : CONFIGURATION DES CHEMINS
###############################################################################
OBB_DIR="/sdcard/Android/obb/$PACKAGE_NAME"

info "Chemin OBB sur le Quest : $OBB_DIR"
info "Dossier OBB local : ./$PACKAGE_NAME"

###############################################################################
# ETAPE 4 : VERIFICATION DE LA CONNEXION ADB
###############################################################################
info "Verification de la connexion ADB..."

# Verifie si ADB est disponible
if ! command -v adb &> /dev/null; then
    error_exit "ADB n'est pas installe ou n'est pas dans le PATH."
fi

# Affiche les appareils connectes
adb devices

# Verifie qu'au moins un appareil est connecte
DEVICE_COUNT=$(adb devices | grep -c "device$" || true)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    error_exit "Aucun appareil Quest detecte. Verifiez la connexion USB et les autorisations."
fi

success "Appareil Quest detecte"

###############################################################################
# ETAPE 5 : INSTALLATION DE L'APK
###############################################################################
info "Installation de l'application..."
echo -e "  ${NC}-> Cela peut prendre quelques instants...${NC}"

if ! adb install -r "$APK_FILE" &> /dev/null; then
    error_exit "L'installation de l'APK a echoue"
fi

success "Application installee avec succes"

###############################################################################
# ETAPE 6 : COPIE DES FICHIERS OBB VERS LE QUEST
###############################################################################
info "Copie des fichiers OBB vers le Quest..."

# Verification de l'existence du dossier OBB local
if [ ! -d "$PACKAGE_NAME" ]; then
    warning "Aucun dossier OBB trouve localement : $PACKAGE_NAME"
    info "Si l'application necessite des fichiers OBB, placez-les dans un dossier nomme '$PACKAGE_NAME'"
else
    info "Dossier OBB trouve : $PACKAGE_NAME"
    
    # Creation du dossier OBB sur le Quest si necessaire
    info "Creation du repertoire OBB sur le Quest..."
    adb shell "mkdir -p '$OBB_DIR'" &> /dev/null
    
    # Calcul de la taille totale des fichiers OBB
    TOTAL_SIZE=$(find "$PACKAGE_NAME" -type f -exec stat -c%s {} + | awk '{sum+=$1} END {print sum}')
    TOTAL_SIZE_MB=$(echo "scale=2; $TOTAL_SIZE / 1048576" | bc)
    FILE_COUNT=$(find "$PACKAGE_NAME" -type f | wc -l)
    
    info "Taille totale a copier : ${TOTAL_SIZE_MB} MB ($FILE_COUNT fichiers)"
    info "Transfert des fichiers OBB..."
    echo ""
    
    # Copie avec affichage de la progression
    COPIED_SIZE=0
    CURRENT_FILE=0
    
    while IFS= read -r -d '' file; do
        ((CURRENT_FILE++))
        
        # Calcul du chemin relatif
        RELATIVE_PATH="${file#./$PACKAGE_NAME/}"
        TARGET_PATH="$OBB_DIR/$RELATIVE_PATH"
        
        # Calcul du pourcentage
        PERCENT=$(echo "scale=0; ($COPIED_SIZE * 100) / $TOTAL_SIZE" | bc)
        BAR_LENGTH=40
        FILLED=$(echo "scale=0; ($PERCENT * $BAR_LENGTH) / 100" | bc)
        
        # Construction de la barre de progression
        BAR="["
        for ((i=0; i<FILLED; i++)); do BAR="${BAR}="; done
        for ((i=FILLED; i<BAR_LENGTH; i++)); do BAR="${BAR} "; done
        BAR="${BAR}]"
        
        # Affichage de la jauge
        CURRENT_MB=$(echo "scale=2; $COPIED_SIZE / 1048576" | bc)
        echo -ne "\r${CYAN}${BAR} ${PERCENT}% - ${CURRENT_MB} / ${TOTAL_SIZE_MB} MB - Fichier ${CURRENT_FILE}/${FILE_COUNT}${NC}"
        
        # Copie du fichier
        adb push "$file" "$TARGET_PATH" &> /dev/null || true
        
        FILE_SIZE=$(stat -c%s "$file")
        COPIED_SIZE=$((COPIED_SIZE + FILE_SIZE))
    done < <(find "$PACKAGE_NAME" -type f -print0)
    
    # Jauge finale
    BAR="["
    for ((i=0; i<40; i++)); do BAR="${BAR}="; done
    BAR="${BAR}]"
    echo -e "\r${GREEN}${BAR} 100% - ${TOTAL_SIZE_MB} / ${TOTAL_SIZE_MB} MB - Tous les fichiers copies!${NC}"
    echo ""
    
    success "Fichiers OBB copies vers le Quest"
    
    # Affiche la liste des fichiers copies
    info "Fichiers presents sur le Quest :"
    adb shell "ls -lh '$OBB_DIR/'"
fi

###############################################################################
# RESUME FINAL
###############################################################################
echo ""
echo -e "${CYAN}=========================================${NC}"
success "Installation terminee avec succes !"
echo -e "${CYAN}=========================================${NC}"
echo ""
echo "Details :"
echo "  - APK installe     : $APK_FILE"
echo "  - Package name     : $PACKAGE_NAME"
echo "  - OBB sur le Quest : $OBB_DIR"
echo ""
info "Vous pouvez maintenant lancer l'application sur votre Quest"
echo ""
