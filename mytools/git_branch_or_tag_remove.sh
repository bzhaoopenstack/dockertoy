# 批量删除git branch和tag
git branch -r | awk -F/ '/\/release/{print $2}' | xargs -I {} git push origin :{}

git tag -l | xargs -n 1 git push --delete origin
