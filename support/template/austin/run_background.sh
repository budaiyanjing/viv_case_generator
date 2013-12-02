#

echo -e "\n~~~If this script goes to background, you must edit ./stop file first \nbefore trying to kill the process\n" 

./run_foreground.sh >log 2>&1 &
