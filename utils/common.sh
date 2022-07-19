NC="\e[0m"            # no color
CYAN="\e[1m\e[1;96m"  # cyan color

function printLogo {
    bash <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/logo.sh)
}

function printLine {
    echo "=================================================================================================="
}

function printCyan {
    echo -e "${CYAN}${1}${NC}"
}
