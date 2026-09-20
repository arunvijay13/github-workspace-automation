#!/bin/bash
set -Eeuo pipefail

git_validate_branch_name() {
    local branch="$1"

    git check-ref-format --branch "$branch" >/dev/null 2>&1
}

git_is_clean() {
    local repository_path="$1"

    [[ -z "$(git -C "$repository_path" status --porcelain)" ]]
}

git_branch_exists_local() {
    local repository_path="$1"
    local branch="$2"

    git -C "$repository_path" \
        show-ref \
        --verify \
        --quiet \
        "refs/heads/$branch"
}

git_branch_exists_remote() {
    local repository_path="$1"
    local branch="$2"

    git -C "$repository_path" \
        show-ref \
        --verify \
        --quiet \
        "refs/remotes/origin/$branch"
}

git_source_branch_exists() {
    local repository_path="$1"
    local branch="$2"

    git -C "$repository_path" \
        ls-remote \
        --exit-code \
        --heads \
        origin \
        "$branch" \
        >/dev/null 2>&1
}

git_create_feature_branch() {
    local repository_path="$1"
    local source_branch="$2"
    local feature_branch="$3"

    if ! git_is_clean "$repository_path"; then
        log_error "Working tree is not clean: $repository_path"
        return 1
    fi

    git -C "$repository_path" switch \
        --create "$feature_branch" \
        "origin/$source_branch"
}

git_switch_feature_branch() {
    local repository_path="$1"
    local feature_branch="$2"

    if ! git_is_clean "$repository_path"; then
        log_error "Working tree is not clean: $repository_path"
        return 1
    fi

    git -C "$repository_path" switch "$feature_branch"
}

git_track_remote_feature_branch() {
    local repository_path="$1"
    local feature_branch="$2"

    if ! git_is_clean "$repository_path"; then
        log_error "Working tree is not clean: $repository_path"
        return 1
    fi

    git -C "$repository_path" switch \
        --track \
        --create "$feature_branch" \
        "origin/$feature_branch"
}

git_merge_source_into_feature() {
    local repository_path="$1"
    local source_branch="$2"

    if ! git_is_clean "$repository_path"; then
        log_error "Working tree is not clean: $repository_path"
        return 1
    fi

    git -C "$repository_path" merge \
        --no-edit \
        "origin/$source_branch"
}