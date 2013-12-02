#

sed  -e  "/boundary/,/^);/ {s/boundary/patches/;/faces/d;/{/d;/}/d;/type/d;s/\t);/\t)/;s/\s\{1,\}\([a-zA-Z]\{1,\}\)/\t\tpatch\t\1/};s/\t//" blockMeshDict
echo "ready to proceed?"
read -r
cp blockMeshDict blockMeshDict~
sed  -i  "/boundary/,/^);/ {s/boundary/patches/;/faces/d;/{/d;/}/d;/type/d;s/\t);/\t)/;s/\s\{1,\}\([a-zA-Z]\{1,\}\)/\t\tpatch\t\1/};s/\t//" blockMeshDict
