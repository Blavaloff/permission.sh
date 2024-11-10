#!/bin/bash

# Vérification du fichier CSV
if [ ! -f "StadeRochelais.csv" ]; then
    echo "Erreur: Le fichier stadeRochelais.csv n'existe pas"
    exit 1
fi

# Nettoyage des anciens groupes (optionnel)
echo "Nettoyage des anciens groupes..."
for group in DIRECTION STAFF JOUEUR ORGANISATION ENTRAINEUR MEDICAL PREPARATEUR_PHYSIQUE VIDEO AVANT PREMIERE_LIGNE DEUXIEME_LIGNE TROISIEME_LIGNE PILLIER TALLON TROIS_QUART DEMI CENTRE AILLIER ARRIERE MELEE OUVERTURE; do
    sudo groupdel $group 2>/dev/null || true
done

# Création des groupes principaux
echo "Création des groupes principaux..."
for group in DIRECTION STAFF JOUEUR; do
    sudo groupadd $group 2>/dev/null || true
done

# Création des sous-groupes STAFF
echo "Création des sous-groupes STAFF..."
for group in ENTRAINEUR MEDICAL PREPARATEUR_PHYSIQUE VIDEO ORGANISATION; do
    sudo groupadd $group 2>/dev/null || true
done

# Création des sous-groupes JOUEUR
echo "Création des sous-groupes pour les joueurs..."
for group in AVANT PREMIERE_LIGNE DEUXIEME_LIGNE TROISIEME_LIGNE PILLIER TALLON TROIS_QUART DEMI CENTRE AILLIER ARRIERE MELEE OUVERTURE; do
    sudo groupadd $group 2>/dev/null || true
done

# Création et configuration des répertoires partagés
echo "Configuration des répertoires partagés..."
sudo rm -rf /PARTAGE 2>/dev/null || true
sudo mkdir -p /PARTAGE
sudo chmod 755 /PARTAGE

for dir in DIRECTION STAFF JOUEUR ; do
    sudo mkdir -p "/PARTAGE/$dir"
    sudo chown root:$dir "/PARTAGE/$dir"
    sudo chmod 770 "/PARTAGE/$dir"
done

for dir in ENTRAINEUR MEDICAL PREPARATEUR_PHYSIQUE VIDEO ORGANISATION; do
    sudo mkdir -p "/PARTAGE/STAFF/$dir"
    sudo chown root:$dir "/PARTAGE/STAFF/$dir"
    sudo chmod 770 "/PARTAGE/STAFF/$dir"
done

for dir in AVANT TROIS_QUART; do
    sudo mkdir -p "/PARTAGE/JOUEUR/$dir"
    sudo chown root:$dir "/PARTAGE/JOUEUR/$dir"
    sudo chmod 770 "/PARTAGE/JOUEUR/$dir"
done

for dir in PREMIERE_LIGNE DEUXIEME_LIGNE TROISIEME_LIGNE; do
    sudo mkdir -p "/PARTAGE/JOUEUR/AVANT/$dir"
    sudo chown root:$dir "/PARTAGE/JOUEUR/AVANT/$dir"
    sudo chmod 770 "/PARTAGE/JOUEUR/AVANT/$dir"
done

for dir in PILLIER TALLON; do
    sudo mkdir -p "/PARTAGE/JOUEUR/AVANT/PREMIERE_LIGNE/$dir"
    sudo chown root:$dir "/PARTAGE/JOUEUR/AVANT/PREMIERE_LIGNE/$dir"
    sudo chmod 770 "/PARTAGE/JOUEUR/AVANT/PREMIERE_LIGNE/$dir"
done

for dir in DEMI CENTRE AILLIER ARRIERE; do
    sudo mkdir -p "/PARTAGE/JOUEUR/TROIS_QUART/$dir"
    sudo chown root:$dir "/PARTAGE/JOUEUR/TROIS_QUART/$dir"
    sudo chmod 770 "/PARTAGE/JOUEUR/TROIS_QUART/$dir"
done

for dir in MELEE OUVERTURE; do
    sudo mkdir -p "/PARTAGE/JOUEUR/TROIS_QUART/DEMI/$dir"
    sudo chown root:$dir "/PARTAGE/JOUEUR/TROIS_QUART/DEMI/$dir"
    sudo chmod 770 "/PARTAGE/JOUEUR/TROIS_QUART/DEMI/$dir"
done

# Configuration du skel
echo "Configuration du répertoire skel..."
sudo rm -rf /etc/skel/{Strategies,Entrainements,Analyses} 2>/dev/null || true
sudo mkdir -p /etc/skel/{Strategies,Entrainements,Analyses}
sudo chmod 700 /etc/skel/{Strategies,Entrainements,Analyses}
sudo ln -s /PARTAGE /etc/skel/PARTAGE

# Fonctions utilitaires
create_login() {
    local prenom=$1
    local nom=$2
    local base_login=$(echo "${prenom:0:1}${nom}" | tr '[:upper:]' '[:lower:]' | tr -d ' ' | cut -c1-8)
    local login=$base_login
    local counter=1
    
    while id "$login" &>/dev/null; do
        login="${base_login}$(printf %02d $counter)"
        ((counter++))
    done
    
    echo $login
}

convert_date() {
    local date=$1
    date_clean=$(echo $date | tr -d ' ')
    IFS='/' read -r jour mois annee <<< "$date_clean"
    printf "%02d%02d%04d" "$jour" "$mois" "$annee"
}

# Création des utilisateurs
echo "Création des utilisateurs..."
while IFS=, read -r prenom nom nationalite poste date_naissance taille poids jiff contrat;
do
    if [ "$prenom" != "Prénom" ]; then
        login=$(create_login "$prenom" "$nom")
        password=$(convert_date "$date_naissance")
        
        # Suppression de l'utilisateur s'il existe déjà
        sudo userdel -r "$login" 2>/dev/null || true
        
        # Création du nouvel utilisateur
        sudo useradd -m -k /etc/skel -s /bin/bash "$login"
        echo "$login:$password" | sudo chpasswd
        sudo chage -d 0 "$login"
        
        # Attribution des groupes
        case $contrat in
            "ENTRAINEUR") sudo usermod -a -G STAFF,ENTRAINEUR "$login" ;;
            "MEDICAL") sudo usermod -a -G STAFF,MEDICAL "$login" ;;
            "VIDEO") sudo usermod -a -G STAFF,VIDEO "$login" ;;
            "ORGANISATION" ) sudo usermod -a -G STAFF,ORGANISATION "$login" ;;
            "PREPARATEUR PHYSIQUE" ) sudo usermod -a -G STAFF,"PREPARATEUR PHYSIQUE" "$login" ;;
            "PRO"|"ESPOIR") 
                sudo usermod -a -G JOUEUR "$login"
                case $poste in
                    "Pilier") sudo usermod -a -G AVANT,PREMIERE_LIGNE,PILLIER "$login" ;;
                    "Talonneur") sudo usermod -a -G AVANT,PREMIERE_LIGNE,TALLON "$login" ;;
                    "3ème ligne") sudo usermod -a -G AVANT,TROISIEME_LIGNE "$login" ;;
                    "Mêlée") sudo usermod -a -G TROIS_QUART,DEMI,MELEE "$login" ;;
                    "Ailier") sudo usermod -a -G TROIS_QUART,AILLIER "$login" ;;
                    "Arrière") sudo usermod -a -G TROIS_QUART,ARRIERE "$login" ;;
                esac
                ;;
        esac
        
        echo "Utilisateur $login créé avec succès"
    fi
done < StadeRochelais.csv

echo "Configuration terminée avec succès!"
