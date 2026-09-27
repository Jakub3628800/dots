# Adapted from anna-oake/nixos-config (Apache-2.0; see ssh-tint.LICENSE).
# https://github.com/anna-oake/nixos-config/blob/main/modules/home/profiles/workstation/ssh-tint.zsh
# Dots changes: terminal guards, SSH option/alias handling, and reliable cleanup.

_dots_ssh_tint() {
  emulate -L zsh
  # Do not decorate configuration queries, version output, or control commands.
  # Stop at the destination: options in a remote command belong to that command.
  local -a args=("$@")
  local arg flag
  while (( $#args )); do
    arg=$args[1]
    shift args
    [[ $arg == -- || $arg != -* ]] && break
    arg=${arg#-}
    while [[ -n $arg ]]; do
      flag=$arg[1]
      arg=${arg[2,-1]}
      case $flag in
        G|V|Q|O) return 1 ;;
        B|b|c|D|E|e|F|I|i|J|L|l|m|o|P|p|R|S|W|w)
          [[ -n $arg ]] || shift args
          break ;;
      esac
    done
  done

  local config line name value host file key fallback sum
  local -A cfg
  local -a files fields
  config=$(command ssh -G "$@" 2>/dev/null) || return 1
  for line in "${(@f)config}"; do
    name=${line%% *}
    cfg[$name]=${line#* }
  done
  # Background tunnels and explicitly non-interactive sessions need no tint.
  [[ $cfg[forkafterauthentication] == yes || $cfg[sessiontype] == none ||
     $cfg[requesttty] == false || $cfg[stdinnull] == yes ]] && return 1
  host=$cfg[hostname]
  [[ -n $host ]] || return 1
  if [[ -n $cfg[hostkeyalias] && $cfg[hostkeyalias] != none ]]; then
    host=$cfg[hostkeyalias]
  elif [[ $cfg[port] != 22 ]]; then
    host="[$host]:$cfg[port]"
  fi
  # ssh -G expands paths/tokens itself. Its file list is space-separated.
  files=(${=cfg[userknownhostsfile]} ${=cfg[globalknownhostsfile]})
  for file in "${files[@]}"; do
    [[ -r $file && $file != none ]] || continue
    for line in "${(@f)$(command ssh-keygen -F "$host" -f "$file" 2>/dev/null)}"; do
      fields=(${=line})
      # Ignore comments, revoked keys, and CA markers (not a host's own key).
      [[ $#fields -ge 3 && $fields[1] != [\#@]* ]] || continue
      [[ -n $fallback ]] || fallback=$fields[3]
      if [[ $fields[2] == ssh-ed25519 ]]; then
        key=$fields[3]
        break 2
      fi
    done
  done
  key=${key:-$fallback}
  # No key recorded yet: muted red. Never scan the network or trust a new key.
  [[ -n $key ]] || { print -rn -- '#2a1a1a'; return 0; }
  sum=$(print -rn -- "$key" | command cksum) || return 1

  # 16 hues x 2 brightness levels, kept dark and muted for light foregrounds.
  zmodload zsh/mathfunc || return 1
  local -i n=$(( ${sum%% *} % 32 ))
  local -F hp=$(( n % 16 * 6 / 16.0 )) s=0.35 l=$(( n < 16 ? 0.12 : 0.19 )) c x m
  c=$(( (1 - abs(2 * l - 1)) * s ))
  x=$(( c * (1 - abs(fmod(hp, 2) - 1)) ))
  m=$(( l - c / 2 ))
  local -a rgb
  case $(( int(hp) )) in
    0) rgb=($c $x 0) ;; 1) rgb=($x $c 0) ;; 2) rgb=(0 $c $x) ;;
    3) rgb=(0 $x $c) ;; 4) rgb=($x 0 $c) ;; *) rgb=($c 0 $x) ;;
  esac
  printf '#%02x%02x%02x' $(( int((rgb[1] + m) * 255) )) $(( int((rgb[2] + m) * 255) )) $(( int((rgb[3] + m) * 255) ))
}

ssh() {
  emulate -L zsh
  # Ghostty only; never write escapes into pipelines/files or recolor nested SSH.
  if [[ ${TERM_PROGRAM:-} != ghostty || ! -o interactive ||
        ! -t 0 || ! -t 1 || $TERM == dumb ||
        -n ${SSH_CONNECTION:-} || ${DOTS_SSH_TINT:-1} == 0 ]]; then
    command ssh "$@"
    return $?
  fi
  local tint
  tint=$(_dots_ssh_tint "$@") || tint=
  if [[ -z $tint ]]; then
    command ssh "$@"
    return $?
  fi
  local -i rc=0
  {
    printf '\e]11;%s\a' "$tint"
    command ssh "$@"
    rc=$?
  } always {
    # Restore the terminal's configured default, including after interruption.
    printf '\e]111\a'
  }
  return $rc
}
