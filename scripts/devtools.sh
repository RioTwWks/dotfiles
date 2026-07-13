#!/usr/bin/env bash

green="\033[32m"
red="\033[31m"
reset="\033[0m"

check() {
    local name="$1"
    local cmd="$2"
    local version=""

    case "$cmd" in
        docker)
            command -v docker >/dev/null &&
            version=$(docker --version | awk '{print $3}' | tr -d ',')
            ;;
        git)
            command -v git >/dev/null &&
            version=$(git --version | awk '{print $3}')
            ;;
        python)
            command -v python >/dev/null &&
            version=$(python --version | awk '{print $2}')
            ;;
        go)
            command -v go >/dev/null &&
            version=$(go version | awk '{print $3}' | sed 's/go//')
            ;;
        terraform)
            command -v terraform >/dev/null &&
            version=$(terraform version | head -1 | awk '{print $2}' | sed 's/^v//')
            ;;
        kubectl)
            command -v kubectl >/dev/null &&
            version=$(kubectl version --client=true | head -1 | awk '{print $3}')
            ;;
        helm)
            command -v helm >/dev/null &&
            version=$(helm version --short | sed 's/^v//' | cut -d+ -f1)
            ;;
        ansible)
            command -v ansible >/dev/null &&
            version=$(ansible --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
            ;;
        uv)
            command -v uv >/dev/null &&
            version=$(uv --version | awk '{print $2}')
            ;;
        node)
            command -v node >/dev/null &&
            version=$(node --version | sed 's/^v//')
            ;;
    esac

    if [[ -n "$version" ]]; then
        printf "${green}✓${reset} %-12s %s\n" "$name" "$version"
    else
        printf "${red}✗${reset} %-12s not installed\n" "$name"
    fi
}

check Docker docker
check Git git
check Python python
check Go go
check Terraform terraform
check kubectl kubectl
check Helm helm
check Ansible ansible
check uv uv
check Node node