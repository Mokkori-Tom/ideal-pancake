#project_root
#!/bin/bash
git config --global core.autocrlf false
# 変更箇所をステージングする
git add .

# 変更されたファイルやディレクトリをリストアップする
changes=$(git diff --name-only --cached)

if [ -z "$changes" ]; then
    echo "No changes to commit."
else
    # コミットメッセージを変更ファイルに基づいて生成する
    commit_message="Auto commit of changes: $changes"
    git commit -m "$commit_message"
fi
