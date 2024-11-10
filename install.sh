#! /bin/bash


# Installing the permissions/Goups/Users/Directory
curl -O https://raw.githubusercontent.com/Blavaloff/permission.sh/main/StadeRochelais.csv
curl -sL https://raw.githubusercontent.com/Blavaloff/permission.sh/main/permission.sh | bash

# Installing Visual Studio Code
# 1. Mettre à jour la liste des paquets
sudo apt update

# 2. Installer les dépendances nécessaires
sudo apt install -y software-properties-common apt-transport-https wget gpg

# 3. Importer la clé Microsoft GPG
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

# 4. Mettre à jour à nouveau la liste des paquets
sudo apt update

# 5. Installer VS Code
sudo apt install code

# 6. Nettoyer les fichiers temporaires
rm -f packages.microsoft.gpg