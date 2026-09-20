#!/bin/bash
set -Eeuo pipefail

select_environment() {
    echo
    echo "Available environments:"
    echo
    echo "  1. DEV"
    echo "  2. TEST"
    echo "  3. QA"
    echo "  4. CUSTOM"
    echo

    local choice

    while true; do
        read -r -p "Select environment [1-4]: " choice

        case "$choice" in
            1)
                ENVIRONMENT="DEV"
                break
                ;;
            2)
                ENVIRONMENT="TEST"
                break
                ;;
            3)
                ENVIRONMENT="QA"
                break
                ;;
            4)
                ENVIRONMENT="CUSTOM"
                break
                ;;
            *)
                log_warn "Invalid selection. Please choose 1-4."
                ;;
        esac
    done

    log_success "Selected environment: $ENVIRONMENT"
}

get_release_branches_for_repository() {
    local repository="$1"
    local current_year

    current_year="$(date +%Y)"

    gh api \
        "repos/${repository}/branches?per_page=100" \
        --paginate \
        --jq '.[].name' |
        awk -v year="$current_year" \
            '$0 ~ ("^" year "-release-[0-9]+(\\.[0-9]+)*$")'
}

get_common_release_branches() {
    local repositories=("$@")
    local repository
    local release_branches
    local common_branches=()
    local first_repository=true
    local branch
    local filtered_branches=()

    for repository in "${repositories[@]}"; do
        release_branches="$(
            get_release_branches_for_repository "$repository"
        )"

        if [[ -z "$release_branches" ]]; then
            log_error "No release branches found for: $repository"
            return 1
        fi

        if [[ "$first_repository" == true ]]; then
            while IFS= read -r branch; do
                [[ -n "$branch" ]] && common_branches+=("$branch")
            done <<< "$release_branches"

            first_repository=false
            continue
        fi

        filtered_branches=()

        for branch in "${common_branches[@]}"; do
            if printf '%s\n' "$release_branches" |
                grep -Fxq "$branch"; then
                filtered_branches+=("$branch")
            fi
        done

        common_branches=("${filtered_branches[@]}")

        if [[ "${#common_branches[@]}" -eq 0 ]]; then
            return 0
        fi
    done

    printf '%s\n' "${common_branches[@]}" | sort -V
}

get_latest_common_release_branch() {
    local repositories=("$@")
    local latest_branch

    latest_branch="$(
        get_common_release_branches "${repositories[@]}" |
            tail -n 1
    )"

    if [[ -z "$latest_branch" ]]; then
        log_error "No common release branch found."
        return 1
    fi

    printf '%s\n' "$latest_branch"
}

select_qa_release_branch() {
    local repositories=("$@")
    local branches=()
    local branch
    local choice
    local index

    while IFS= read -r branch; do
        [[ -n "$branch" ]] && branches+=("$branch")
    done < <(
        get_common_release_branches "${repositories[@]}"
    )

    if [[ "${#branches[@]}" -eq 0 ]]; then
        die "No common release branches available for QA."
    fi

    echo
    echo "Available QA release branches:"
    echo

    index=1

    for branch in "${branches[@]}"; do
        printf "  %d. %s\n" "$index" "$branch"
        ((index += 1))
    done

    echo

    while true; do
        read -r \
            -p "Select QA release branch [1-${#branches[@]}]: " \
            choice

        if [[ "$choice" =~ ^[0-9]+$ ]] &&
            (( choice >= 1 && choice <= ${#branches[@]} )); then

            SOURCE_BRANCH="${branches[$((choice - 1))]}"
            break
        fi

        log_warn "Invalid selection. Please choose 1-${#branches[@]}."
    done

    log_success "Selected QA source branch: $SOURCE_BRANCH"
}

select_custom_source_branch() {
    echo

    while true; do
        read -r -p "Enter source branch: " SOURCE_BRANCH

        if [[ -z "$SOURCE_BRANCH" ]]; then
            log_warn "Source branch cannot be empty."
            continue
        fi

        if ! git_validate_branch_name "$SOURCE_BRANCH"; then
            log_warn "Invalid Git branch name: $SOURCE_BRANCH"
            continue
        fi

        break
    done

    log_success "Selected source branch: $SOURCE_BRANCH"
}

resolve_source_branch() {
    local repositories=("$@")

    case "$ENVIRONMENT" in
        DEV)
            SOURCE_BRANCH="master"
            log_success "DEV source branch: $SOURCE_BRANCH"
            ;;

        TEST)
            SOURCE_BRANCH="$(
                get_latest_common_release_branch "${repositories[@]}"
            )"

            log_success "TEST source branch: $SOURCE_BRANCH"
            ;;

        QA)
            select_qa_release_branch "${repositories[@]}"
            ;;

        CUSTOM)
            select_custom_source_branch
            ;;

        *)
            die "Unsupported environment: $ENVIRONMENT"
            ;;
    esac
}