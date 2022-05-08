#!/bin/bash

set -euo pipefail

BOLD="$(printf "\033[1m")"
RED="$(printf "\033[31m")"
GREEN="$(printf "\033[32m")"
YELLOW="$(printf "\033[33m")"
BLUE="$(printf "\033[34m")"
GREY="$(printf "\033[37m")"
UL="$(printf "\033[4m")"
NC="$(printf "\033[0m")"
URL="${BLUE}${UL}"

print_help() {
    echo "Usage: initialize_new_repo.sh [-h|--help] NAME BZR_URL"
}

section() {
    WIDTH=55
    printf '=%.0s' $(seq 0 "$WIDTH")
    echo
    echo " $*"
    printf '=%.0s' $(seq 0 "$WIDTH")
    echo
}

while test $# -gt 0
do
    case "$1" in
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            _positionals+=("$1")
            ;;
    esac
    shift
done
# Take care expanding this potentially empty array
if [[ "${_positionals[*]+true}" == true ]]; then
    set "${_positionals[@]}"
fi
if [[ $# -ne 2 ]]; then
    print_help
    exit 0
fi

DIR=$(pwd)
WORKDIR=$(pwd)
repo_name="$1"
repo_url="$2"
repo_dir="$WORKDIR/$repo_name"

if [[ -e "$repo_name" ]]; then
    echo "${RED}Error: Output directory named $repo_name already exists$NC"
    exit 1
fi

echo "Creating new git repository ${BOLD}$repo_name$NC from $URL$repo_url$NC"


(
    set -x
    mkdir "$repo_dir"
    cd $repo_dir
    git init --initial-branch=main
)

(
    set -x
    # Run docker to fill out this repository
    echo "${BOLD}Building repository$NC"
    docker build -t bzr_cloner .

    docker run -v "$repo_dir:/opt/repo" bzr_cloner bash -c "
    set -x
    brz checkout ${repo_url} /opt/imported
    cd /opt/imported
    brz fast-export -b main | git -C /opt/repo fast-import
    "
    git -C "$repo_dir" reset --hard main
)

echo "${BOLD}Adding auto maintenance tools to repository$NC"
(
    set -x
    shopt -s dotglob 
    cd "$repo_dir"
    git switch --orphan auto_update
    cp -r ${DIR}/template/* .
    # Insert the upstream configuration file
    cat <<EOF > config.yaml
source:
    url: "$repo_url"
EOF
    git add -A
    git commit -m "Initial autotooling configuration"
)

echo "Initial cloning configuration complete."
echo
echo "Please run this command to push to a new remote repository:"
echo
echo "$BOLD    git -C \"$repo_dir\" remote add origin <remote_url>$NC"
echo "$BOLD    git -C \"$repo_dir\" push -u origin main auto_update$NC"
echo