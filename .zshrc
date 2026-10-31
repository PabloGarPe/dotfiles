# fastfetch con el avatar al abrir una terminal de kitty (config: ~/.config/fastfetch,
# generada por matugen). Va antes del instant prompt de p10k, que no admite salida.
# Solo en la shell principal de kitty: no en subshells, nvim ni otros terminales.
if [[ -o interactive && -n $KITTY_WINDOW_ID && $SHLVL -le 1 && -z $NVIM ]] && (( $+commands[fastfetch] )); then
  fastfetch
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Plugins de oh-my-zsh (antes de cargar la config de CachyOS, que los respeta)
plugins=(git fzf extract sudo)

# oh-my-zsh, Powerlevel10k, autosugerencias, resaltado y búsqueda en historial
source /usr/share/cachyos-zsh-config/cachyos-config.zsh

# Escribir el nombre de una carpeta hace cd a ella
setopt autocd

# Autocompletado sin distinguir mayúsculas y con menú navegable
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select

# ↑/↓ buscan en el historial lo que ya has escrito
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
alias dots='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
