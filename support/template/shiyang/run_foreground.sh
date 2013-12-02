#

echo -e "~~~~If this script goes to background, you must edit ./stop file first \n~~~~before trying to kill the process" 

manually_started="yes"  # manually started or automatically continued

function dict.read() {
    local _filename=$1
    local _dictname=$2
    echo `egrep "\<${_dictname}\>" ${_filename}|sed "s/[=:]/ /g"|awk -F" " '{print($2)}'`
}
function dict.write() {
    local _filename=$1
    local _dictname=$2
    local _dictvalue=$3
    sed -i "s/\<${_dictname}\>\s\{1,\}[-0-9a-zA-Z.\"]\{1,\}\s*/${_dictname}\t${_dictvalue} /" ${_filename}
}

n_delete=$1 # result folders to delete
if [ -z "$n_delete" ]; then n_delete=1; fi
max_count=10    # it's abnormal if the program restarts too many times, need to check the files

function error () {
    if [ "$manually_started" == "yes" ]; then manually_started="no"; return 0; fi 
    prefix="error_in_(`pwd|sed 's=.*/=='`)" # error file's prefix
    _t_error=`find -maxdepth 1 -regex '.*/[0-9.]+' |sort|sed 's=.*/\([0-9.]*[0-9]$\)=\1='|tail -1`
    _n_error=`find -maxdepth 1 -regex ".*/$prefix.*"|sort|sed 's=.*_n\([0-9]\{1,\}\)_t.*=\1='|tail -1`
    if [ -z "$_n_error" ]; then _n_error=0; fi
    _n_error1=`expr $_n_error + 1`
    _same_time_error_filename=${prefix}_n${_n_error}_t$_t_error
    _new_error_filename=${prefix}_n${_n_error1}_t$_t_error
    touch $_new_error_filename
    cp $_new_error_filename ../$_new_error_filename
    if [ -f "$_same_time_error_filename" ]; then return 1; fi
}

function isnew() {
    _time_org=`find -maxdepth 1 -regex '.*/[0-9.]+' |sort -r|sed 's=.*/\([0-9.]*[0-9]$\)=\1='`
    if [ "$_time_org" == "0" ]; then echo 0; else echo 1; fi
}

function restart() {
    _n=$1;
    _index=1
    for loop in `find -maxdepth 1 -regex '.*/[0-9.]+' |sort -r|sed 's=.*/\([0-9.]*[0-9]$\)=\1='`; do
        time[$_index]=$loop
        _index=`expr $_index + 1`
    done
    _index=1
    for loop in `ls -rtlh sinkTrimRes/ |awk '{print($9)}'|tac`; do
        _last_disp_file_time_cand[$_index]=$loop
        _index=`expr $_index + 1`
    done
    _m=0 # extract displacement from which time
    if [ "$_n" -ne "0" ]; then
        for loop in `seq $_n`; do
            if [ "${time[$loop]}" == "0" ]; then break; fi
            _m=$loop
            rm -rf ${time[$loop]}
            echo -e "\tResult of t=${time[$loop]}s removed"
        done
        echo -e "\tTotally $_m folder(s) removed"
    fi
    _m=`expr $_m + 1` 
    _index=1
    _last_disp_file_time=${_last_disp_file_time_cand[1]}
    while [ `echo "${_last_disp_file_time} ${time[$_m]}" | awk '{if($1>=$2) {print 0} else {print 1}}'` -eq "0" ]; do
        _index=`expr $_index + 1`
        _last_disp_file_time=${_last_disp_file_time_cand[$_index]}
        if [ "$_index" -ge "50" ]; then break; fi   # if there's no disp_file less than restart_time, break
    done
    last_disp_file=`echo "${_last_disp_file_time}"|xargs -i find ./sinkTrimRes/{} -type f`
    for loop in `seq 4`; do # loop for 4 cylinders' displacement
        loop1=`expr $loop + 1`
        if [ -n "$last_disp_file" ]; then
            eval "last_disp[$loop]=\`sed '/^[-0-9.e]\{1,\}\s*$/ s/^/=/' $last_disp_file|sed ':a;$!N;s/\n=/\t/g;ta;P;D'|egrep \"^${time[$_m]}\s\"|awk \"{print(\\\\\$$loop1)}\"|tail -1\`" #same as: sed -n -e 'H;/^[-0-9.e]\{1,\}\s*$/ {x;s/\n/\t/;x' -e '}' -e '/^[-0-9.e]\{1,\}\s*$/! {x;P' -e '}' mySingleTopoBodyFvMesh.dat 
        else
            last_disp[$loop]=0
        fi
        eval "sed -i \"\=//cyl${loop}_begin=,\=//cyl${loop}_end= {/initDisp/ s/initDisp\s.*;/initDisp\t\${last_disp[${loop}]};/}\"" ./constant/dynamicMeshDict
    done
    echo -e "\tExtracted initDisp from $last_disp_file"
    echo -e "\tt=${time[$_m]}, initDisp: ${last_disp[1]} ${last_disp[2]} ${last_disp[3]} ${last_disp[4]}"
    echo -e "\tRestarting caculation from t=${time[$_m]}s, "`date`
    echo -e "\t..."
    myTurbDyMFoam >log_continue_${time[$_m]} 2>>log_continue_${time[$_m]}
}

isnew=`isnew`   # whether this is a newly started calculation
count=0 #times of rerun

if [ "$isnew" -eq "0" ]; 
then   
    manually_started="no"
    myTurbDyMFoam >log_start 2>>log_start; 
else
    [ "1" -lt "0" ] # return 1, i.e. set $?=1, restart
fi

while [ "$?" -ne "0" ]; do
    stop_now=`dict.read 'restartDict' "stop_now"`
    if [ "$stop_now" != "0" ]; then echo "The script has been terminated"; exit; fi
    count=`expr $count + 1`
    reset_count=`dict.read 'restartDict' "reset_count"`
    if [ "$reset_count" -ne "0" ]; then
        count=1; max_count=$reset_count;
        dict.write "restartDict" "reset_count" "0"
    fi
    if [ "$count" -ge "$max_count" ]; then echo "Max restart times has reached, the script has stopped."; exit; fi
    n_delete=`dict.read 'restartDict' "to_delete"`
    maxCo=`dict.read 'restartDict' "maxCo"`
    dict.write "./system/controlDict" "maxCo" $maxCo
    error;
    if [ "$?" -eq "1" ]; then n_delete=`expr $n_delete + 1`; dict.write 'restartDict' "maxCo" `echo "scale=9;$maxCo/2"|bc`; echo -e "\tmaxCo changed to $maxCo!"; fi
    restart $n_delete
done
echo "Congratulations! The calculation has finished successfully!!"
