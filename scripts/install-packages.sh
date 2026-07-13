# Pacman:
sudo pacman -S --needed - < packages/pacman.txt

# AUR:
yay -S --needed $(cat packages/aur.txt)

# Flatpak:
flatpak install -y $(cat packages/flatpak.txt)