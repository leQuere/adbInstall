# 📱 Script d'Installation Automatique pour Meta Quest

Script automatisé pour installer des applications APK et leurs fichiers OBB sur votre Meta Quest via ADB.

Si vous aimez ou voulez aider, faites un don:
[![Sponsor](https://img.shields.io/badge/Sponsor-❤️-ea4aaa?style=for-the-badge&logo=github-sponsors)](https://github.com/sponsors/leQuere)


## 🎯 Fonctionnalités

- ✅ Détection automatique du fichier APK
- ✅ Détection automatique du nom du package
- ✅ Installation de l'APK sur le Quest
- ✅ Copie automatique des fichiers OBB
- ✅ Barre de progression en temps réel
- ✅ Vérification de la connexion ADB
- ✅ Messages colorés et clairs

## 📋 Prérequis

### Windows (PowerShell)
- Windows 10/11
- PowerShell 5.1 ou supérieur
- ADB installé et configuré dans le PATH
- Câble USB pour connecter le Quest

### Linux (Bash)
- Distribution Linux (Ubuntu, Debian, Fedora, etc.)
- Bash 4.0 ou supérieur
- ADB installé (`sudo apt install adb` sur Debian/Ubuntu)
- `bc` installé pour les calculs (`sudo apt install bc`)
- Câble USB pour connecter le Quest

## 🔧 Installation d'ADB

### Windows
1. Téléchargez les [Platform Tools Android](https://developer.android.com/studio/releases/platform-tools)
2. Extrayez l'archive dans un dossier (ex: `C:\platform-tools`)
3. Ajoutez le dossier au PATH système :
   - Panneau de configuration → Système → Paramètres système avancés
   - Variables d'environnement → Variable système `Path` → Modifier
   - Ajouter le chemin vers platform-tools

### Linux
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install adb bc

# Fedora
sudo dnf install android-tools bc

# Arch Linux
sudo pacman -S android-tools bc
```

## 📁 Structure des Fichiers

Organisez vos fichiers comme suit :

```
📂 Dossier_Installation/
├── 📄 install_quest.ps1          # Script PowerShell (Windows)
├── 📄 install_quest.sh           # Script Bash (Linux)
├── 📄 votre_application.apk      # Votre fichier APK
└── 📂 com.exemple.nomdupackage/  # Dossier OBB (même nom que le package)
    ├── 📄 main.123456.com.exemple.nomdupackage.obb
    └── 📄 patch.123456.com.exemple.nomdupackage.obb
```

**Important :** Le nom du dossier OBB doit correspondre exactement au nom du package de l'application.

## 🚀 Utilisation

### Windows (PowerShell)

1. **Activez le mode développeur sur votre Quest**
   - Paramètres → Système → À propos
   - Appuyez 7 fois sur "Numéro de version"

2. **Connectez votre Quest en USB**
   - Branchez le câble USB
   - Autorisez le débogage USB sur le Quest

3. **Vérifiez la connexion ADB**
   ```powershell
   adb devices
   ```

4. **Exécutez le script**
   ```powershell
   .\install_quest.ps1
   ```

   Ou faites un clic droit sur le fichier → "Exécuter avec PowerShell"

### Linux (Bash)

1. **Activez le mode développeur sur votre Quest** (même procédure que Windows)

2. **Connectez votre Quest en USB**

3. **Rendez le script exécutable**
   ```bash
   chmod +x install_quest.sh
   ```

4. **Vérifiez la connexion ADB**
   ```bash
   adb devices
   ```

5. **Exécutez le script**
   ```bash
   ./install_quest.sh
   ```

## 📊 Exemple d'Exécution

```
[INFO] Recherche du fichier APK...
[OK] APK detecte : MonJeu.apk
[INFO] Detection du package name...
[OK] PACKAGE_NAME detecte : com.example.mygame
[INFO] Verification de la connexion ADB...
[OK] Appareil Quest detecte
[INFO] Installation de l'application...
[OK] Application installee avec succes
[INFO] Copie des fichiers OBB vers le Quest...
[INFO] Taille totale a copier : 1234.56 MB (2 fichiers)
[========================================] 100% - 1234.56 / 1234.56 MB
[OK] Fichiers OBB copies vers le Quest
=========================================
[OK] Installation terminee avec succes !
=========================================
```

## ⚠️ Dépannage

### "Aucun appareil Quest detecte"
- Vérifiez que le câble USB est bien branché
- Autorisez le débogage USB sur le Quest
- Essayez `adb kill-server` puis `adb start-server`
- Vérifiez que les pilotes USB sont installés (Windows)

### "ADB n'est pas installe"
- Vérifiez l'installation d'ADB : `adb version`
- Assurez-vous qu'ADB est dans le PATH système

### "Aucun fichier APK trouve"
- Vérifiez que le fichier .apk est bien dans le même dossier que le script
- Le nom du fichier doit se terminer par `.apk`

### "Aucun repertoire trouve pour PACKAGE_NAME"
- Créez un dossier avec le nom exact du package
- Exemple : `com.beatgames.beatsaber`
- Placez vos fichiers OBB dans ce dossier

### Erreur de permissions (Linux)
```bash
# Ajoutez votre utilisateur au groupe plugdev
sudo usermod -aG plugdev $USER

# Créez une règle udev pour le Quest
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="2833", MODE="0666", GROUP="plugdev"' | sudo tee /etc/udev/rules.d/51-android.rules
sudo udevadm control --reload-rules
```

## 📝 Notes

- Le script remplace automatiquement l'application si elle est déjà installée (`-r` flag)
- Les fichiers OBB sont placés dans `/sdcard/Android/obb/[PACKAGE_NAME]/`
- La barre de progression affiche la taille totale et le nombre de fichiers copiés
- Le script s'arrête en cas d'erreur pour faciliter le débogage

## 🔐 Sécurité

- N'installez que des APK provenant de sources fiables
- Vérifiez toujours le contenu avant l'installation
- Le mode développeur peut présenter des risques de sécurité

## 📄 Licence

Ce script est fourni "tel quel" sans garantie. Utilisez-le à vos propres risques.

## 🤝 Contribution

N'hésitez pas à améliorer ce script et à partager vos modifications !

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez la section Dépannage ci-dessus
2. Assurez-vous que tous les prérequis sont installés
3. Vérifiez que votre Quest est en mode développeur
4. Testez la commande `adb devices` manuellement

---

**Bon jeu sur votre Meta Quest ! 🎮**
