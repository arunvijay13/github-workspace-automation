# GitHub Workspace Automation

Shell automation for preparing Caterpillar PPS developer feature workspaces.

## Workspace

Every feature branch gets its own workspace:

```text
$HOME/Documents/projects/cpps/<feature-branch-name>/
```

Example:

```text
$HOME/Documents/projects/cpps/feature/CPPS-1234-price-update/
├── gciosdd_pps_web/
├── gciosdd_pps_price_manager/
├── gciosdd_pps_publish/
└── gciosdd_pps_admin/
```

## Environments

### DEV

Uses:

`master`

### TEST

Automatically discovers release branches available in all
selected repositories and selects the highest/common release branch.

Example:

`2026-release-7.1`

### QA

Discovers release branches available in all selected repositories
and presents them to the user for selection.

Example:

````text
1. 2026-release-7.1
2. 2026-release-7.0
3. 2026-release-6.9

## Feature branch behavior

The feature branch name is always requested from the user.

New branch:

```text
DEV
  ↓
master
  ↓
feature/CPPS-1234-price-update
````

or:

```text
TEST
  ↓
2026-release-7.2
  ↓
feature/CPPS-1234-price-update
```

If the feature branch already exists, the tool safely reuses it and asks:

```text
Feature branch already exists. Pull latest changes from <source> into <feature>? [y/N]:
```

If `y`, it performs:

```bash
git fetch origin --prune
git merge origin/<source-branch>
```

It never uses `git reset --hard`.

## Repositories

Configured in `config/repositories.json`:

- caterpillar-inc/gciosdd_pps_web
- caterpillar-inc/gciosdd_pps_price_manager
- caterpillar-inc/gciosdd_pps_publish
- caterpillar-inc/gciosdd_pps_admin

## Prerequisites

```bash
brew install gh
brew install jq
gh auth login
gh auth setup-git
```

## Run

```bash
./bin/github-workspace
```

## Test

Syntax:

```bash
bash -n bin/github-workspace
bash -n lib/*.sh
```

Local tests:

```bash
./tests/test_branch.sh
./tests/test_release_sort.sh
./tests/test_repository.sh
```

## Main scenarios

### DEV + one repository

Input:

```text
Environment: DEV
Feature: feature/CPPS-1001-test
Repository: gciosdd_pps_web
```

Creates:

```text
origin/master
    ↓
feature/CPPS-1001-test
```

### DEV + all repositories

Creates the same feature branch from `master` in every selected repository.

### TEST

The tool discovers branches such as:

```text
2026-release-7.1
2026-release-7.2
2026-release-8.0
```

When multiple repositories are selected, only release branches common to all
selected repositories are considered.

### Existing feature branch

If the feature branch exists, the user chooses whether to merge the latest
source branch.

### Dirty repository

If a repository has uncommitted changes, branch switching or merging is
stopped for that repository.

### Non-Git destination

A pre-existing non-Git directory is never deleted or overwritten.
