# Git.
export GIT_PS1_SHOWCOLORHINTS=true
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
# -----------------------------------------------------------------------------
# SSH Agent for Git
env=~/.ssh/agent.env

agent_load_env() { 
    test -f "$env" && . "$env" >| /dev/null ; 
}

agent_start () {
    (umask 077; ssh-agent >| "$env")
    . "$env" >| /dev/null ; 
}

agent_load_env

# agent_run_state: 0=agent running w/ key; 1=agent w/o key; 2= agent not running
agent_run_state=$(ssh-add -l >| /dev/null 2>&1; echo $?)

if [ ! "$SSH_AUTH_SOCK" ] || [ $agent_run_state = 2 ]; then
    agent_start
    ssh-add
elif [ "$SSH_AUTH_SOCK" ] && [ $agent_run_state = 1 ]; then
    ssh-add
fi

unset env
# ----------------------------------------------------------------------
# Generic.

export CLICOLOR=1
export PREGNOR_SOURCE="${HOME}/source/github.com/pregnor"
export PS1="\n\D{%F %T} \[\033[32m\]\h \u\[\033[00m\] @ \[\033[36m\]\w\[\033[33m\]$(__git_ps1)\[\033[00m\]\n> "
# -----------------------------------------------------------------------------