# Rex shell integration for zsh. Source it from ~/.zshrc, before zoxide:
#
#   [[ -n $REX_SESSION ]] && source ~/.config/rex/shell/rex.zsh
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
