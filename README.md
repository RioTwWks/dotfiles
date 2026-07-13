# EndeavourOS Workstation Bootstrap

> **Bootstrap воспроизводимой рабочей станции DevOps** на EndeavourOS + Btrfs.
> Не классические dotfiles: одна команда после чистой установки → практически идентичная машина.

## Requirements

- Чистая установка **EndeavourOS** (KDE Plasma)
- **Btrfs** (`@`, `@home`, …)
- Сеть + `yay`
- Timeshift не используем — только **Snapper**

## Installation

```bash
git clone https://github.com/RioTwWks/dotfiles ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

Logout/reboot (docker group, zsh). Затем:

```bash
./scripts/doctor.sh
```

## Updating

```bash
./scripts/update.sh
```

Обновляет (если утилита есть): `pacman`, `yay -Sua`, `flatpak`, `rustup`, `mise`, `npm -g`, `flutter`.  
`snap-pac` делает pre/post снимки root при операциях pacman.

## Recovery

| Компонент | Роль |
|-----------|------|
| Snapper | снимки `@` / `@home` |
| snap-pac | pre/post при обновлениях |
| grub-btrfs | boot в снимок из GRUB |
| btrfs-assistant | GUI отката |
| btrfs scrub | проверка целостности |

```bash
./install/snapper.sh
./scripts/doctor.sh
```

Откат: GRUB → **snapshots** или Btrfs Assistant.

## Packages

| Файл | Назначение |
|------|------------|
| `pacman.txt` | официальные пакеты |
| `aur.txt` | AUR |
| `flatpak.txt` | Flatpak |
| `fonts.txt` | шрифты |
| `services.txt` | systemd units (`enable --now`) |
| `cursor-extensions.txt` | расширения Cursor |

## Customization

```
configs/
  cursor/     settings.json, keybindings.json
  docker/     daemon.json
  fastfetch/
  ghostty/
  git/
  kde/        (placeholder)
  starship/
  zsh/
```

Правки — в репозитории; `install/shell.sh` и `install/cursor.sh` ставят симлинки.

## Screenshots

Файлы в `assets/screenshots/`:

```markdown
![desktop](assets/screenshots/desktop.png)
```

## Structure

```
bootstrap.sh              # цветной run(), continue-on-error
packages/                 # pacman, aur, flatpak, fonts, services, cursor-ext
install/                  # packages, services, shell, fonts, ghostty,
                          # docker, cursor, devtools, kde, snapper
scripts/
  doctor.sh
  update.sh
configs/
assets/
```

## Roadmap

1. ✅ Snapper + rollback  
2. ✅ Модульный bootstrap + doctor + services/fonts  
3. ⏳ Экспорт Plasma → `configs/kde/`  
4. ⏳ Homelab restore (GitLab, Proxy Manager, …)
