#!/bin/bash
set -Eeuo pipefail

get_repository_count() {
    jq '.repositories | length' "$REPOSITORIES_CONFIG"
}

get_repository_name() {
    local index="$1"

    jq -r \
        ".repositories[$index].name" \
        "$REPOSITORIES_CONFIG"
}

get_repository_owner() {
    local index="$1"

    jq -r \
        ".repositories[$index].owner" \
        "$REPOSITORIES_CONFIG"
}

get_repository_description() {
    local index="$1"

    jq -r \
        ".repositories[$index].description" \
        "$REPOSITORIES_CONFIG"
}

select_repositories() {
    local count
    local index
    local choice

    count="$(get_repository_count)"

    echo
    echo "Available repositories:"
    echo

    for ((index = 0; index < count; index++)); do
        printf "  %d. %s\n" \
            "$((index + 1))" \
            "$(get_repository_description "$index")"
    done

    printf "  %d. All\n" "$((count + 1))"
    echo

    while true; do
        read -r \
            -p "Select repository [1-$((count + 1))]: " \
            choice

        if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
            log_warn "Invalid selection."
            continue
        fi

        if (( choice == count + 1 )); then
            SELECTED_REPOSITORIES=()

            for ((index = 0; index < count; index++)); do
                SELECTED_REPOSITORIES+=(
                    "$(get_repository_owner "$index")/$(get_repository_name "$index")"
                )
            done

            break
        fi

        if (( choice >= 1 && choice <= count )); then
            index=$((choice - 1))

            SELECTED_REPOSITORIES=(
                "$(get_repository_owner "$index")/$(get_repository_name "$index")"
            )

            break
        fi

        log_warn "Invalid selection. Please choose 1-$((count + 1))."
    done

    echo
    log_success "Repository selection completed."
}

get_repository_workspace_name() {
    local repository="$1"

    printf '%s\n' "${repository##*/}"
}

prepare_repository_workspace() {
    local repository="$1"
    local destination="$2"

    if [[ -d "$destination/.git" ]]; then
        return 0
    fi

    if [[ -e "$destination" ]]; then
        log_error "Destination already exists and is not a Git repository:"
        log_error "$destination"
        return 1
    fi

    mkdir -p "$(dirname "$destination")"

    github_clone_repository \
        "$repository" \
        "$destination"
}

process_repository() {
    local repository="$1"
    local repository_name
    local destination
    local local_exists
    local remote_exists

    repository_name="$(get_repository_workspace_name "$repository")"

    destination="${WORKSPACE_ROOT}/${FEATURE_BRANCH}/${repository_name}"

    log_info "Processing: $repository_name"

    if ! prepare_repository_workspace "$repository" "$destination"; then
        FAILED_REPOSITORIES+=("$repository_name")
        return 1
    fi

    if ! git -C "$destination" fetch origin --prune; then
        log_error "Failed to fetch: $repository_name"
        FAILED_REPOSITORIES+=("$repository_name")
        return 1
    fi

    if ! git_source_branch_exists "$destination" "$SOURCE_BRANCH"; then
        log_error \
            "Source branch '$SOURCE_BRANCH' does not exist in $repository_name."

        FAILED_REPOSITORIES+=("$repository_name")
        return 1
    fi

    local_exists=false
    remote_exists=false

    if git_branch_exists_local "$destination" "$FEATURE_BRANCH"; then
        local_exists=true
    fi

    if git_branch_exists_remote "$destination" "$FEATURE_BRANCH"; then
        remote_exists=true
    fi

    if [[ "$local_exists" == false && "$remote_exists" == false ]]; then

        if ! git_create_feature_branch \
            "$destination" \
            "$SOURCE_BRANCH" \
            "$FEATURE_BRANCH"; then

            FAILED_REPOSITORIES+=("$repository_name")
            return 1
        fi

        CREATED_REPOSITORIES+=("$repository_name")
        return 0
    fi

    if [[ "$local_exists" == false && "$remote_exists" == true ]]; then

        if ! git_track_remote_feature_branch \
            "$destination" \
            "$FEATURE_BRANCH"; then

            FAILED_REPOSITORIES+=("$repository_name")
            return 1
        fi

        REUSED_REPOSITORIES+=("$repository_name")
        return 0
    fi

    if [[ "$local_exists" == true ]]; then

        if ! git_switch_feature_branch \
            "$destination" \
            "$FEATURE_BRANCH"; then

            FAILED_REPOSITORIES+=("$repository_name")
            return 1
        fi

        REUSED_REPOSITORIES+=("$repository_name")

        echo
        read -r \
            -p "Feature branch already exists. Pull latest changes from $SOURCE_BRANCH into $FEATURE_BRANCH for $repository_name? [y/N]: " \
            merge_choice

        case "$merge_choice" in
            y|Y|yes|YES)
                if git_merge_source_into_feature \
                    "$destination" \
                    "$SOURCE_BRANCH"; then

                    MERGED_REPOSITORIES+=("$repository_name")
                else
                    log_error \
                        "Failed to merge $SOURCE_BRANCH into $FEATURE_BRANCH for $repository_name."

                    FAILED_REPOSITORIES+=("$repository_name")
                    return 1
                fi
                ;;
        esac
    fi
}