#!/bin/bash
# I dont know bash that will I not sure if bash if you can use variable out the block thats whey I call the zenity to select the distro
# also this uninstalling file is not tested figure it out if any error happens
LOGFILE="$HOME/aenux-uninstall.log"
exec > >(tee -a "$LOGFILE") 2>&1

# Ensure zenity is installed
if ! command -v zenity &>/dev/null; then
  echo "[*] Installing zenity..."
   
  DISTRO=$(zenity --list --title="Select Your Distribution" \
    --column="ID" --column="Distribution" \
    1 "distro base on Ubuntu" \
    2 "archlinux " \
    --height=400 --width=400)

  [ -z "$DISTRO" ] && zenity --error --text="No distribution selected. Exiting." && exit 1

  case $DISTRO in
    1) origin="ubuntu" ;;
    2) origin="archlinux" ;;
    *) handle_error ;;
  esac

  if [[ "$origin" == "archlinux" ]]; then 
    sudo pacman -Syu --noconfirm
    sudo pacman -S zenity wget dpkg --noconfirm
  else
    sudo apt update && sudo apt install zenity -y
  fi

fi
# Error handler
handle_error() {
  zenity --error --title="Uninstallation Failed" \
    --text="An error occurred during uninstallation.\nCheck log at: $LOGFILE"
  exit 1
}
trap handle_error ERR

# Step 1: Remove AeNux-related files
echo "[*] Removing AeNux files..."
sudo rm -rf $HOME/cutefishaep
sudo rm -f "$HOME/Desktop/AeNux.desktop"
sudo rm -f "$HOME/.local/share/applications/AeNux.desktop"
sudo rm -f "$HOME/.local/share/icons/aenux.png"

# Step 2: Ask if user wants to remove Wine & Winetricks completely
zenity --question --title="Remove Wine & Winetricks?" \
  --text="Do you want to completely remove Wine, Winetricks, and related configurations?\n(This may affect other Wine applications)" \
  --width=400

if [[ $? -eq 0 ]]; then
  echo "[*] Removing Wine and Winetricks..."

  # Purge Wine and Winetricks
  DISTRO=$(zenity --list --title="Select Your Distribution" \
    --column="ID" --column="Distribution" \
    1 "distro base on Ubuntu" \
    2 "archlinux " \
    --height=400 --width=400)

  [ -z "$DISTRO" ] && zenity --error --text="No distribution selected. Exiting." && exit 1

  case $DISTRO in
    1) origin="ubuntu" ;;
    2) origin="archlinux" ;;
    *) handle_error ;;
  esac

  if [[ "$origin" == "ubuntu" ]]; then
     sudo apt-get purge --auto-remove winehq-* -y
  elif [[ "$origin" == "archlinux" ]]; then
     sudo pacman -Rns wine-gecko wine-mono wine winetricks --noconfirm
  fi



  # Remove wine config and keys
  echo "[*] Cleaning Wine-related configs..."
  sudo rm -rf "$HOME/.wine"
  sudo rm -rf /etc/apt/keyrings
  sudo rm -f /etc/apt/sources.list.d/winehq-*.sources

  # Optional: Remove i386 if nothing depends on it
  if ! dpkg --get-selections | grep -q ":i386"; then
    echo "[*] No i386 packages found. Removing i386 architecture..."
    sudo dpkg --remove-architecture i386
  else
    echo "[!] i386 packages still present. Skipping architecture removal."
  fi
  if [[ "$origin" == "ubuntu" ]]; then
    sudo apt-get autoremove -y
    sudo apt-get clean
  fi
fi

# Done
echo "Done uninstalling!"
exit 0
