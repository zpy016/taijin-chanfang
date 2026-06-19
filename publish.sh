#!/usr/bin/env bash
# 发布脚本：把最新版本 数字禅房vN.html 提升为 index.html 并推送到 GitHub
# 用法：编辑/新建好 数字禅房vN.html 后，在本目录运行  ./publish.sh
#
# 约定：永远只编辑版本文件（数字禅房vN.html），不要直接改 index.html。
#       index.html 是"当前线上版"的派生产物，由本脚本维护。
set -euo pipefail
cd "$(dirname "$0")"

# 1. 找出版本号最大的 数字禅房vN.html（_副本 / 未归档 等带后缀的不算正式版本）
latest=$(ls 数字禅房v*.html 2>/dev/null \
  | sed -E 's/^数字禅房v([0-9]+)\.html$/\1\t&/' \
  | sort -n | tail -1 | cut -f2-)

if [ -z "$latest" ]; then
  echo "❌ 未找到 数字禅房v*.html"; exit 1
fi
echo "📦 最新版本文件：$latest"

# 2. 若 index.html 已是该版本，跳过复制
if [ -f index.html ] && cmp -s "$latest" index.html; then
  echo "ℹ️  index.html 已是 $latest，无需更新"
else
  # 3. 发布前确认：旧 index.html 内容是否已被某个版本文件保存
  #    （即"原来的 index.html 改回之前的版本"——它本就以 数字禅房vN.html 留存）
  preserved=false
  while IFS= read -r f; do
    [ -f index.html ] && cmp -s index.html "$f" && { preserved=true; break; }
  done < <(ls 数字禅房v*.html 2>/dev/null)
  if [ "$preserved" = false ] && [ -f index.html ]; then
    bak="数字禅房v_未归档_$(date +%Y%m%d_%H%M%S).html"
    cp index.html "$bak"
    echo "⚠️  旧 index.html 未匹配任何版本文件，已备份为 $bak"
  fi
  cp "$latest" index.html
  echo "✅ 已将 $latest 复制为 index.html"
fi

# 4. 提交并推送
git add index.html "$latest"
if git diff --cached --quiet; then
  echo "ℹ️  没有需要提交的改动"
else
  git commit -m "publish: $latest → index.html"
fi
git push
echo "🚀 已推送到 GitHub"
