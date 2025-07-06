# Recommended GitHub Labels

This document outlines the recommended labels for this repository. You can create these labels manually in GitHub or use the GitHub CLI.

## Priority Labels
- `priority:high` - High priority issues that should be addressed quickly
- `priority:medium` - Medium priority issues 
- `priority:low` - Low priority issues or nice-to-have features

## Type Labels
- `bug` - Something isn't working correctly
- `enhancement` - New feature or improvement to existing functionality
- `documentation` - Improvements or additions to documentation
- `question` - Questions about usage or functionality
- `duplicate` - This issue or pull request already exists
- `wontfix` - This will not be worked on
- `invalid` - This doesn't seem right

## Area Labels
- `area:keybindings` - Related to key mappings
- `area:templates` - Related to template functionality
- `area:daily-notes` - Related to daily note features
- `area:links` - Related to link functionality
- `area:search` - Related to search and find features
- `area:workspaces` - Related to workspace functionality
- `area:config` - Related to plugin configuration

## Status Labels
- `help-wanted` - Community contributions welcome
- `good-first-issue` - Good for newcomers to contribute
- `needs-triage` - Needs review and categorization
- `blocked` - Cannot proceed due to external dependencies

## Creating Labels with GitHub CLI

You can create these labels using the `gh` command:

```bash
# Type labels
gh label create "bug" --description "Something isn't working" --color "d73a4a"
gh label create "enhancement" --description "New feature or request" --color "a2eeef"
gh label create "documentation" --description "Improvements or additions to documentation" --color "0075ca"
gh label create "question" --description "Further information is requested" --color "d876e3"
gh label create "duplicate" --description "This issue or pull request already exists" --color "cfd3d7"
gh label create "wontfix" --description "This will not be worked on" --color "ffffff"
gh label create "invalid" --description "This doesn't seem right" --color "e4e669"

# Priority labels
gh label create "priority:high" --description "High priority" --color "b60205"
gh label create "priority:medium" --description "Medium priority" --color "fbca04"
gh label create "priority:low" --description "Low priority" --color "0e8a16"

# Area labels
gh label create "area:keybindings" --description "Related to key mappings" --color "c2e0c6"
gh label create "area:templates" --description "Related to template functionality" --color "c2e0c6"
gh label create "area:daily-notes" --description "Related to daily note features" --color "c2e0c6"
gh label create "area:links" --description "Related to link functionality" --color "c2e0c6"
gh label create "area:search" --description "Related to search and find features" --color "c2e0c6"
gh label create "area:workspaces" --description "Related to workspace functionality" --color "c2e0c6"
gh label create "area:config" --description "Related to plugin configuration" --color "c2e0c6"

# Status labels
gh label create "help-wanted" --description "Extra attention is needed" --color "008672"
gh label create "good-first-issue" --description "Good for newcomers" --color "7057ff"
gh label create "needs-triage" --description "Needs review and categorization" --color "ededed"
gh label create "blocked" --description "Cannot proceed due to external dependencies" --color "d93f0b"
```