# This file is written to simplify the following duplicative operation:
## cellSet		//need to run 3 times after the modification of cellSetDict for each cylinder
## setSet -batch setBatch
## setsToZones
# and is part of the auto script
# by Zhiyao Wang, zhiyao@umich.edu, June 2013

# purge old mesh zones, sets/ folder
rm -rf ./constant/polyMesh/*Zones ./constant/polyMesh/meshModifiers	#auto_script_tag
rm -rf ./constant/polyMesh/sets/ 	#auto_script_tag
rm -rf ./0/polyMesh/	#auto_script_tag
rm -rf ./VTK/ 	#auto_script_tag

#  do cellSet three times for each cylinder
cp -p ./system/cellSetDict ./system/cellSetDict.tmp

# all relevant lines IN cellSetDict must be commented by '//'
# and the following script will automatically uncomment those lines
# edit the following lines based on how many cylinders you are using

sed '\*cyl1Top* s*//**' ./system/cellSetDict.tmp > ./system/cellSetDict 	#cyl1
cellSet	#cyl1
sed '\*cyl1\>* s*//**' ./system/cellSetDict.tmp > ./system/cellSetDict 	#cyl1
cellSet	#cyl1
sed '\*cyl1Bot* s*//**' ./system/cellSetDict.tmp > ./system/cellSetDict 	#cyl1
cellSet	#cyl1

#sed '\*cyl2Top* s*//**' ./system/cellSetDict.tmp > ./system/cellSetDict 	#cyl2
#cellSet	#cyl2
#sed '\*cyl2\>* s*//**' ./system/cellSetDict.tmp > ./system/cellSetDict 	#cyl2
#cellSet	#cyl2
#sed '\*cyl2Bot* s*//**' ./system/cellSetDict.tmp > ./system/cellSetDict 	#cyl2
#cellSet	#cyl2
#
#sed '\*cyl3Top* s*//**' ./system/cellSetDict.tmp > ./system/cellSetDict 	#cyl3
#cellSet	#cyl3
#sed '\*cyl3\>* s*//**' ./system/cellSetDict.tmp > ./system/cellSetDict 	#cyl3
#cellSet	#cyl3
#sed '\*cyl3Bot* s*//**' ./system/cellSetDict.tmp > ./system/cellSetDict 	#cyl3
#cellSet	#cyl3
#
#sed '\*cyl4Top* s*//**' ./system/cellSetDict.tmp > ./system/cellSetDict 	#cyl4
#cellSet	#cyl4
#sed '\*cyl4\>* s*//**' ./system/cellSetDict.tmp > ./system/cellSetDict 	#cyl4
#cellSet	#cyl4
#sed '\*cyl4Bot* s*//**' ./system/cellSetDict.tmp > ./system/cellSetDict 	#cyl4
#cellSet	#cyl4


# end of modification area

mv ./system/cellSetDict.tmp ./system/cellSetDict	#recover original cellSetDict

setSet -batch ./system/setBatch	#auto_script_tag

rm -f ./constant/polyMesh/sets/*_old*	#  *_old files must be removed	#auto_script_tag

setsToZones	# generate 3 cell zones and 2 face zones for each cylinder, which are required by the solver	#auto_script_tag

