#!/bin/bash

# Configuration files
REPOS_CONFIG_FILE="repositories.conf"
DOCUSAURUS_CONFIG_FILE="docusaurus-config.json"

# Configuration: Cleanup
KEEP_REPOS=false
KEEP_DOXYGEN_OUTPUT=false
KEEP_XML=false

# Versioning-Configuration
ENABLE_VERSIONING=true
MAX_VERSIONS=10
VERSION_TAG_PATTERN="v*"
INCLUDE_CURRENT=true

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_debug() { echo -e "${YELLOW}[DEBUG]${NC} $1"; }

declare -gA REPOS
declare -gA REPOS_LABELS
declare -gA REPOS_ENABLED
declare -gA REPOS_DESCRIPTIONS

load_repositories() {
    echo_step "Loading repository configuration from $REPOS_CONFIG_FILE..."
    
    if [ ! -f "$REPOS_CONFIG_FILE" ]; then
        echo_error "Configuration file $REPOS_CONFIG_FILE not found!"
        echo_info "Creating template file..."
        create_default_config
        return 1
    fi
    
    local count=0
    local enabled_count=0
    
    while IFS='|' read -r repo_id repo_url label description enabled || [ -n "$repo_id" ]; do
        [[ "$repo_id" =~ ^#.*$ ]] && continue
        [[ -z "$repo_id" ]] && continue
        
        repo_id=$(echo "$repo_id" | xargs)
        repo_url=$(echo "$repo_url" | xargs)
        label=$(echo "$label" | xargs)
        description=$(echo "$description" | xargs)
        enabled=$(echo "$enabled" | xargs)
        
        if [ -z "$repo_url" ]; then
            echo_warn "Skipping invalid line: $repo_id (no URL)"
            continue
        fi
        
        if [[ ! "$repo_url" =~ \.git$ ]]; then
            clone_url="${repo_url}.git"
        else
            clone_url="$repo_url"
        fi
        
        if [ -z "$label" ]; then
            label=$(echo "$repo_id" | sed 's/wb-idf-//' | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
        fi
        
        if [ -z "$description" ]; then
            description="Documentation for $label"
        fi
        
        REPOS["$repo_id"]="$clone_url"
        REPOS_LABELS["$repo_id"]="$label"
        REPOS_ENABLED["$repo_id"]="${enabled:-true}"
        REPOS_DESCRIPTIONS["$repo_id"]="$description"
        
        count=$((count + 1))
        
        if [ "${enabled:-true}" = "true" ]; then
            enabled_count=$((enabled_count + 1))
            echo_info "  ✅ $label ($repo_id)"
        else
            echo_warn "  ⏸️  $label ($repo_id) - deactivated"
        fi
        
    done < "$REPOS_CONFIG_FILE"
    
    if [ $enabled_count -eq 0 ]; then
        echo_error "No active repositories found!"
        return 1
    fi

    echo_info "📦 $enabled_count of $count repositories loaded"
    return 0
}

generate_docusaurus_config() {
    echo_step "Generating $DOCUSAURUS_CONFIG_FILE for Docusaurus..."
    
    if [ -f "$DOCUSAURUS_CONFIG_FILE" ]; then
        cp "$DOCUSAURUS_CONFIG_FILE" "${DOCUSAURUS_CONFIG_FILE}.backup"
    fi
    
    python3 << 'PYTHON_END'
import json
import os

repos_data = []

config_file = os.environ.get('REPOS_CONFIG_FILE', 'repositories.conf')

with open(config_file, 'r') as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        parts = line.split('|')
        if len(parts) < 5:
            continue
        
        repo_id = parts[0].strip()
        repo_url = parts[1].strip()
        label = parts[2].strip()
        description = parts[3].strip()
        enabled = parts[4].strip().lower() == 'true'
        
        github_url = repo_url.replace('.git', '')
        
        repos_data.append({
            "id": repo_id,
            "label": label,
            "description": description,
            "editUrl": f"{github_url}/tree/main/",
            "githubUrl": github_url,
            "enabled": enabled
        })

config = {
    "repositories": repos_data,
    "settings": {
        "versioning": {
            "enabled": True,
            "showUnreleased": True,
            "currentLabel": "Next",
            "currentPath": "next"
        },
        "branding": {
            "title": "WhirlingBits Documentation",
            "tagline": "ESP-IDF Component Documentation",
            "organizationName": "WhirlingBits"
        }
    }
}

with open('repositories.json', 'w') as f:
    json.dump(config, f, indent=2)

print(f"✅ {len(repos_data)} repositories written")
PYTHON_END
    
    local py_exit=$?
    
    if [ $py_exit -eq 0 ]; then
        echo_info "✅ $DOCUSAURUS_CONFIG_FILE successfully generated"
        return 0
    else
        echo_error "❌ Error generating configuration"
        if [ -f "${DOCUSAURUS_CONFIG_FILE}.backup" ]; then
            mv "${DOCUSAURUS_CONFIG_FILE}.backup" "$DOCUSAURUS_CONFIG_FILE"
        fi
        return 1
    fi
}

create_default_config() {
    cat > "$REPOS_CONFIG_FILE" << 'EOF'
# Repository Configuration
# Format: REPO_ID|REPO_URL|LABEL|DESCRIPTION|ENABLED

wb-idf-core|https://github.com/WhirlingBits/wb-idf-core|wb-idf-core|Core functionality|true
EOF
    
    echo_info "Template-Konfiguration erstellt: $REPOS_CONFIG_FILE"
}

cleanup_temp_files() {
    echo_step "Räume temporäre Dateien auf..."
    local cleaned=0
    
    if [ "$KEEP_DOXYGEN_OUTPUT" = false ]; then
        for repo_name in "${!REPOS[@]}"; do
            local repo_dir="repos/$repo_name"
            if [ -d "$repo_dir/doxygen" ]; then
                rm -rf "$repo_dir/doxygen"
                ((cleaned++))
            fi
        done
    fi
    
    [ "$KEEP_XML" = false ] && [ -d "temp_xml" ] && rm -rf temp_xml && ((cleaned++))
    [ "$KEEP_REPOS" = false ] && [ -d "repos" ] && rm -rf repos && ((cleaned++))
    [ -d "sidebars/.backup" ] && rm -rf sidebars/.backup && ((cleaned++))
    
    # ✅ Safe ls-check
    if ls *.log 1> /dev/null 2>&1; then
        rm -f *.log
        ((cleaned++))
    fi
    
    [ -f "${DOCUSAURUS_CONFIG_FILE}.backup" ] && rm -f "${DOCUSAURUS_CONFIG_FILE}.backup"
    [ -f "sidebars.js" ] && rm -f "sidebars.js" && ((cleaned++))
    [ -f "sidebars.json" ] && rm -f "sidebars.json" && ((cleaned++))
    
    [ $cleaned -gt 0 ] && echo_info "✅ $cleaned Cleanup-Operationen"
}

cleanup_on_exit() {
    local exit_code=$?
    echo ""
    
    if [ $exit_code -ne 0 ]; then
        echo_error "Script terminated with error code $exit_code"
        echo_warn "Running cleanup..."
    fi
    
    cleanup_temp_files
    exit $exit_code
}

trap cleanup_on_exit EXIT

check_dependencies() {
    echo_step "Checking dependencies..."
    local missing=0
    for cmd in git doxygen python3; do
        if ! command -v $cmd &> /dev/null; then
            echo_error "$cmd not found!"
            ((missing++))
        fi
    done
    
    if [ $missing -gt 0 ]; then
        echo_error "$missing dependencies missing!"
        return 1
    fi

    echo_info "✅ All dependencies found"
    return 0
}

get_repo_versions() {
    local repo_name=$1
    local repo_dir="repos/$repo_name"
    
    [ ! -d "$repo_dir" ] && echo "" && return
    
    cd "$repo_dir" || return
    local tags=$(git tag -l "$VERSION_TAG_PATTERN" --sort=-version:refname 2>/dev/null | sed 's/^v//')
    cd - > /dev/null || return
    
    [ -n "$tags" ] && echo "$tags" | head -n $MAX_VERSIONS | tr '\n' ' '
}

create_versions_json() {
    local repo_name=$1
    local versions_string=$2
    
    echo_debug "create_versions_json: repo=$repo_name, versions='$versions_string'"
    
    local versions_json="["
    local first=true
    local has_versions=false
    
    for version in $versions_string; do
        [ "$version" = "current" ] && continue
        
        local version_path="${repo_name}_versioned_docs/version-$version"
        if [ ! -d "$version_path" ]; then
            echo_warn "Version $version skipped (path missing: $version_path)"
            continue
        fi
        
        local md_count=$(find "$version_path" -maxdepth 1 -type f \( -name "*.md" -o -name "*.mdx" \) 2>/dev/null | wc -l)
        if [ $md_count -eq 0 ]; then
            echo_warn "Version $version skipped (no MD files)"
            continue
        fi
        
        has_versions=true
        
        [ "$first" = false ] && versions_json+=","
        first=false
        versions_json+="\"$version\""
    done
    
    versions_json+="]"
    
    if [ "$has_versions" = true ]; then
        echo "$versions_json" > "${repo_name}_versions.json"
        echo_info "✅ ${repo_name}_versions.json → $versions_json"
    else
        rm -f "${repo_name}_versions.json" 2>/dev/null
        echo_debug "No versions found → ${repo_name}_versions.json not created"
    fi
}

create_versions_page() {
    local repo_name=$1
    local versions_string=$2
    local label="${REPOS_LABELS[$repo_name]}"
    local github_url="${REPOS[$repo_name]%.git}"
    
    [ -z "$versions_string" ] && return
    
    local versions_page="$repo_name/versions.md"
    
    echo_debug "Creating versions page: $versions_page"
    
    cat > "$versions_page" << EOF
---
id: versions
title: ${label} Versions
sidebar_label: Versions
---

# ${label} Documentation Versions

This page lists all available versions of the ${label} documentation.

## Current Version (Recommended)

The current version reflects the latest development state:

- [**Next (Unreleased)**](./) - Latest development version from \`main\` branch

## Released Versions

The following stable versions are available:

EOF
    
    local version_count=0
    for version in $versions_string; do
        [ "$version" = "current" ] && continue
        
        local version_path="${repo_name}_versioned_docs/version-$version"
        if [ ! -d "$version_path" ]; then
            echo_debug "  Skipping version $version (path not found)"
            continue
        fi
        
        echo "- [**$version**](../$version/) - Stable release \`v$version\`" >> "$versions_page"
        ((version_count++))
    done
    
    if [ $version_count -eq 0 ]; then
        echo "" >> "$versions_page"
        echo "_No stable versions released yet._" >> "$versions_page"
    fi
    
    cat >> "$versions_page" << EOF

## Version Archive

You can find all releases and their changelogs in the GitHub repository:

- [📦 GitHub Releases]($github_url/releases)
- [📝 Changelog]($github_url/blob/main/CHANGELOG.md)

## Version Support

- **Next**: Active development, may contain breaking changes
- **Latest Stable**: Recommended for production use
- **Older Versions**: Maintained for bug fixes only

## Upgrading

To upgrade between versions, please refer to the migration guide in each release notes.
EOF
    
    echo_info "✅ Created $versions_page ($version_count versions)"
}


generate_sidebar_from_markdown() {
    local target_dir=$1
    local repo_name=$2
    local version=$3
    local repo_dir="repos/$repo_name"
    
    echo_debug "Generating sidebar for: $target_dir"

    # ✅ Check for DoxygenLayout.xml
    local layout_file="$repo_dir/DoxygenLayout.xml"
    local use_doxygen_layout=false
    
    if [ -f "$layout_file" ]; then
        use_doxygen_layout=true
        echo_debug "Found DoxygenLayout.xml - using Doxygen structure"
    else
        echo_debug "No DoxygenLayout.xml - using flat structure"
    fi

    # Find all Markdown files (excluding index.md and versions.md)
    local md_files=()
    while IFS= read -r -d '' file; do
        local basename=$(basename "$file" .md)
        [ "$basename" = "index" ] && continue
        [ "$basename" = "versions" ] && continue
        md_files+=("$basename")
    done < <(find "$target_dir" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)
    
    # Sort alphabetically
    IFS=$'\n' md_files=($(sort <<<"${md_files[*]}"))
    unset IFS
    
    echo_debug "Found ${#md_files[@]} markdown files (excluding index/versions)"
    
    # Create Sidebar JSON
    local sidebar_file
    if [ "$version" = "current" ]; then
        sidebar_file="$repo_name/sidebars.json"
    else
        mkdir -p "${repo_name}_versioned_sidebars"
        sidebar_file="${repo_name}_versioned_sidebars/version-$version-sidebars.json"
    fi
    
    # ✅ Generate structured sidebar
    cat > "$sidebar_file" << 'EOF'
{
  "apiSidebar": [
    {
      "type": "doc",
      "id": "index",
      "label": "Overview"
    }
EOF
    
    # ✅ Add API Reference category (only if files exist)
    if [ ${#md_files[@]} -gt 0 ]; then
        cat >> "$sidebar_file" << 'EOF'
,
    {
      "type": "category",
      "label": "API Reference",
      "collapsed": false,
      "items": [
EOF
        
        # ✅ FIX: First collect all entries with correct array handling
        if [ "$use_doxygen_layout" = true ]; then
            echo_debug "Parsing DoxygenLayout.xml for sidebar structure..."

            # ✅ Collect all sidebar items in an array
            local sidebar_items=()
            # ✅ Track used files separately
            local used_files=()
            
            # Python helper for DoxygenLayout.xml parsing
            while IFS='|' read -r group_ref group_title has_subtabs; do
                # Skip ERROR lines
                [[ "$group_ref" == "ERROR" ]] && continue

                # Check if MD file exists
                local found_md=false
                for md_file in "${md_files[@]}"; do
                    if [[ "$md_file" == *"$group_ref"* ]] || [[ "$md_file" == "$group_ref" ]]; then
                        found_md=true

                        # Extract label from frontmatter
                        local label="$group_title"
                        if [ -f "$target_dir/$md_file.md" ] && [ -z "$group_title" ]; then
                            local frontmatter_label=$(sed -n '/^---$/,/^---$/p' "$target_dir/$md_file.md" | grep '^title:' | sed 's/^title: *//' | sed 's/^["'\'']//' | sed 's/["'\'']$//')
                            [ -n "$frontmatter_label" ] && label="$frontmatter_label"
                        fi
                        
                        # Fallback Label
                        if [ -z "$label" ] || [ "$label" = "$group_ref" ]; then
                            label=$(echo "$md_file" | sed 's/wb_idf_//' | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
                        fi

                        # Store item info
                        sidebar_items+=("$md_file|$label")
                        # ✅ FIX: Track used files separately
                        used_files+=("$md_file")
                        break
                    fi
                done
                
                if [ "$found_md" = false ]; then
                    echo_debug "  Warning: No MD file found for group reference '$group_ref'"
                fi
            done < <(python3 << PYTHON_EOF
import xml.etree.ElementTree as ET
import sys

try:
    tree = ET.parse('$layout_file')
    root = tree.getroot()
    
    # Finde navindex
    navindex = root.find('.//navindex')
    if navindex is None:
        sys.exit(0)
    
    for tab in navindex.findall('tab'):
        if tab.get('visible', 'yes') != 'yes':
            continue
        
        tab_type = tab.get('type', 'user')
        title = tab.get('title', '')
        url = tab.get('url', '')
        
        # Extrahiere @ref group_name aus URL
        import re
        ref_match = re.search(r'@ref\s+(\w+)', url)
        if ref_match:
            group_ref = ref_match.group(1)
            has_subtabs = 'yes' if tab.findall('tab') else 'no'
            print(f"{group_ref}|{title}|{has_subtabs}")
            
            # Sub-Tabs
            for subtab in tab.findall('tab'):
                sub_title = subtab.get('title', '')
                sub_url = subtab.get('url', '')
                sub_ref_match = re.search(r'@ref\s+(\w+)', sub_url)
                if sub_ref_match:
                    sub_group_ref = sub_ref_match.group(1)
                    print(f"{sub_group_ref}|{sub_title}|no")

except Exception as e:
    print(f"ERROR|Parsing failed: {str(e)}|no", file=sys.stderr)
    sys.exit(1)
PYTHON_EOF
)

            # ✅ Generate JSON from collected items
            local first=true
            for item in "${sidebar_items[@]}"; do
                IFS='|' read -r md_file label <<< "$item"
                
                [ "$first" = false ] && echo "," >> "$sidebar_file"
                first=false
                
                cat >> "$sidebar_file" << EOF
        {
          "type": "doc",
          "id": "$md_file",
          "label": "$label"
        }
EOF
            done
            
            for md_file in "${md_files[@]}"; do
                [ -z "$md_file" ] && continue

                # ✅ Check if already used (exact string comparison)
                local is_used=false
                for used in "${used_files[@]}"; do
                    if [ "$md_file" = "$used" ]; then
                        is_used=true
                        break
                    fi
                done

                # Skip already used files
                [ "$is_used" = true ] && continue
                
                [ "$first" = false ] && echo "," >> "$sidebar_file"
                first=false

                # Extract label from frontmatter
                local label="$md_file"
                if [ -f "$target_dir/$md_file.md" ]; then
                    local frontmatter_label=$(sed -n '/^---$/,/^---$/p' "$target_dir/$md_file.md" | grep '^title:' | sed 's/^title: *//' | sed 's/^["'\'']//' | sed 's/["'\'']$//')
                    [ -n "$frontmatter_label" ] && label="$frontmatter_label"
                fi
                
                if [ "$label" = "$md_file" ]; then
                    label=$(echo "$md_file" | sed 's/wb_idf_//' | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
                fi
                
                cat >> "$sidebar_file" << EOF
        {
          "type": "doc",
          "id": "$md_file",
          "label": "$label"
        }
EOF
            done
        else
            # ✅ Fallback: Simple alphabetical list (without DoxygenLayout.xml)
            echo_debug "Using flat structure (no DoxygenLayout.xml)..."
            
            local first=true
            for md_file in "${md_files[@]}"; do
                [ "$first" = false ] && echo "," >> "$sidebar_file"
                first=false

                # Extract label from frontmatter
                local label="$md_file"
                if [ -f "$target_dir/$md_file.md" ]; then
                    local frontmatter_label=$(sed -n '/^---$/,/^---$/p' "$target_dir/$md_file.md" | grep '^title:' | sed 's/^title: *//' | sed 's/^["'\'']//' | sed 's/["'\'']$//')
                    [ -n "$frontmatter_label" ] && label="$frontmatter_label"
                fi
                
                if [ "$label" = "$md_file" ]; then
                    label=$(echo "$md_file" | sed 's/wb_idf_//' | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
                fi
                
                cat >> "$sidebar_file" << EOF
        {
          "type": "doc",
          "id": "$md_file",
          "label": "$label"
        }
EOF
            done
        fi
        
        cat >> "$sidebar_file" << 'EOF'

      ]
    }
EOF
    fi

    # ✅ Close sidebar
    cat >> "$sidebar_file" << 'EOF'
  ]
}
EOF
    
    echo_info "✅ Generated sidebar: $sidebar_file (${#md_files[@]} items)"
}

process_repo() {
    local repo_name=$1
    local repo_url=$2
    local version=${3:-"current"}
    
    [ "${REPOS_ENABLED[$repo_name]}" != "true" ] && echo_warn "Überspringe $repo_name" && return 0
    
    local label="${REPOS_LABELS[$repo_name]}"
    
    echo ""
    echo "═══════════════════════════════════════════════════"
    echo_step "Processing: $label ($repo_name) - Version: $version"
    echo "═══════════════════════════════════════════════════"
    
    local repo_dir="repos/$repo_name"
    
    # Clone/Update
    if [ -d "$repo_dir" ]; then
        cd "$repo_dir" || return 1
        git fetch --all --tags --quiet 2>/dev/null || true
        cd - > /dev/null || return 1
    else
        mkdir -p repos
        if ! git clone "$repo_url" "$repo_dir"; then
            echo_error "Clone failed"
            return 1
        fi
    fi
    
    cd "$repo_dir" || return 1
    
    # Checkout Version
    local git_tag
    if [ "$version" = "current" ]; then
        if ! git checkout main 2>/dev/null && ! git checkout master 2>/dev/null; then
            echo_error "No main/master branch found"
            cd - > /dev/null || return 1
            return 1
        fi
        git pull --quiet 2>/dev/null || true
        git_tag="current"
    else
        git_tag="v${version}"
        if ! git checkout "tags/$git_tag" --quiet 2>/dev/null; then
            echo_error "Tag $git_tag not found"
            cd - > /dev/null || return 1
            return 1
        fi
    fi
    
    cd - > /dev/null || return 1
    
    # Doxygen
    if [ ! -f "$repo_dir/Doxyfile" ]; then
        echo_error "Doxyfile not found"
        return 1
    fi
    
    cd "$repo_dir" || return 1
    if ! doxygen Doxyfile > /dev/null 2>&1; then
        echo_error "Doxygen error"
        cd - > /dev/null || return 1
        return 1
    fi
    cd - > /dev/null || return 1
    
    if [ ! -d "$repo_dir/doxygen/xml" ]; then
        echo_error "XML fehlt"
        return 1
    fi
    
    local xml_count=$(find "$repo_dir/doxygen/xml" -name "*.xml" 2>/dev/null | wc -l)
    echo_info "✅ $xml_count XML-Dateien"
    
    # Target Directory
    local target_dir
    if [ "$version" = "current" ]; then
        target_dir="$repo_name"
    else
        target_dir="${repo_name}_versioned_docs/version-$version"
    fi
    
    echo_debug "Target: $target_dir"
    mkdir -p "$target_dir"
    
    # Markdown conversion
    if [ ! -f "doxygen_to_markdown.py" ]; then
        echo_error "doxygen_to_markdown.py not found"
        return 1
    fi
    
    # ✅ Pass DoxygenLayout.xml if available
    local layout_arg=""
    if [ -f "$repo_dir/DoxygenLayout.xml" ]; then
        layout_arg="--layout $repo_dir/DoxygenLayout.xml"
        echo_debug "Using DoxygenLayout.xml for structure"
    fi
    
    # ✅ FIX: Capture output and exit code separately
    local py_output
    py_output=$(python3 doxygen_to_markdown.py \
        --xml-dir "$repo_dir/doxygen/xml" \
        --output "$target_dir" \
        --format docusaurus \
        $layout_arg 2>&1)
    local py_exit=$?
    
    # Show Output (without "Processing")
    echo "$py_output" | grep -v "Processing"
    
    if [ $py_exit -ne 0 ]; then
        echo_error "Conversion failed (Exit: $py_exit)"
        return 1
    fi
    
    # Flatten api/
    if [ -d "$target_dir/api" ]; then
        find "$target_dir/api" -maxdepth 1 -type f -exec mv {} "$target_dir/" \; 2>/dev/null
        rmdir "$target_dir/api" 2>/dev/null || true
    fi
    
    # .md Extension
    for file in "$target_dir"/*; do
        if [ -f "$file" ] && [[ ! "$file" =~ \.(md|mdx|json)$ ]]; then
            if file "$file" | grep -q "text"; then
                mv "$file" "${file}.md"
            fi
        fi
    done
    
    # Check Markdown
    local md_count=$(find "$target_dir" -maxdepth 1 -type f \( -name "*.md" -o -name "*.mdx" \) 2>/dev/null | wc -l)
    
    if [ $md_count -eq 0 ]; then
        echo_error "No Markdown files found in $target_dir"
        return 1
    fi
    
    # Flatten groups/
    if [ -d "$target_dir/groups" ]; then
        mv "$target_dir/groups/"* "$target_dir/" 2>/dev/null
        rmdir "$target_dir/groups" 2>/dev/null || true
        
        find "$target_dir" -maxdepth 1 -type f \( -name "*.mdx" -o -name "*.md" \) -exec sed -i \
            -e 's|id: groups/|id: |g' \
            -e 's|](groups/|](|g' \
            {} + 2>/dev/null
    fi
    
    # Cleanup
    for unwanted in files directories namespaces classes api; do
        [ -d "$target_dir/$unwanted" ] && rm -rf "$target_dir/$unwanted"
    done
    
    find "$target_dir" -maxdepth 1 -type f \( -name "*.mdx" -o -name "*.md" \) -exec sed -i \
        -e '/<!--truncate-->/d' \
        -e '/<!--more-->/d' \
        -e 's/<a href="#[^"]*">More\.\.\.<\/a>//g' \
        {} + 2>/dev/null
    
    # ✅ REPLACED: Sidebar handling - Generate from Markdown files + DoxygenLayout.xml
    generate_sidebar_from_markdown "$target_dir" "$repo_name" "$version"
    
    echo_info "✅ $label ($version): $md_count Module"
    return 0
}

main() {
    echo "═══════════════════════════════════════════════════"
    echo_info "WhirlingBits Documentation Generator v3.3"
    echo_info "Multi-Instance Docusaurus Structure + DoxygenLayout.xml"
    echo "═══════════════════════════════════════════════════"
    echo ""
    
    check_dependencies || exit 1
    load_repositories || exit 1
    generate_docusaurus_config || exit 1
    
    mkdir -p repos
    
    local success=0
    local failed=0
    
    for repo_name in "${!REPOS[@]}"; do
        [ "${REPOS_ENABLED[$repo_name]}" != "true" ] && continue
        
        repo_url="${REPOS[$repo_name]}"
        label="${REPOS_LABELS[$repo_name]}"
        
        echo_debug "Processing repo: $repo_name"
        
        local all_versions=""
        local released_versions=""
        
        if [ "$ENABLE_VERSIONING" = true ]; then
            local repo_dir="repos/$repo_name"
            if [ ! -d "$repo_dir" ]; then
                echo_debug "Cloning $repo_name for version detection..."
                if ! git clone "$repo_url" "$repo_dir"; then
                    ((failed++))
                    continue
                fi
            fi
            
            local git_versions=$(get_repo_versions "$repo_name")
            
            if [ -n "$git_versions" ]; then
                released_versions="$git_versions"
                echo_debug "Found versions: $git_versions"
            else
                echo_debug "No git tags found matching pattern '$VERSION_TAG_PATTERN'"
            fi
            
            all_versions="current"
            [ -n "$git_versions" ] && all_versions="$all_versions $git_versions"
        else
            all_versions="current"
        fi
        
        echo_debug "Processing versions: $all_versions"
        
        for version in $all_versions; do
            if process_repo "$repo_name" "$repo_url" "$version"; then
                ((success++))
            else
                echo_error "❌ Error in $repo_name ($version)"
                ((failed++))
            fi
        done

        # ✅ UPDATED: Create versions.json and versions.md
        if [ -n "$released_versions" ]; then
            echo_debug "Creating versions.json with: $released_versions"
            create_versions_json "$repo_name" "$released_versions"
            
            # ✅ NEW: Create versions.md overview page
            echo_debug "Creating versions.md for: $repo_name"
            create_versions_page "$repo_name" "current $released_versions"
        else
            echo_debug "No released versions - skipping versions.json and versions.md"
        fi
    done
    
    echo ""
    echo "═══════════════════════════════════════════════════"
    echo_info "📊 Build Statistics:"
    echo "═══════════════════════════════════════════════════"
    echo_info "   ✅ Successful: $success"
    [ $failed -gt 0 ] && echo_error "   ❌ Failed: $failed"

    echo ""
    echo_info "🎯 Multi-Instance Structure (Docusaurus Standard):"
    for repo_name in "${!REPOS[@]}"; do
        [ "${REPOS_ENABLED[$repo_name]}" != "true" ] && continue
        
        echo ""
        echo "   $repo_name/ (current)"
        [ -f "$repo_name/sidebars.json" ] && echo "   ├── sidebars.json ✅"
        [ -f "$repo_name/versions.md" ] && echo "   ├── versions.md ✅"
        [ -f "${repo_name}_versions.json" ] && echo "   ${repo_name}_versions.json: $(cat ${repo_name}_versions.json 2>/dev/null)"
        [ -d "${repo_name}_versioned_docs" ] && echo "   ${repo_name}_versioned_docs/ ✅" && ls -1 "${repo_name}_versioned_docs/" 2>/dev/null | sed 's/^/   ├── /'
        [ -d "${repo_name}_versioned_sidebars" ] && echo "   ${repo_name}_versioned_sidebars/ ✅"
    done
    
    echo ""
    
    if [ $failed -gt 0 ]; then
        echo_error "⚠️  Build completed with errors"
        return 1
    else
        echo_info "✅ Done! Next step: npm run build"
        return 0
    fi
}

main
exit $?