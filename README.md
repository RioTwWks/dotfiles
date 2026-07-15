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
# задать BORG_PASSPHRASE
$EDITOR ~/.config/dotfiles/backup.env

# первый полный бэкап (засевает репозиторий)
./scripts/backup.sh init

./scripts/doctor.sh
```

## Updating

```bash
./scripts/update.sh
```

Обновляет (если утилита есть): `pacman`, `yay -Sua`, `flatpak`, `rustup`, `mise`, `npm -g`, `flutter`.  
После обновления — инкрементальный Borg-бэкап.  
`snap-pac` делает pre/post снимки root при операциях pacman.

## Recovery (быстрый откат)

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

## Backup (инкрементальный)

[Borg](https://www.borgbackup.org/) хранит архивы в одном репозитории: первый `init` — полный seed, каждый следующий `create` добавляет **только изменённые чанки**.

| Триггер | Действие |
|---------|----------|
| `backup.sh init` | создать репо + первый полный архив |
| `backup.sh create` | ручной инкремент |
| pacman hook | после Install/Upgrade/Remove (с debounce 1ч) |
| daily timer | автоматический инкремент |
| `update.sh` | инкремент после обновления системы |
| weekly prune | retention: daily/weekly/monthly |

```bash
./install/backup.sh          # borg + timer + pacman hook
$EDITOR ~/.config/dotfiles/backup.env
./scripts/backup.sh init     # первый полный
./scripts/backup.sh create   # дальше — только дельта
./scripts/backup.sh list
./scripts/backup.sh prune
```

Конфиг: `configs/backup/` → `~/.config/dotfiles/backup.env`  
Исключения: `configs/backup/excludes.txt`  
По умолчанию бэкапятся `$HOME` и `/etc` (пути в `BACKUP_PATHS`).

Восстановление файла/каталога:

```bash
borg list
borg extract ::ARCHIVE-NAME home/ivan/path/to/file
```

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
  backup/     backup.env.example, excludes.txt
  cursor/     settings.json, keybindings.json
  docker/     daemon.json
  fastfetch/
  ghostty/
  git/
  kde/        (placeholder)
  starship/
  zsh/
```

## Screenshots

Файлы в `assets/screenshots/`:

```markdown
![desktop](assets/screenshots/desktop.png)
```

## Structure

```
bootstrap.sh
packages/
install/          # … snapper.sh, backup.sh
scripts/
  doctor.sh
  update.sh
  backup.sh       # init | create | list | prune | check
configs/
assets/
```

## Roadmap

1. ✅ Snapper + rollback  
2. ✅ Модульный bootstrap + doctor + services/fonts  
3. ✅ Инкрементальный Borg backup (init → create → hook/timer)  
4. ⏳ Экспорт Plasma → `configs/kde/`  
5. ⏳ Homelab restore (GitLab, Proxy Manager, …)
