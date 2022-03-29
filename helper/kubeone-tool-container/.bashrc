source /etc/bash_completion
export PATH=$PATH:/usr/local/bin
export PATH=$PATH:/usr/bin
export PATH="/home/kubermatic/bin:$PATH"

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
    PS1="$(powerline-go -theme $POWERLINE_THEME -cwd-max-depth 5 -newline -modules "termtitle,kube,venv,user,host,ssh,cwd,perms,git,hg,jobs,exit,root,vgo" -error $?)"
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
[ -f /home/kubermatic/bin/fubectl.source ] && source /home/kubermatic/bin/fubectl.source

# fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

#### krew
export PATH="${KREW_ROOT:-/home/kubermatic/.krew}/bin:$PATH"

#### terrafrom autocompletion
complete -C /usr/bin/terraform terraform

### kubeone autocompletion
source <(kubeone completion bash)
