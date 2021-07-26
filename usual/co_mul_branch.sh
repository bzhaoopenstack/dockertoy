git fetch upstream






for i in `git branch -a | grep upstream | grep -v CVE | grep -v master | grep -v openEuler1`;
do
branch_name=`echo $i | sed -r 's#\S+\/\S+\/##g'`
git checkout $i -b $branch_name
done
