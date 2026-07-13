# dotfiles

Воспроизводимое окружение EndeavourOS + **самовосстановление** на Btrfs
(по плану из [выбора дистрибутива](https://chatgpt.com/share/6a550be6-95f0-83eb-bd87-d5ec3750f857)).

## Требование

При установке — **Btrfs** (`@`, `@home`, …). Timeshift **не** используем: только Snapper.

## Быстрый старт

```bash
git clone https://github.com/RioTwWks/dotfiles
cd dotfiles
./bootstrap.sh
```

## Самовосстановление (шаг 1 плана)

| Компонент | Роль |
|-----------|------|
| **Snapper** | снимки `@` / `@home` |
| **snap-pac** | pre/post при `pacman` |
| **grub-btrfs** | загрузка в снимок из GRUB |
| **btrfs-assistant** | GUI отката |
| **btrfs scrub** | проверка целостности |

```bash
./install/snapper.sh          # настроить стек (идемпотентно)
./scripts/update.sh           # обновление со снимками
./scripts/versions.sh         # doctor
```

Откат: GRUB → snapshots **или** Btrfs Assistant.

## Дорожная карта из чата

1. ✅ Snapper + автоматические снимки Btrfs → `install/snapper.sh`
2. ⏳ Bootstrap одной командой → `./bootstrap.sh` (доращиваем модули)
3. ⏳ Автоустановка Cursor / Ghostty / Fastfetch / Docker / Zsh
4. ⏳ Восстановление homelab-сервисов (GitLab, Proxy Manager, …)

## Структура

```
bootstrap.sh
packages/                 # pacman / AUR / flatpak
install/
  snapper.sh              # Btrfs self-recovery
scripts/
  update.sh
  versions.sh
  …
configs/
```
