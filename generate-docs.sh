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
declare -gA REPOS_CATEGORIES
declare -gA REPOS_DISPLAY_MODE

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
    
    while IFS='|' read -r repo_id repo_url label description field5 field6 field7 || [ -n "$repo_id" ]; do
        [[ "$repo_id" =~ ^#.*$ ]] && continue
        [[ -z "$repo_id" ]] && continue
        
        repo_id=$(echo "$repo_id" | xargs)
        repo_url=$(echo "$repo_url" | xargs)
        label=$(echo "$label" | xargs)
        description=$(echo "$description" | xargs)
        field5=$(echo "$field5" | xargs)
        field6=$(echo "$field6" | xargs)
        field7=$(echo "$field7" | xargs)
        
        # Detect format
        local category display_mode enabled
        
        if [ -z "$field7" ] && [ -z "$field6" ]; then
            # Old format (5 fields): REPO_ID|URL|LABEL|DESC|ENABLED
            category="drivers"
            display_mode="toplevel"
            enabled="$field5"
        elif [ -z "$field7" ]; then
            # Medium format (6 fields): REPO_ID|URL|LABEL|DESC|CATEGORY|ENABLED
            category="$field5"
            display_mode="category"
            enabled="$field6"
        else
            # New format (7 fields): REPO_ID|URL|LABEL|DESC|CATEGORY|DISPLAY_MODE|ENABLED
            category="$field5"
            display_mode="$field6"
            enabled="$field7"
        fi
        
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
        REPOS_CATEGORIES["$repo_id"]="$category"
        REPOS_DISPLAY_MODE["$repo_id"]="${display_mode:-category}"
        
        count=$((count + 1))
        
        local display_icon
        if [ "$display_mode" = "toplevel" ]; then
            display_icon="📌"
        else
            display_icon="📁"
        fi
        
        if [ "${enabled:-true}" = "true" ]; then
            enabled_count=$((enabled_count + 1))
            echo_info "  ✅ $display_icon $label ($repo_id) [$category/$display_mode]"
        else
            echo_warn "  ⏸️  $display_icon $label ($repo_id) [$category/$display_mode] - deactivated"
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
        
        # Support 5, 6, or 7 field format
        if len(parts) == 5:
            # Old format: REPO_ID|REPO_URL|LABEL|DESCRIPTION|ENABLED
            repo_id = parts[0].strip()
            repo_url = parts[1].strip()
            label = parts[2].strip()
            description = parts[3].strip()
            category = 'drivers'
            display_mode = 'toplevel'
            enabled = parts[4].strip().lower() == 'true'
        elif len(parts) == 6:
            # Medium format: REPO_ID|REPO_URL|LABEL|DESCRIPTION|CATEGORY|ENABLED
            repo_id = parts[0].strip()
            repo_url = parts[1].strip()
            label = parts[2].strip()
            description = parts[3].strip()
            category = parts[4].strip()
            display_mode = 'category'
            enabled = parts[5].strip().lower() == 'true'
        elif len(parts) == 7:
            # New format: REPO_ID|REPO_URL|LABEL|DESCRIPTION|CATEGORY|DISPLAY_MODE|ENABLED
            repo_id = parts[0].strip()
            repo_url = parts[1].strip()
            label = parts[2].strip()
            description = parts[3].strip()
            category = parts[4].strip()
            display_mode = parts[5].strip()
            enabled = parts[6].strip().lower() == 'true'
        else:
            print(f"⚠️  Skipping invalid line (expected 5, 6, or 7 fields): {line}")
            continue
        
        # Remove .git suffix if present
        github_url = repo_url.replace('.git', '')
        
        repos_data.append({
            "id": repo_id,
            "label": label,
            "description": description,
            "category": category,
            "displayMode": display_mode,
            "editUrl": f"{github_url}/tree/main/",
            "githubUrl": github_url,
            "enabled": enabled
        })

# Configuration with categories
config = {
    "repositories": repos_data,
    "settings": {
        "categories": [
            {
                "id": "drivers",
                "label": "🔧 Hardware Drivers",
                "icon": "🔧",
                "description": "Low-level peripheral drivers for ESP32",
                "position": "left"
            },
            {
                "id": "projects",
                "label": "🎵 Projects",
                "icon": "🎵",
                "description": "Complete IoT applications and examples",
                "position": "left"
            },
            {
                "id": "hardware",
                "label": "🏗️ Hardware",
                "icon": "🏗️",
                "description": "PCB designs and 3D printable models",
                "position": "left"
            },
            {
                "id": "docs",
                "label": "📚 Documentation",
                "icon": "📚",
                "description": "Guides, tutorials, and references",
                "position": "left"
            }
        ],
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

# Write to docusaurus-config.json
with open('docusaurus-config.json', 'w') as f:
    json.dump(config, f, indent=2)

# Summary
print(f"✅ Generated config with {len(repos_data)} repositories")
print(f"\n📊 Repositories by display mode:")

toplevel_repos = [r for r in repos_data if r['displayMode'] == 'toplevel']
category_repos = [r for r in repos_data if r['displayMode'] == 'category']

if toplevel_repos:
    print(f"\n   📌 Top-Level ({len(toplevel_repos)}):")
    for repo in toplevel_repos:
        status = "✅" if repo['enabled'] else "⏸️"
        print(f"      {status} {repo['label']} ({repo['id']})")

if category_repos:
    print(f"\n   📁 In Categories ({len(category_repos)}):")
    categories = {}
    for repo in category_repos:
        cat = repo['category']
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(repo)
    
    for cat, repos in sorted(categories.items()):
        enabled_count = sum(1 for r in repos if r['enabled'])
        print(f"\n      {cat}: {len(repos)} repos ({enabled_count} enabled)")
        for repo in repos:
            status = "✅" if repo['enabled'] else "⏸️"
            print(f"         {status} {repo['label']}")

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
# Format: REPO_ID|REPO_URL|LABEL|DESCRIPTION|CATEGORY|DISPLAY_MODE|ENABLED
#
# DISPLAY_MODE: 
#   - "toplevel" = Direkt in Navbar (eigenständiger Link)
#   - "category" = In Kategorie-Dropdown
# CATEGORY: drivers, projects, hardware, docs

# Top-Level (direkt sichtbar)
wb-idf-core|https://github.com/WhirlingBits/wb-idf-core|Core Library|Core functionality and base components|drivers|toplevel|true

# In Category-Dropdowns
wb-idf-i2c|https://github.com/WhirlingBits/wb-idf-core|I²C Driver|I²C communication|drivers|category|false
EOF
    
    echo_info "Template configuration created: $REPOS_CONFIG_FILE"
}

cleanup_temp_files() {
    echo_step "Cleaning up temporary files..."
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
    
    if ls *.log 1> /dev/null 2>&1; then
        rm -f *.log
        ((cleaned++))
    fi
    
    [ -f "${DOCUSAURUS_CONFIG_FILE}.backup" ] && rm -f "${DOCUSAURUS_CONFIG_FILE}.backup"
    [ -f "sidebars.js" ] && rm -f "sidebars.js" && ((cleaned++))
    [ -f "sidebars.json" ] && rm -f "sidebars.json" && ((cleaned++))
    
    [ $cleaned -gt 0 ] && echo_info "✅ $cleaned cleanup operations"
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

    local layout_file="$repo_dir/DoxygenLayout.xml"
    local use_doxygen_layout=false
    
    if [ -f "$layout_file" ]; then
        use_doxygen_layout=true
        echo_debug "Found DoxygenLayout.xml - using Doxygen structure"
    else
        echo_debug "No DoxygenLayout.xml - using flat structure"
    fi

    local md_files=()
    while IFS= read -r -d '' file; do
        local basename=$(basename "$file" .md)
        [ "$basename" = "index" ] && continue
        [ "$basename" = "versions" ] && continue
        md_files+=("$basename")
    done < <(find "$target_dir" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)
    
    IFS=$'\n' md_files=($(sort <<<"${md_files[*]}"))
    unset IFS
    
    echo_debug "Found ${#md_files[@]} markdown files (excluding index/versions)"
    
    local sidebar_file
    if [ "$version" = "current" ]; then
        sidebar_file="$repo_name/sidebars.json"
    else
        mkdir -p "${repo_name}_versioned_sidebars"
        sidebar_file="${repo_name}_versioned_sidebars/version-$version-sidebars.json"
    fi
    
    cat > "$sidebar_file" << 'EOF'
{
  "apiSidebar": [
    {
      "type": "doc",
      "id": "index",
      "label": "Overview"
    }
EOF
    
    if [ ${#md_files[@]} -gt 0 ]; then
        if [ "$use_doxygen_layout" = true ]; then
            echo "," >> "$sidebar_file"
        else
            cat >> "$sidebar_file" << 'EOF'
,
    {
      "type": "category",
      "label": "API Reference",
      "collapsed": false,
      "items": [
EOF
        fi
        
        if [ "$use_doxygen_layout" = true ]; then
            echo
            export TARGET_DIR="$target_dir"
            export LAYOUT_FILE="$layout_file"
            
            python3 << 'PYTHON_EOF' >> "$sidebar_file"
import xml.etree.ElementTree as ET
import sys
import os
import re
import json

target_dir = os.environ['TARGET_DIR']
layout_file = os.environ['LAYOUT_FILE']

md_files = []
try:
    for f in os.listdir(target_dir):
        if f.endswith('.md') or f.endswith('.mdx'):
            basename = os.path.splitext(f)[0]
            if basename not in ['index', 'versions']:
                md_files.append(basename)
    md_files.sort()
except Exception as e:
    sys.stderr.write(f"Error listing dir: {e}\n")

used_files = set()
sidebar_items = []

def get_frontmatter_title(file_path):
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
            in_fm = False
            for line in lines:
                if line.strip() == '---':
                    if in_fm: break
                    in_fm = True
                    continue
                if in_fm and line.strip().startswith('title:'):
                    return line.strip().split(':', 1)[1].strip().strip('"\'')
    except:
        pass
    return None

def find_md_file(ref):
    if ref in md_files:
        return ref
    for f in md_files:
        if ref in f:
            return f
    return None

def process_tab(tab):
    visible = tab.get('visible', 'yes')
    if visible != 'yes':
        return None
    
    title = tab.get('title', '')
    url = tab.get('url', '')
    
    item = None
    
    ref_match = re.search(r'@ref\s+(\w+)', url)
    if ref_match:
        ref = ref_match.group(1)
        md_file = find_md_file(ref)
        
        if md_file:
            used_files.add(md_file)
            fm_title = get_frontmatter_title(os.path.join(target_dir, md_file + '.md'))
            label = title if title else (fm_title if fm_title else md_file.replace('wb_idf_', '').replace('_', ' ').title())
            
            item = {
                "type": "doc",
                "id": md_file,
                "label": label
            }
    
    subtabs = tab.findall('tab')
    children = []
    for subtab in subtabs:
        child = process_tab(subtab)
        if child:
            children.append(child)
            
    if children:
        cat = {
            "type": "category",
            "label": title if title else "Group",
            "items": children,
            "collapsed": False
        }
        if item:
            cat["link"] = {
                "type": "doc",
                "id": item["id"]
            }
            if not title:
                cat["label"] = item["label"]
        return cat
    
    return item

try:
    tree = ET.parse(layout_file)
    root = tree.getroot()
    navindex = root.find('.//navindex')
    
    if navindex:
        for tab in navindex.findall('tab'):
            item = process_tab(tab)
            if item:
                sidebar_items.append(item)

except Exception as e:
    sys.stderr.write(f"Error parsing layout: {e}\n")

for f in md_files:
    if f not in used_files:
        fm_title = get_frontmatter_title(os.path.join(target_dir, f + '.md'))
        label = fm_title if fm_title else f.replace('wb_idf_', '').replace('_', ' ').title()
        sidebar_items.append({
            "type": "doc",
            "id": f,
            "label": label
        })

if sidebar_items:
    print(",\n".join(json.dumps(item, indent=2) for item in sidebar_items))
PYTHON_EOF
        else
            echo_debug "Using flat structure (no DoxygenLayout.xml)..."
            
            local first=true
            for md_file in "${md_files[@]}"; do
                [ "$first" = false ] && echo "," >> "$sidebar_file"
                first=false

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
        
        if [ "$use_doxygen_layout" = false ]; then
            cat >> "$sidebar_file" << 'EOF'

      ]
    }
EOF
        fi
    fi

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
    
    [ "${REPOS_ENABLED[$repo_name]}" != "true" ] && echo_warn "Skipping $repo_name" && return 0
    
    local label="${REPOS_LABELS[$repo_name]}"
    
    echo ""
    echo "═══════════════════════════════════════════════════"
    echo_step "Processing: $label ($repo_name) - Version: $version"
    echo "═══════════════════════════════════════════════════"
    
    local repo_dir="repos/$repo_name"
    
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
        echo_error "XML missing"
        return 1
    fi
    
    local xml_count=$(find "$repo_dir/doxygen/xml" -name "*.xml" 2>/dev/null | wc -l)
    echo_info "✅ $xml_count XML files"
    
    local target_dir
    if [ "$version" = "current" ]; then
        target_dir="$repo_name"
    else
        target_dir="${repo_name}_versioned_docs/version-$version"
    fi
    
    echo_debug "Target: $target_dir"
    mkdir -p "$target_dir"
    
    if [ ! -f "doxygen_to_markdown.py" ]; then
        echo_error "doxygen_to_markdown.py not found"
        return 1
    fi
    
    local layout_arg=""
    if [ -f "$repo_dir/DoxygenLayout.xml" ]; then
        layout_arg="--layout $repo_dir/DoxygenLayout.xml"
        echo_debug "Using DoxygenLayout.xml for structure"
    fi
    
    local py_output
    py_output=$(python3 doxygen_to_markdown.py \
        --xml-dir "$repo_dir/doxygen/xml" \
        --output "$target_dir" \
        --format docusaurus \
        $layout_arg 2>&1)
    local py_exit=$?
    
    echo "$py_output" | grep -v "Processing"
    
    if [ $py_exit -ne 0 ]; then
        echo_error "Conversion failed (Exit: $py_exit)"
        return 1
    fi
    
    if [ -d "$target_dir/api" ]; then
        find "$target_dir/api" -maxdepth 1 -type f -exec mv {} "$target_dir/" \; 2>/dev/null
        rmdir "$target_dir/api" 2>/dev/null || true
    fi
    
    for file in "$target_dir"/*; do
        if [ -f "$file" ] && [[ ! "$file" =~ \.(md|mdx|json)$ ]]; then
            if file "$file" | grep -q "text"; then
                mv "$file" "${file}.md"
            fi
        fi
    done
    
    local md_count=$(find "$target_dir" -maxdepth 1 -type f \( -name "*.md" -o -name "*.mdx" \) 2>/dev/null | wc -l)
    
    if [ $md_count -eq 0 ]; then
        echo_error "No Markdown files found in $target_dir"
        return 1
    fi
    
    if [ -d "$target_dir/groups" ]; then
        mv "$target_dir/groups/"* "$target_dir/" 2>/dev/null
        rmdir "$target_dir/groups" 2>/dev/null || true
        
        find "$target_dir" -maxdepth 1 -type f \( -name "*.mdx" -o -name "*.md" \) -exec sed -i \
            -e 's|id: groups/|id: |g' \
            -e 's|](groups/|](|g' \
            {} + 2>/dev/null
    fi
    
    for unwanted in files directories namespaces classes api; do
        [ -d "$target_dir/$unwanted" ] && rm -rf "$target_dir/$unwanted"
    done
    
    find "$target_dir" -maxdepth 1 -type f \( -name "*.mdx" -o -name "*.md" \) -exec sed -i \
        -e '/<!--truncate-->/d' \
        -e '/<!--more-->/d' \
        -e 's/<a href="#[^"]*">More\.\.\.<\/a>//g' \
        {} + 2>/dev/null
    
    generate_sidebar_from_markdown "$target_dir" "$repo_name" "$version"
    
    echo_info "✅ $label ($version): $md_count modules"
    return 0
}

main() {
    echo "═══════════════════════════════════════════════════"
    echo_info "WhirlingBits Documentation Generator v3.4"
    echo_info "Multi-Instance + Categories + Display Modes"
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

        if [ -n "$released_versions" ]; then
            echo_debug "Creating versions.json with: $released_versions"
            create_versions_json "$repo_name" "$released_versions"
            
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
    echo_info "🎯 Multi-Instance Structure (with Categories):"
    for repo_name in "${!REPOS[@]}"; do
        [ "${REPOS_ENABLED[$repo_name]}" != "true" ] && continue
        
        local display_mode="${REPOS_DISPLAY_MODE[$repo_name]}"
        local category="${REPOS_CATEGORIES[$repo_name]}"
        local display_icon="📌"
        [ "$display_mode" = "category" ] && display_icon="📁"
        
        echo ""
        echo "   $display_icon $repo_name/ (current) [$category/$display_mode]"
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