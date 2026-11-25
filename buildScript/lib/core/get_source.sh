#!/bin/bash
set -e

source "buildScript/init/env.sh"
ENV_NB4A=1
source "buildScript/lib/core/get_source_env.sh"
pushd ..

####

# ensure_repo <目录> <仓库地址> <提交>
# 目录不存在则克隆；已存在则只做增量获取，且保留用户当前分支与未提交的改动。
ensure_repo() {
  local dir="$1" url="$2" commit="$3"

  if [ ! -d "$dir" ]; then
    git clone --no-checkout "$url" "$dir"
  elif [ ! -d "$dir/.git" ]; then
    echo "错误：$dir 已存在但不是 git 仓库，请手动处理后再运行。" >&2
    exit 1
  fi

  pushd "$dir"
  local origin
  origin="$(git remote get-url origin 2>/dev/null || true)"
  if [ -n "$origin" ] && [ "$origin" != "$url" ]; then
    echo "注意：$dir 的 origin 是 $origin，与期望的 $url 不同；仍从期望地址取提交。" >&2
  fi

  if git cat-file -e "$commit^{commit}" 2>/dev/null; then
    echo "$dir: 已包含提交 $commit"
  else
    git fetch --tags "$url" || true
    if ! git cat-file -e "$commit^{commit}" 2>/dev/null; then
      echo "错误：$dir 中找不到提交 $commit（$url）。" >&2
      echo "若该目录是浅克隆，请先执行：git -C $dir fetch --unshallow --tags $url" >&2
      exit 1
    fi
  fi

  # 已在目标提交上则不动，避免把用户自己的分支/工作区切换成游离 HEAD
  if [ "$(git rev-parse HEAD)" = "$(git rev-parse "$commit^{commit}")" ]; then
    echo "$dir: 当前 HEAD 已是 $commit，跳过切换"
  elif [ -n "$(git status --porcelain)" ]; then
    echo "错误：$dir 有未提交的改动，拒绝切换到 $commit。请先提交或 stash。" >&2
    exit 1
  else
    git checkout "$commit"
  fi
  popd
}

####

ensure_repo "sing-box" "$URL_SING_BOX" "$COMMIT_SING_BOX"

####

ensure_repo "sing" "$URL_SING" "$COMMIT_SING"

####

ensure_repo "libneko" "$URL_LIBNEKO" "$COMMIT_LIBNEKO"

####

popd
