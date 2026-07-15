eval "$(starship init zsh)"

# Fastfetch on interactive shells
if [[ $- == *i* ]] && command -v fastfetch >/dev/null; then
    fastfetch
fi

[[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
setopt AUTO_CD
setopt EXTENDED_HISTORY

command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

[[ -r /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -r /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh

if command -v eza >/dev/null; then
  alias ls='eza'
  alias ll='eza -lah --icons'
  alias lt='eza --tree --level=2 --icons'
fi

alias doctor='~/dotfiles/scripts/doctor.sh'
alias update-system='~/dotfiles/scripts/update.sh'
alias backup='~/dotfiles/scripts/backup.sh'
