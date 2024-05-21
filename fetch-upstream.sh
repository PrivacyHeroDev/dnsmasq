#!/bin/bash
set -e

openwrt_tag="${1}"
regex_patch_branch="${2}"

if [ -z "${openwrt_tag}" ] || [ -z "${regex_patch_branch}" ]; then
    echo "Usage: $0 <openwrt_tag> <regex_patch_branch>"
    exit 1
fi


git remote add upstream https://thekelleys.org.uk/git/dnsmasq.git || true

# Create a directory for the patch repo
patch_repo_dir=$(mktemp -d)
echo "Using ${patch_repo_dir} as the patch repo directory"
pushd "${patch_repo_dir}"
git clone https://github.com/lixingcong/dnsmasq-regex-openwrt.git --branch "${regex_patch_branch}" .
regex_patch_commit="$(git rev-parse HEAD)"
popd

branch_name="dnsmasq-${openwrt_tag}/patches-${regex_patch_commit}"

worktree_dir=$(mktemp -d)

# Create a new worktree
git worktree add "${worktree_dir}" upstream/master
pushd "${worktree_dir}"

# Create a new branch from upstream dnsmasq
git branch --delete "${branch_name}" || true
git checkout -b "${branch_name}" "${openwrt_tag}"

# Apply the patches
git apply "${patch_repo_dir}/patches/"*.patch
git commit -am "Apply regex/openwrt patches from ${regex_patch_commit}"
git tag "${branch_name}"

# Remove the worktree
popd
git worktree remove "${worktree_dir}"
