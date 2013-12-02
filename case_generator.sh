# /bin/bash 
# viv_case_generator.sh
# This is used to generate CFD case files of VIV simulations.
# Usage: case_generator [config file] [n_cylinders]
#   Arguments can be combined in any order, 
#     If [n_cylinders] is not specified, it will be set to the default value in the configuration file.
#     If [config file] is not specified, default configuration file specified in ./setup/default will be used.
# Written by Zhiyao Wang, zhiyao@umich.edu, July 2013.

############################ SECTION I ############################
#------------ introduction
# I)  Boundary naming rule of general grid interface (GGI) pairs in accordance with number of cylinders:
#    _________________________________________________________________________
# ->|                |        |    |        |             |                   |
# ->|                |        |    |        |             |                   |
# ->|                |        |    |        |             |                   |
# ->|                |        |    |        |             |                   |
# ->|                |        |    |        |             |                   |
# ->|    upstream    |  cyl1  |    |  cyl2  |    ... ...  |    downstream     |
# ->|                |        |    |        |             |                   |
# ->|                |        |    |        |             |                   |
# ->|                |        |    |        |             |                   |
# ->|                |        |    |        |             |                   |
# ->|                |        |    |        |             |                   |
# ->|________________|________|____|________|_____________|___________________|
# inlet            ggi1     ggi2  ggi3     ggi4  ... ...                   outlet
#                 in out   in out in out  in out ... ...
# 
# 
# II) A brief instruction to pre-process OpenFOAM case files:
# 
# 1) Generate OpenFOAM mesh.
#     Merge the mesh of flow domain with blocks containing the cylinder using 'mergeMeshes' command, making sure GGI faces are independent even if they are overlapped.
# 
# 2) Make modifications to the following files.
#     In 'constant\dynamicMeshDict', modify physical parameters including k, m and c for each cylinder.
#     In 'system\controlDict', modify parameters for calculating drag and lift coefficients of each cylinder.
#     In 'constant\polyMesh\boundary', specify pairing information for each GGI face.
#     In 'system\cellSetDict' and 'system\setBatch', define moving and fixed mesh regions according to the position of each cylinder.
#     In the files of nut, nuTilda, p, U in '0' folder, specify boundary conditions for initial time based on the number of cylinders.
# 
# 3) Run the following commands.
#     cellSet	
#     setSet -batch setBatch
#     setsToZones
#     setFields
#     transformPoints -scale "(disired scale)"		


############################ SECTION II ############################
#------------ function definitions
function evaluate() { echo "scale=10;$1" | bc; }

function dict_read() {
    local _filename=$1
    local _dictname=$2
    echo `egrep "^\s*\<${_dictname}\>" ${_filename}|sed "s/#.*$//g"|sed "s/[=:]/ /g"|awk -F" " '{print($2,$3,$4,$5)}'|sed "s/[,'\"]/ /g"`
}
function dict_write() {
    local _filename=$1
    local _dictname=$2
    local _dictvalue=$3
    local _locator=$4
    if [ -z $_locator ]; then _locator=".*"; fi
    sed -i "/$_locator/ s/\<${_dictname}\>\s\{1,\}[-0-9a-zA-Z.\"]\{1,\}\s*/${_dictname}\t${_dictvalue} /" ${_filename}
}

function createMesh() { 
#createMesh "./tmp2/constant/polyMesh/blockMeshDict.org" "rec_dom_mid" "min_grid" "grad"
_mesh_solver="./support/src/meshSpaceCalculator"
_casedir=`echo $1|sed 's=/constant/polyMesh.*$==g'`
_destination=$_casedir/constant/polyMesh/blockMeshDict
cp $1 $_destination 
_YT=`echo $2|awk -F"," '{print($1)}'`	#boundary postion
_YB=`echo $2|awk -F"," '{print($2)}'`
_XL=`echo $2|awk -F"," '{print($3)}'`
_XR=`echo $2|awk -F"," '{print($4)}'`
_ZF=`echo $2|awk -F"," '{print($5)}'`
_ZB=`echo $2|awk -F"," '{print($6)}'`
_YCT=`echo $2|awk -F"," '{print($7)}'`
_YCB=`echo $2|awk -F"," '{print($8)}'`
_YIT=`evaluate "(($_YT)+($_YCT))/2"`
_YIB=`evaluate "(($_YB)+($_YCB))/2"`
_mg=$3	#min grid size
_LX=`evaluate "($_XR)-($_XL)"`	#length of each side
_LYT=`evaluate "(($_YT)-($_YCT))/2"`
_LYC=`evaluate "($_YCT)-($_YCB)"`
_LYB=`evaluate "(($_YCB)-($_YB))/2"`
_LZ=`evaluate "($_ZF)-($_ZB)"`
_GX=`echo $4|awk -F"," '{print($1)}'|bc`	#expansion ratio at each side
_GY=`echo $4|awk -F"," '{print($2)}'|bc`
_GZ=1	#grad in z-direction is not allowed in this version
if [ `echo "$_GY 1.0" | awk '{if($1<$2) {print 0} else {print 1}}'` -eq "0" ]
 then _GY=`evaluate "1/$_GY"`; fi	#ensure GY>=1
_GYTU=`evaluate "1/$_GY"`
_GYTD=$_GY
_GYC=1
_GYBU=$_GYTU
_GYBD=$_GYTD
sed -i "s/\<XL/$_XL/g" $_destination	#write to blockMeshDict
sed -i "s/\<XR/$_XR/g" $_destination 
sed -i "s/\<YT/$_YT/g" $_destination 
sed -i "s/\<YIT/$_YIT/g" $_destination 
sed -i "s/\<YCT/$_YCT/g" $_destination 
sed -i "s/\<YCB/$_YCB/g" $_destination 
sed -i "s/\<YIB/$_YIB/g" $_destination 
sed -i "s/\<YB/$_YB/g" $_destination 
sed -i "s/\<ZB/$_ZB/g" $_destination 
sed -i "s/\<ZF/$_ZF/g" $_destination 
sed -i "s/\<GX/$_GX/g" $_destination 
sed -i "s/\<GYTU/$_GYTU/g" $_destination 
sed -i "s/\<GYTD/$_GYTD/g" $_destination 
sed -i "s/\<GYC/$_GYC/g" $_destination 
sed -i "s/\<GYBU/$_GYBU/g" $_destination 
sed -i "s/\<GYBD/$_GYBD/g" $_destination 
sed -i "s/\<GZ/$_GZ/g" $_destination 
if [ `echo "$_GX 1.0" | awk '{if($1<=$2) {print 0} else {print 1}}'` -eq "0" ]; then _GX=`evaluate "1/$_GX+0.000001"`; fi	#make grad>1 (=1 is not allowed by the solver) for further process
if [ `echo "$_GY 1.0" | awk '{if($1==$2) {print 0} else {print 1}}'` -eq "0" ]; then _GY=`evaluate "1/$_GY+0.000001"`; fi	#ensure GY>1
_DX=`$_mesh_solver ds r $_LX $_mg $_GX|grep '\<n'|sed 's/^.*: //g'`
_DYT=`$_mesh_solver ds r $_LYT $_mg $_GY|grep '\<n'|sed 's/^.*: //g'`
_DYC=`$_mesh_solver ds r $_LYC $_mg 1.000001|grep '\<n'|sed 's/^.*: //g'`
_DYB=`$_mesh_solver ds r $_LYB $_mg $_GY|grep '\<n'|sed 's/^.*: //g'`
_DZ=1;
sed -i "s/\<DX/$_DX/g" $_destination 
sed -i "s/\<DYT/$_DYT/g" $_destination 
sed -i "s/\<DYC/$_DYC/g" $_destination 
sed -i "s/\<DYB/$_DYB/g" $_destination 
sed -i "s/\<DZ/$_DZ/g" $_destination 
blockMesh -case $_casedir
}
function vadd() { #C=`vadd "$A" "-$B" "-(1 -2 3)" ...` 
_index=1
_vx[0]=0; _vy[0]=0; _vz[0]=0
_filter='s/["+]//g;s/^.*(//g;s/).*$//g;s/[\s ]\{1,\}/,/g'
for loop; do
	_vx[$_index]=`echo $loop |sed "$_filter"|awk -F"," '{print($1)}'`
	_vy[$_index]=`echo $loop |sed "$_filter"|awk -F"," '{print($2)}'`
	_vz[$_index]=`echo $loop |sed "$_filter"|awk -F"," '{print($3)}'`
	_vs[$_index]=`echo $loop |sed 's/["]//g;s/[+]*(.*)//g'`
	_vx[0]=`evaluate "${_vx[0]}+(${_vs[$_index]}(${_vx[$_index]}))"`
	_vy[0]=`evaluate "${_vy[0]}+(${_vs[$_index]}(${_vy[$_index]}))"`
	_vz[0]=`evaluate "${_vz[0]}+(${_vs[$_index]}(${_vz[$_index]}))"`
	_index=`expr $_index + 1`
done
_result="(${_vx[0]} ${_vy[0]} ${_vz[0]})"
echo $_result
}
function rec() { 
#C=`rec "$A+$B;$C-$D;(1 2 3)+(4 5 6);-(1 2 3);(0 0 0);(0 0 1);(0 0 0);(0 0 0)"` 
_filter='s/\([0-9.]\{1,\}\)[\s ]\{1,\}/\1,/g;s/)/) /g'
_1=`echo $1|sed "$_filter"|awk -F";" '{print($1)}'`
_2=`echo $1|sed "$_filter"|awk -F";" '{print($2)}'`
_3=`echo $1|sed "$_filter"|awk -F";" '{print($3)}'`
_4=`echo $1|sed "$_filter"|awk -F";" '{print($4)}'`
_5=`echo $1|sed "$_filter"|awk -F";" '{print($5)}'`
_6=`echo $1|sed "$_filter"|awk -F";" '{print($6)}'`
_7=`echo $1|sed "$_filter"|awk -F";" '{print($7)}'`
_8=`echo $1|sed "$_filter"|awk -F";" '{print($8)}'`
_top=`vadd $_1|sed 's/[()]//g'|awk '{print($2)}'`
_bottom=`vadd $_2|sed 's/[()]//g'|awk '{print($2)}'`
_left=`vadd $_3|sed 's/[()]//g'|awk '{print($1)}'`
_right=`vadd $_4|sed 's/[()]//g'|awk '{print($1)}'`
_front=`vadd $_5|sed 's/[()]//g'|awk '{print($3)}'`
_back=`vadd $_6|sed 's/[()]//g'|awk '{print($3)}'`
_ctop=`vadd $_7|sed 's/[()]//g'|awk '{print($2)}'`
_cbot=`vadd $_8|sed 's/[()]//g'|awk '{print($2)}'`
echo "$_top,$_bottom,$_left,$_right,$_front,$_back,$_ctop,$_cbot"
}

############################ SECTION III ############################
#------------ the start of the process
default_setup_file=`dict_read "./setup/default" "default_configuration_file"`
if [ -z "$1" ]; then
    n_cyl=0; setup=$default_setup_file;
else
    case $1 in
        1|2|3|4)	
            n_cyl=$1; setup=$default_setup_file ;;
        *)	
            n_cyl=0; setup=$1 ;;
    esac
fi
if [ -n "$2" ]; then
    case $2 in
        1|2|3|4)	n_cyl=$2 ;;
        *)	setup=$2 ;;
    esac
fi
common_prototype_folder="./support/template/common" # prototype folder name with common files
mesh_path="./support/mesh"
temp_result_folder_name=tmp # temporary result folder name
max_cylinder_capacity=4	# should be enough, see comments if you want to change this limit

#------------ read parameters from setup file
maxCo=`dict_read "$setup" "maxCo"`
nu=`dict_read "$setup" "nu"`
d=`dict_read "$setup" "d"`
minThickness=`dict_read "$setup" "minThickness"`
maxThickness=`dict_read "$setup" "maxThickness"`

block_cyl[1]=`dict_read "$setup" "shape1"`
block_cyl[2]=`dict_read "$setup" "shape2"`
block_cyl[3]=`dict_read "$setup" "shape3"`
block_cyl[4]=`dict_read "$setup" "shape4"`
dim_cyl[1]=`dict_read "$setup" "blockWidth1"`
dim_cyl[2]=`dict_read "$setup" "blockWidth2"`
dim_cyl[3]=`dict_read "$setup" "blockWidth3"`
dim_cyl[4]=`dict_read "$setup" "blockWidth4"`
pos_cyl[1]=`dict_read "$setup" "position_of_shape1"`
dis_cyl1_2=`dict_read "$setup" "offset_shape1_2"`
dis_cyl2_3=`dict_read "$setup" "offset_shape2_3"`
dis_cyl3_4=`dict_read "$setup" "offset_shape3_4"`

lim_top=`dict_read "$setup" "lim_top"`
lim_bottom=`dict_read "$setup" "lim_bottom"`
lim_top_new=`dict_read "$setup" "lim_top_new"`
lim_bottom_new=`dict_read "$setup" "lim_bottom_new"`
lim_front=`dict_read "$setup" "lim_front"`
lim_back=`dict_read "$setup" "lim_back"`
lgth_upstream=`dict_read "$setup" "lgth_upstream"`
lgth_downstream=`dict_read "$setup" "lgth_downstream"`
min_grid=`dict_read "$setup" "min_grid"`
ER_dom_x_upstream=`dict_read "$setup" "ER_dom_x_upstream"`
ER_dom_x_mid=`dict_read "$setup" "ER_dom_x_mid"`
ER_dom_x_downstream=`dict_read "$setup" "ER_dom_x_downstream"`
ER_dom_y=`dict_read "$setup" "ER_dom_y"`
default_number_of_cylinders=`dict_read "$setup" "default_number_of_cylinders"`
owner=`dict_read "$setup" "owner"`
name_template=`dict_read "$setup" "name_template"`
special_prototype_folder=`dict_read "$setup" "special_prototype_folder"`

res=`dict_read "$setup" "re"` # Re's
ms=`dict_read "$setup" "m"` # m's
cs=`dict_read "$setup" "c"` #c's
ks=`dict_read "$setup" "k"` #k's

index=1; for loop in $ms; do m[$index]=$loop; index=`expr $index + 1`; done
index=1; for loop in $cs; do c[$index]=$loop; index=`expr $index + 1`; done
index=1; for loop in $ks; do k[$index]=$loop; index=`expr $index + 1`; done
for loop in `seq $max_cylinder_capacity`; do if [ -z "${m[$loop]}" ]; then m[$loop]=0; fi done #### change 4
for loop in `seq $max_cylinder_capacity`; do if [ -z "${c[$loop]}" ]; then c[$loop]=0; fi done #### change 4
for loop in `seq $max_cylinder_capacity`; do if [ -z "${k[$loop]}" ]; then k[$loop]=0; fi done #### change 4

setup_name=`echo $setup|sed "s=.*/==g"`
index=0
for loop in $res; do
    index=`expr $index + 1`
    re[$index]=$loop
    result_file_name[$index]=`echo "$name_template"|sed "s/%owner/$owner/g"|sed "s/%setup/$setup_name/g"|sed "s/%re/${re[$index]}k/g"`
done
    result_folder_name=`echo "$name_template"|sed "s/%owner/$owner/g"|sed "s/%setup/$setup_name/g"|sed "s/%re/${re[1]}-${re[$index]}k/g"`
for loop in $res; do
    re[$index]=`evaluate "${re[$index]} * 1000"`
    Uinf[$index]=`evaluate "${re[$index]}*$nu/$d"`
    index=`expr $index - 1`
done

#------------ calculate other parameters
if [ "$n_cyl" -eq "0" ]; then n_cyl=$default_number_of_cylinders; fi

for loop in `seq $max_cylinder_capacity`; do dim_cyl[$loop]=`evaluate "${dim_cyl[$loop]}/2"`; done
last_ggi_face_index=`expr $n_cyl \* 2`
pos_cyl[2]=`vadd "${pos_cyl[1]}" "$dis_cyl1_2"`
pos_cyl[3]=`vadd "${pos_cyl[2]}" "$dis_cyl2_3"`
pos_cyl[4]=`vadd "${pos_cyl[3]}" "$dis_cyl3_4"`
offset_cyl[1]='(0 0 0)'
offset_cyl[2]=`vadd "${pos_cyl[2]}" "-${offset_cyl[1]}"`
offset_cyl[3]=`vadd "${pos_cyl[3]}" "-${offset_cyl[1]}"`
offset_cyl[4]=`vadd "${pos_cyl[4]}" "-${offset_cyl[1]}"`
scale="($d $d 1)" #----set scale
lRef=$d
Aref=`evaluate "($lim_front-($lim_back))*$lRef"`

#------------ prepare temporary fiels
rm -rf tmp*
rm -rf $result_folder_name
cp -rp $common_prototype_folder tmp
cp -rpf $special_prototype_folder/* tmp/	# result folder
cp -rp ./tmp/ tmp1	# master case folder
cp -rp ./tmp/ tmp2	# slave case folder

#------------ echo setup information
echo "//~~~~~~~~~~~~~~~ start automatic mesh processing ~~~~~~~~~~~~~~~\\\\"
echo -e "\tNumber of Cylinders = $n_cyl\tnu = $nu\n\tThickness_min = $minThickness\tThickness_max = $maxThickness"
echo -e "\t  paramters\tmass\t  c\t  k"
index=1
for loop in `seq $n_cyl`; do
    echo -e "\t  cylinder$loop\t${m[$loop]}\t${c[$loop]}\t${k[$loop]}"
done
for loop in $res; do
    echo -e "\t  Re[$index]=${re[$index]}\tU[$index]=${Uinf[$index]}"
    index=`expr $index + 1`
done

counter=1	#system counter

#------------ merge domain blocks

rec_dom_upstream=`rec "(0 $lim_top 0);(0 $lim_bottom 0);${pos_cyl[1]}-(${dim_cyl[1]} 0 0)-($lgth_upstream 0 0);${pos_cyl[1]}-(${dim_cyl[1]} 0 0);(0 0 $lim_front);(0 0 $lim_back);(0 ${dim_cyl[1]} 0);(0 -${dim_cyl[1]} 0)"`	#top,bottom,left,right,front,back,top_of_cyl,bottom_of_cyl
rec_dom_downstream=`rec "(0 $lim_top 0);(0 $lim_bottom 0);${pos_cyl[$n_cyl]}+(${dim_cyl[$n_cyl]} 0 0);${pos_cyl[$n_cyl]}+(${dim_cyl[$n_cyl]} 0 0)+($lgth_downstream 0 0);(0 0 $lim_front);(0 0 $lim_back);(0 ${dim_cyl[$n_cyl]} 0);(0 -${dim_cyl[$n_cyl]} 0)"`	

echo -e "\tgenerating domain blocks..."

createMesh "./tmp1/constant/polyMesh/dict/blockMeshDict_dom_upstream.org" "${rec_dom_upstream}" "$min_grid" "$ER_dom_x_upstream,$ER_dom_y" > log
cp ./tmp1/constant/polyMesh/blockMeshDict ./tmp/constant/polyMesh/blockMeshDict$counter; counter=`expr $counter + 1`	#for record
createMesh "./tmp2/constant/polyMesh/dict/blockMeshDict_dom_downstream.org" "${rec_dom_downstream}" "$min_grid" "$ER_dom_x_downstream,$ER_dom_y" >> log
cp ./tmp2/constant/polyMesh/blockMeshDict ./tmp/constant/polyMesh/blockMeshDict$counter; counter=`expr $counter + 1`	#for record

mergeMeshes . tmp1 . tmp2 >> log 

loop=1
while [ $loop -lt $n_cyl ]
do
	loop_ggi2=`expr $loop \* 2`
	loop_ggi3=`expr $loop \* 2 + 1`
	loop_cyl1=`expr $loop `
	loop_cyl2=`expr $loop + 1`
	rec_dom_mid[${loop}]=`rec "(0 $lim_top 0);(0 $lim_bottom 0);${pos_cyl[${loop_cyl1}]}+(${dim_cyl[${loop_cyl1}]} 0 0);${pos_cyl[${loop_cyl2}]}-(${dim_cyl[${loop_cyl2}]} 0 0);(0 0 $lim_front);(0 0 $lim_back);(0 ${dim_cyl[$loop]} 0);(0 -${dim_cyl[$loop]} 0)"`
	density_x_dom_mid=`echo ${rec_dom_mid[${loop}]}|awk -F"," '{print($4-$3"/min_grid")}'|sed "s/min_grid/$min_grid/g"|bc`	#can be refined
	createMesh "./tmp2/constant/polyMesh/dict/blockMeshDict_dom_mid.org" "${rec_dom_mid[${loop}]}" "$min_grid" "$ER_dom_x_mid,$ER_dom_y" >> log
cp ./tmp2/constant/polyMesh/blockMeshDict ./tmp/constant/polyMesh/blockMeshDict$counter; counter=`expr $counter + 1`	#for record
	sed -i "s/ggi2out/ggi${loop_ggi2}out/g" ./tmp2/constant/polyMesh/boundary
	sed -i "s/ggi3in/ggi${loop_ggi3}in/g" ./tmp2/constant/polyMesh/boundary
	mergeMeshes . tmp1 . tmp2 >> log
	loop=`expr $loop + 1`
done
dict_write "./tmp*/system/controlDict" "writeCompression" "compressed"

#------------ merge domain with cylinders
loop=1
while [ $loop -le $n_cyl ]
do
	cp -r $mesh_path/${block_cyl[$loop]}/* tmp2/constant/polyMesh/
	transformPoints -translate "${offset_cyl[$loop]}" -case ./tmp2/	>>	log
	loop_ggi1=`expr $loop \* 2 - 1`
	loop_ggi2=`expr $loop \* 2`
	sed -i "s/cylinder1/cylinder${loop}/g" ./tmp2/constant/polyMesh/boundary
	sed -i "s/ggi1out/ggi${loop_ggi1}out/g" ./tmp2/constant/polyMesh/boundary
	sed -i "s/ggi2in/ggi${loop_ggi2}in/g" ./tmp2/constant/polyMesh/boundary
	echo -e "\tmerging domain with cylinder${loop}..."
	mergeMeshes . tmp1 . tmp2 >> log 
	loop=`expr $loop + 1`
done

#------------ copy merged mesh to result folder and remove redundant folders
find -type d -regex ".*/[0-9.]*[1-9]"| sort | tail -1 | xargs -I {1} cp -r {1}/polyMesh/ ./tmp/constant/
rm -rf tmp1 tmp2
cd ./tmp/
rm -rf ./constant/polyMesh/dict
#------------ set ggi properties
source ./batch_scripts/modifyBoundary.sh	# there is no need to change 'modifyBoundary' file unless you use different boundary names in the mesh.
sed -i "s/Last/$last_ggi_face_index/g" ./constant/polyMesh/boundary	

loop=`expr $n_cyl + 1`
while [ $loop -le $max_cylinder_capacity ]	# delete redundant boundary names
do
	sed -i "\=//cyl${loop}_begin= s=^=/*=" ./system/controlDict
	sed -i "\=//cyl${loop}_end= s=$=*/=" ./system/controlDict
	sed -i "\=//cyl${loop}_begin= s=^=/*=" ./constant/dynamicMeshDict
	sed -i "\=//cyl${loop}_end= s=$=*/=" ./constant/dynamicMeshDict
	sed -i "\=//cyl${loop}_begin= s=^=/*=" ./0/**
	sed -i "\=//cyl${loop}_end= s=$=*/=" ./0/**
	loop=`expr $loop + 1`
done

#------------ set case parameters to files
echo -e "\tsetting case parameters..."
for loop in `seq $max_cylinder_capacity`; do  ####
    dict_write "./constant/dynamicMeshDict" "mass" "${m[$loop]}" "\/\/cyl${loop}$"
    dict_write "./constant/dynamicMeshDict" "c" "${c[$loop]}" "\/\/cyl${loop}$"
    dict_write "./constant/dynamicMeshDict" "k" "${k[$loop]}" "\/\/cyl${loop}$"
done
sed -i "/\s*nu\s*nu\s/ s/^.*$/nu\tnu [0 2 -1 0 0 0 0] $nu;/" ./constant/transportProperties
sed -i "/minThickness/ s/minThickness.*;/minThickness\t$minThickness;/" ./constant/dynamicMeshDict 
sed -i "/maxThickness/ s/maxThickness.*;/maxThickness\t$maxThickness;/" ./constant/dynamicMeshDict 
sed -i "\=//nu= s=\<\(nu\w*\).*//=\1\t$nu\t//=" ./system/setFieldsDict
sed -i "/^[\t ]*maxCo/ s/^.*;/maxCo\t${maxCo};\t/" ./system/controlDict 
sed -i "/^[\t ]*lRef/ s/^.*;/\tlRef\t${lRef};\t/" ./system/controlDict 
sed -i "/^[\t ]*Aref/ s/^.*;/\tAref\t${Aref};\t/" ./system/controlDict 
if	[ $n_cyl -eq "1" ];	then
	sed -i "s/liblinMultiBodyFvMesh.so/liblinSingleBodyFvMesh.so/" ./system/controlDict
else
	sed -i "s/liblinSingleBodyFvMesh.so/liblinMultiBodyFvMesh.so/" ./system/controlDict
	sed -i "s/mySingleTopoBodyFvMesh/myMultiTopoBodyFvMesh/" ./constant/dynamicMeshDict
fi
loop=1
while [ $loop -le $max_cylinder_capacity ]	# set block boundary value to cellSetDict
do
	XL=`vadd "${pos_cyl[$loop]}" "-(${dim_cyl[$loop]} 0 0)"|sed 's/[()]//g'|awk '{print($1)}'`
	XR=`vadd "${pos_cyl[$loop]}" "+(${dim_cyl[$loop]} 0 0)"|sed 's/[()]//g'|awk '{print($1)}'`
	YCT=`vadd "${pos_cyl[$loop]}" "+(0 ${dim_cyl[$loop]} 0)"|sed 's/[()]//g'|awk '{print($2)}'`
	YCB=`vadd "${pos_cyl[$loop]}" "-(0 ${dim_cyl[$loop]} 0)"|sed 's/[()]//g'|awk '{print($2)}'`
	sed -i "\=//cyl${loop}= s/XL/$XL/g" ./system/cellSetDict
	sed -i "\=//cyl${loop}= s/XR/$XR/g" ./system/cellSetDict
	sed -i "\=//cyl${loop}= s/YCT/$YCT/g" ./system/cellSetDict
	sed -i "\=//cyl${loop}= s/YCB/$YCB/g" ./system/cellSetDict
	loop=`expr $loop + 1`
done

#------------ set field for nut and nuTilda
echo -e "\tsetting fields..."
setFields >> ../log

#------------ create 3 cells zones and 2 faces zones for each cylinder
sed '/#cyl/ s/^/#/' ./batch_scripts/createZones.sh > ./createZones.sh.org
sed -i '/#auto_script_tag/ s/^/#/' ./createZones.sh.org
cp ./system/setBatch ./setBatch.org
echo -e "" > ./setBatch

loop=1
while [ $loop -le $n_cyl ]
do
	echo -e "\tcreating zones for cylinder${loop}..."
	sed "/#cyl${loop}/ s/^[ #]\{1,\}//" ./createZones.sh.org > ./createZones.sh.tmp
	source ./createZones.sh.tmp >> ../log	
	sed -n "s=^\(.*\)//cyl${loop}=\1=p" ./setBatch.org >> ./setBatch
	loop=`expr $loop + 1`
done
echo "quit" >> ./setBatch
setSet -batch ./setBatch >> ../log	
rm -f ./constant/polyMesh/sets/*_old*	#  *_old files must be removed
setsToZones >> ../log	

#rm -r ./constant/polyMesh/sets/
mv ./setBatch ./system/
rm ./createZones.sh.* ./setBatch.*

#------------ scale mesh to experimental measures
echo -e "\tscaling mesh..."
transformPoints -scale "$scale"	>> ../log

#------------ finish
cd ..
mkdir $result_folder_name
mv tmp/ "$result_folder_name/tmp"
cd $result_folder_name
index=1
for loop in $res; do
    cp -rp tmp/ ${result_file_name[$index]}
    sed -i "\=//U= s=uniform\s*(.*)=uniform (${Uinf[$index]} 0 0)=" ./${result_file_name[$index]}/0/U
    index=`expr $index + 1`
done
rm -rf tmp/
echo -e "\tfiles were generated in $result_folder_name/"
echo "\\\\~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ END ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//"

