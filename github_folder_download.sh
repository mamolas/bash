#!/bin/bash

set -x  # Enable debugging output

urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * )               printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}

download_folder() {
    local path="$1"
    local encoded_path=$(urlencode "$path")
    local api_url="https://api.github.com/repos/$owner/$repo/contents/$encoded_path?ref=$commit"
    local response=$(curl -sS -H "Accept: application/vnd.github.v3+json" "$api_url")

    echo "$response" | jq -r '.[] | @base64' | while read -r item; do
        decoded=$(echo $item | base64 --decode)
        name=$(echo $decoded | jq -r '.name')
        item_type=$(echo $decoded | jq -r '.type')
        download_url=$(echo $decoded | jq -r '.download_url')

        if [ "$item_type" == "file" ]; then
            echo "Downloading: $name"
            curl -sS -O "$download_url"
        elif [ "$item_type" == "dir" ]; then
            echo "Entering directory: $name"
            mkdir -p "$name"
            (cd "$name" && download_folder "$path/$name")
        fi
    done
}

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <github_permalink>"
    exit 1
fi

# Extract owner, repo, commit, and path from the permalink
permalink=$1
owner=$(echo $permalink | cut -d'/' -f4)
repo=$(echo $permalink | cut -d'/' -f5)
commit=$(echo $permalink | cut -d'/' -f7)
path=$(echo $permalink | cut -d'/' -f8- | sed 's/%20/ /g')

echo "Owner: $owner"
echo "Repo: $repo"
echo "Commit: $commit"
echo "Path: $path"

# Create and enter the target directory
target_dir=$(basename "$path")
mkdir -p "$target_dir"
cd "$target_dir"
echo "Current directory: $(pwd)"

# Start the recursive download
download_folder "$path"

echo "Script completed. Files have been downloaded to: $(pwd)"
