# EndeavourOS Workstation Bootstrap

Воспроизводимая рабочая станция DevOps/DevSecOps на **EndeavourOS + Btrfs**:
пакеты, configs, Snapper-recovery, Docker, Cursor, Ghostty — одной командой после чистой установки.

> Это уже не классические «dotfiles», а **Workstation Bootstrap**.
> Локальный путь пока `~/dotfiles`; при желании репозиторий можно переименовать в `workstation` / `endeavouros-bootstrap`.

## Requirements

- Чистая установка **EndeavourOS** (рекомендуется KDE Plasma)
- Файловая система **Btrfs** (`@`, `@home`, …)
- Сеть + `yay` (идёт с EndeavourOS)
- Timeshift **не** нужен — только Snapper

## Installation

```bash
git clone https://github.com/RioTwWks/dotfiles ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

Затем logout/reboot (docker group, zsh login shell).

Проверка:

```bash
./scripts/doctor.sh
```

## Updating

```bash
./scripts/update.sh
```

`snap-pac` автоматически делает pre/post снимки root перед операциями `pacman`.

## Recovery

| Компонент | Роль |
|-----------|------|
| Snapper | снимки `@` / `@home` |
| snap-pac | pre/post при обновлениях |
| grub-btrfs | загрузка в снимок из GRUB |
| btrfs-assistant | GUI отката |
| btrfs scrub | проверка целостности |

```bash
./install/snapper.sh     # настроить / починить стек
./scripts/doctor.sh      # статус
```

Откат после плохого обновления:

1. GRUB → submenu **snapshots** → boot
2. или **Btrfs Assistant** → restore

## Packages

Списки в `packages/`:

| Файл | Назначение |
|------|------------|
| `pacman.txt` | официальные репозитории |
| `aur.txt` | AUR (`yay`) |
| `flatpak.txt` | Flatpak |
| `cursor-extensions.txt` | расширения Cursor |

Установка пакетов: `./install/packages.sh`  
Расширения Cursor: `./install/cursor.sh`

## Customization

Конфиги линкуются из `configs/`:

```
configs/
  fastfetch/config.jsonc
  ghostty/config          # Catppuccin Mocha
  git/.gitconfig
  starship/starship.toml
  zsh/.zshrc
```

Правь файлы в репозитории — симлинки уже указывают сюда (`./install/shell.sh`).

Модули установки: `install/*.sh` (docker, fonts, kde, snapper, …).

## Screenshots

Положи скриншоты в `assets/screenshots/` и добавь сюда:

```markdown
![desktop](assets/screenshots/desktop.png)
```

## Structure

```
bootstrap.sh              # оркестратор (run + continue on error)
packages/                 # декларативные списки
install/                  # модули установки
  packages.sh
  shell.sh
  fonts.sh
  ghostty.sh
  docker.sh
  cursor.sh
  devtools.sh
  kde.sh
  snapper.sh
scripts/
  doctor.sh               # единый health-check
  update.sh
configs/
assets/
```

## Roadmap

1. ✅ Snapper + rollback
2. ✅ Модульный bootstrap + doctor
3. ⏳ Экспорт Plasma в `configs/kde/`
4. ⏳ Homelab restore (GitLab, Proxy Manager, …)
