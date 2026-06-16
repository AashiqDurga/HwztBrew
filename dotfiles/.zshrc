# =============================================================================
# ~/.zshrc — shell config (symlinked from the mac-setup repo)
# Oh My Zsh for plugin management + starship for the prompt.
# =============================================================================

# ----- Homebrew (Apple Silicon) ---------------------------------------------
eval "$(/opt/homebrew/bin/brew shellenv)"

# ----- Oh My Zsh -------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""                       # empty — starship draws the prompt instead

# Plugins. git ships with OMZ; the other two are cloned by setup.sh.
# (syntax-highlighting must be last.)
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)
source "$ZSH/oh-my-zsh.sh"

# ----- History (extends OMZ defaults) ---------------------------------------
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS

# ----- mise (language version manager) --------------------------------------
command -v mise >/dev/null && eval "$(mise activate zsh)"

# ----- zoxide (smarter cd) ---------------------------------------------------
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# ----- fzf (fuzzy finder) ----------------------------------------------------
command -v fzf >/dev/null && source <(fzf --zsh) 2>/dev/null

# ----- direnv ----------------------------------------------------------------
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# ----- Starship prompt (must come after OMZ) --------------------------------
command -v starship >/dev/null && eval "$(starship init zsh)"

# ----- Aliases ---------------------------------------------------------------
[[ -f ~/.aliases ]] && source ~/.aliases
