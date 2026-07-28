#!/usr/bin/env bash
# Shared helpers for bazel_env's watch-file lock, sourced by both the per-tool
# launcher (launcher.sh.tpl) and the status script (status.sh.tpl).

# bazel_env_collect_watch_files <watch_base> <list_file>...
#
# In:
#   <watch_base>    workspace root the list entries are relative to.
#   <list_file>...  *_watch_dirs.txt (dirs to watch) and/or *_watch_files.txt
#                   (files to watch); missing list files are ignored.
# Out (stdout):     every watched file as an absolute path, one per line,
#                   sorted and de-duplicated (empty if none).
bazel_env_collect_watch_files() {
  local watch_base="$1"
  shift
  # Canonicalize (resolve symlinks) so launcher and status agree on paths.
  if [[ -d "$watch_base" ]]; then
    watch_base="$(cd "$watch_base" && pwd -P)"
  fi
  local list dir file
  local out=()
  for list in "$@"; do
    [[ -f "$list" ]] || continue
    case "$list" in
    *_watch_dirs.txt)
      for dir in $(cat "$list"); do
        [[ -d "$watch_base/$dir" ]] || continue
        while IFS= read -r file; do
          out+=("$file")
        done < <(find "$watch_base/$dir" -type f)
      done
      ;;
    *_watch_files.txt)
      for file in $(cat "$list"); do
        [[ -f "$watch_base/$file" ]] && out+=("$watch_base/$file")
      done
      ;;
    esac
  done
  [[ ${#out[@]} -gt 0 ]] || return 0
  printf '%s\n' "${out[@]}" | sort -u
}
