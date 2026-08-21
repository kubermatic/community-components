source /etc/bash_completion
export PATH=$PATH:/usr/local/bin
export PATH=$PATH:/usr/bin
export PATH="$HOME/bin:$PATH"

### start an ssh-agent if none is available (skips when one is forwarded into the container)
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
fi

### write commands immediately to history
#http://www.shellhacks.com/en/7-Tips-Tuning-Command-Line-History-in-Bash
shopt -s histappend
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND ;} history -a;history -n"
# increase hist count
export HISTSIZE=1000000
export HISTFILESIZE=1000000

# default editor
export EDITOR=vim
### powerline-go
# https://github.com/justjanne/powerline-go
function _update_ps1() {
   if [ -z $POWERLINE_THEME ]; then
        export POWERLINE_THEME=default
        #export POWERLINE_THEME=low-contrast
    fi
    # Default to powerline-go's `gitlite` module (branch name only, no working
    # tree walk). The full `git` module runs `git status --porcelain`, which
    # crawls through Docker Desktop's FUSE bridge on bind-mounted host paths
    # and takes 20-30s on the first cd into a directory.
    # Override with: export POWERLINE_GIT_MODULE=git  (or any other module
    # name, e.g. an empty string to drop the git segment entirely).
    if [ -z $POWERLINE_GIT_MODULE ]; then
        export POWERLINE_GIT_MODULE=gitlite
    fi
    PS1="$(/bin/powerline-go -theme $POWERLINE_THEME -cwd-max-depth 5 -newline -modules "termtitle,kube,venv,user,host,ssh,cwd,perms,$POWERLINE_GIT_MODULE,hg,jobs,exit,root,vgo" -error $?)"
}
export TERM="xterm-256color"
if [ "$TERM" != "linux" ]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi

### kubectl autocompletion
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k

### add default debug container
alias kdebug='kcmd bash nicolaka/netshoot'

### helm
source <(helm completion bash)

##### fubectl
[ -f /bin/fubectl.source ] && source /bin/fubectl.source

# fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

#### krew
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

#### terrafrom autocompletion
complete -C /usr/bin/terraform terraform

### just autocompletion
source <(just --completions bash)

### kubeone autocompletion
source <(kubeone completion bash)

### echo version nicely on startup
figlet "KubeOne - $(kubeone version | jq -r .kubeone.gitVersion)" | /usr/games/lolcat
