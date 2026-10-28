# Version helpers for the Bash suites.

# Prints "yes" when the version $1 is 0.12.0 or later, comparing major and minor, else "no".
version_at_least_0_12() {
  local major minor
  case "$1" in
    [0-9]*.[0-9]*.*) ;;
    *) echo no; return 0 ;;
  esac
  major="${1%%.*}"
  minor="${1#*.}"; minor="${minor%%.*}"
  case "$major$minor" in
    *[!0-9]*) echo no; return 0 ;;
  esac
  if [ "$major" -ge 1 ] || [ "$minor" -ge 12 ]; then echo yes; else echo no; fi
}
