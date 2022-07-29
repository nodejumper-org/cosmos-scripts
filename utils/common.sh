NC="\e[0m"           # no color
CYAN="\e[1m\e[1;96m" # cyan color

function printLogo {
  bash <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/logo.sh)
}

function printLine {
  echo "=================================================================================================="
}

function printCyan {
  echo -e "${CYAN}${1}${NC}"
}

function addToPath {
  # shellcheck disable=SC2086
  echo "export PATH=${PATH}:${1}" >>${HOME}/.bash_profile
}
