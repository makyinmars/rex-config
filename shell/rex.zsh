# Rex shell integration for zsh: prompt marks, the working directory, and the
# rex_status and track helpers. Source it from ~/.zshrc, before zoxide:
#
#   [[ -n $REX_SESSION && -r ~/.config/rex/shell/rex.zsh ]] && source ~/.config/rex/shell/rex.zsh
#
# Outside Rex it does nothing.
[[ -n $REX_SESSION ]] || return 0

# Keep the rex that matches the server first on PATH. Startup files that
# prepend their own directories push it back.
[[ -n $REX_BIN_DIR ]] && path=("$REX_BIN_DIR" ${path:#$REX_BIN_DIR})

# OSC 133 marks each prompt and command, for Jump to Previous/Next Prompt and
# so Rex clears a program's working or blocked status when the shell gets its
# prompt back. OSC 7 reports the working directory, percent-encoded.
_rex_precmd() {
  local code=$?
  (( ${_rex_running:-0} )) && printf '\e]133;D;%d\a' $code
  _rex_running=0
  local LC_ALL=C url= char hex i
  for (( i = 1; i <= ${#PWD}; i++ )); do
    char=${PWD[i]}
    if [[ $char == [A-Za-z0-9/._~-] ]]; then
      url+=$char
    else
      printf -v hex '%%%02X' "'$char"
      url+=$hex
    fi
  done
  printf '\e]7;file://%s%s\e\\\e]133;A\a' "$HOST" "$url"
  return $code
}

_rex_preexec() {
  _rex_running=1
  printf '\e]133;C\a'
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _rex_preexec
# Run first so the exit status is read before other prompt hooks change it,
# and handed on unchanged through the return above.
precmd_functions=(_rex_precmd ${precmd_functions:#_rex_precmd})

# Report this terminal's status to Rex with the Program Status Protocol
# (OSC 7501). done and error stay until you look at the pane, and Leader o
# goes to the newest one.
#
#   rex_status working "Deploying"
#   rex_status done "Deployed"
#   rex_status clear
rex_status() {
  local state=$1 msg=${2:-}
  local pairs="state=${state}:app=${REX_STATUS_APP:-shell}"
  [[ -n $msg ]] && pairs+=":msg=$(printf '%s' "${msg[1,160]}" | base64 | tr -d '\n')"
  printf '\e]7501;%s\e\\' "$pairs"
}

# Run a command with its status in Rex: working while it runs, then done or
# error. Ctrl+C clears it.
#
#   track bun test
#   track make build
track() {
  (( $# )) || { print -u2 'usage: track COMMAND [ARGS...]'; return 2 }
  local app=${${1:t}//[^A-Za-z0-9_.+-]/}
  local REX_STATUS_APP=${app[1,32]:-shell}
  rex_status working "$*"
  "$@"
  local code=$?
  if (( code == 0 )); then
    rex_status done "$* finished"
  elif (( code == 130 )); then
    rex_status clear
  else
    rex_status error "$* failed with status $code"
  fi
  return code
}
