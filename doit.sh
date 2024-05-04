if [ $# -eq 0 ]; then
echo doit.sh \<major\> \<minor-from\> \<minor-to\>
exit 0
fi
pushd binaries
for name in *\-$1.$3*
do
  cp ../drools-distribution-$1.$3.0.Final/binaries/${name/$1.$2/$1.$3} .
done
popd
