# Git.
export GIT_PS1_SHOWCOLORHINTS=true
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true

if [ -f $(brew --prefix)/etc/bash_completion ]; then
    git_directory="$(${HOME}/source/github.com/pregnor/shell-scripts/get-highest-versioned-subdirectory.sh $(brew --prefix)/Cellar/git)"
    . "${git_directory}/etc/bash_completion.d/git-completion.bash"
    . "${git_directory}/etc/bash_completion.d/git-prompt.sh"
fi

# -----------------------------------------------------------------------------
# Generic.

brew_llvm_bin="$(${HOME}/source/github.com/pregnor/shell-scripts/get-highest-versioned-subdirectory.sh $(brew --prefix)/Cellar/llvm)/bin"

export CLICOLOR=1
export PATH="${brew_llvm_bin}:${PATH}"
export PREGNOR_SOURCE="${HOME}/source/github.com/pregnor"
export PS1='\n\[\033[32m\]\u@\h\[\033[00m\]:\[\033[36m\]\w\[\033[33m\]$(__git_ps1)\[\033[00m\]\n\$ '