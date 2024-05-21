#!/bin/bash
set -e

cleanup_commands=""

cleanup() {
  echo "Cleaning up"
  eval "${cleanup_commands}"
}

add_cleanup_command() {
  cleanup_commands="${cleanup_commands} ${1};"
}

trap cleanup EXIT

readonly openwrt_tag="${1}"
readonly regex_patch_branch="${2}"

if [ -z "${openwrt_tag}" ] || [ -z "${regex_patch_branch}" ]; then
    echo "Usage: ${0} <openwrt_tag> <regex_patch_branch>"
    exit 1
fi


git remote add upstream https://thekelleys.org.uk/git/dnsmasq.git || true

# Create a directory for the patch repo
patch_repo_dir=$(mktemp -d)
readonly patch_repo_dir
add_cleanup_command 'rm -rf "${patch_repo_dir}"'

pushd "${patch_repo_dir}"
git clone https://github.com/lixingcong/dnsmasq-regex-openwrt.git --branch "${regex_patch_branch}" .
regex_patch_commit="$(git rev-parse HEAD)"
readonly regex_patch_commit
popd

readonly tag_name="dnsmasq-${openwrt_tag}/patches-${regex_patch_commit}"

worktree_dir=$(mktemp -d)
readonly worktree_dir
add_cleanup_command 'rm -rf "${worktree_dir}"'

# Create a new worktree
git worktree add "${worktree_dir}" upstream/master
add_cleanup_command 'git worktree remove "${worktree_dir}"'

pushd "${worktree_dir}"
echo "Create a new branch from upstream dnsmasq"
git branch -D "${tag_name}" || true
git checkout -b "${tag_name}" "${openwrt_tag}"
add_cleanup_command 'git branch -D "${tag_name}"'

echo "Apply the patches"
git apply "${patch_repo_dir}/patches/"*.patch
git commit -am "Apply regex/openwrt patches from ${regex_patch_commit}"

echo "Create the tag ${tag_name}"
git tag "${tag_name}" || true
popd

echo "Done. You can branch off the tag ${tag_name}."
