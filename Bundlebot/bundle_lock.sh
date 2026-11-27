# Source before changing shared bundle state.
bundle_lock_dir="$HOME/.bundle/bundle_build.lock"

bundle_lock_cleanup(){
  if [[ -n ${bundle_pidfile:-} ]]; then
    rm -f -- "$bundle_pidfile"
  fi
  if [[ -n ${bundle_staging_lock:-} ]]; then
    rmdir -- "$bundle_staging_lock" || :
  fi
  if [[ ${bundle_lock_owned:-} == 1 ]]; then
    rmdir -- "$bundle_lock_dir"
  fi
}

bundle_lock_acquire(){
  local pid_name=${1:-} force=${2:-}
  if [[ ${BUNDLE_BUILD_LOCK:-} != "$bundle_lock_dir" || ! -d "$bundle_lock_dir" ]]; then
    mkdir -p -- "$HOME/.bundle" || return 1
    if ! mkdir -- "$bundle_lock_dir" 2>/dev/null; then
      if [[ -d "$bundle_lock_dir" ]]; then
        if [[ $force == -f ]]; then
          echo "Warning: overriding bundle lock $bundle_lock_dir." >&2
          return 0
        fi
        echo "Another bundle build holds $bundle_lock_dir." >&2
      else
        echo "Unable to acquire bundle lock $bundle_lock_dir." >&2
      fi
      return 1
    fi
    export BUNDLE_BUILD_LOCK="$bundle_lock_dir"
    bundle_lock_owned=1
  fi
  trap bundle_lock_cleanup EXIT
  trap 'exit 129' HUP
  trap 'exit 130' INT
  trap 'exit 143' TERM
  if [[ -n $pid_name ]]; then
    bundle_pidfile="$bundle_lock_dir/$pid_name"
    printf '%s\n' "$$" > "$bundle_pidfile" || return 1
  fi
}

bundle_stop(){
  local pid_file="$bundle_lock_dir/$1" pid
  if [[ ! -f $pid_file ]]; then
    echo "No active bundle build for $1."
    return 0
  fi
  if ! read -r pid < "$pid_file" || [[ ! $pid =~ ^[1-9][0-9]+$ ]]; then
    echo "Invalid bundle PID in $pid_file." >&2
    return 1
  fi
  echo "Stopping bundle build $pid."
  kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid"
}
