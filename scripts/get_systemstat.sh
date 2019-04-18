#!/bin/bash

# Define variables
LSB=/usr/bin/lsb_release
log=~/systemstat.log
# Purpose: Display pause prompt
# $1-> Message (optional)
function pause(){
    local message="$@"
    [ -z $message ] && message="Press [Enter] key to continue..."
    read -p "$message" readEnterKey
}

# Purpose  - Display a menu on screen
function show_menu(){
    date
    echo "---------------------------"
    echo "   Main Menu"
    echo "---------------------------"
    echo "1. OS and Kernel info"
    echo "2. Cpu info"
    echo "3. Network info and iperf test"
    echo "4. Disk info and fio test"
    echo "5. Free and used memory info"
    echo "6. exit"
}

# Purpose - Display header message
# $1 - message
function write_header(){
    local h="$@"
    echo "---------------------------------------------------------------"
    echo -e "\033[31m   ${h} \033[0m"
    echo "---------------------------------------------------------------"
}

# Purpose - Get info about your operating system
function os_info(){
    write_header " System  and Kernel information "
    [ -x $LSB ] && $LSB -a || echo "$LSB command is not insalled (set \$LSB variable)"
    echo "Kernel information : $(uname -r)"

    #pause "Press [Enter] key to continue..."
   # pause
}

function tool_install(){
    tool_name=$1
    tool_version=$2
    url=$3/${1}-${2}.tar.gz
    wget $url 
    mkdir ${1}-${2}
    tar -xzf ${1}-${2}.tar.gz -C ${1}-${2} --strip-components 1
    cd ${1}-${2} && ./configure && make && sudo make install
}   
# Purpose - Get info about host such as dns, IP, and hostname
function disk_info(){
    write_header " Disk information "
    local disks=$(df -lh|grep -v "loop\|tmpfs\|udev\|Filesystem")
    echo "Disk : $disks"
    write_header " Disk Test Iops "
    #echo " check tools fio exists ......"
    
    if ! type "fio" > /dev/null; then
	echo "Will install fio tool "
	pause
        tool_install "fio" "3.13" "https://github.com/axboe/fio/archive" > /dev/null 2>&1

    else
	echo "fio version $(fio --version)"
    fi
    local diskparts=$(df -lh|grep -v "loop\|tmpfs\|udev\|Filesystem"|awk '{print$NF}'|sed '$!N;s/\n/ "OR" /')
    #echo "Select disk part:  $diskparts"

    while read -p "Select the node data partition : $diskparts ?  " datanode_dir ;do
    
        local cpucore=$(lscpu|grep "^CPU(s)"|awk '{print $2}')
        if [[ "$diskparts" =~ "${datanode_dir}" ]]; then
            echo "fio test write ${datanode_dir} cpucore=$cpucore  size=1G bs=16k runtime=30s : "
            sudo fio -filename=${datanode_dir}/fio.test -direct=1 -iodepth 1 -thread -rw=write -ioengine=psync -bs=16k -size=1G -numjobs=$cpucore -runtime=30 -group_reporting -name=write|grep 'IOPS'
            echo "fio test read ${datanode_dir} cpucore=$cpucore  size=1G bs=16k runtime=30s :" 
	    sudo fio -filename=${datanode_dir}/fio.test -direct=1 -iodepth 1 -thread -rw=read -ioengine=psync -bs=16k -size=1G -numjobs=$cpucore -runtime=30 -group_reporting -name=write|grep 'IOPS'
            break;
	
        fi
    done
    pause
}

function net_info(){
    devices=$(netstat -i | cut -d" " -f1 | egrep -v "^Kernel|Iface|lo")
    write_header " Network information "
    echo "Total network interfaces found : $(wc -w <<<${devices})"

    echo "*** IP Addresses Information ***"
    ip -4 address show

    echo "***********************"
    echo "*** Network routing ***"
    echo "***********************"
    netstat -nr

    echo "**************************************"
    echo "*** Interface traffic information ***"
    echo "**************************************"
    netstat -i

    echo "check iperf tool exists ......"
    if ! type "iperf" > /dev/null;then
        echo "will install iperf "
	pause
        sudo apt-get install iperf
    else
	iperf --version
    fi

#    echo "start iPerf in server open iptable port 5001"
#    iperf -s & 
#    wth=$(curl ip.sb)
#    echo "other server as client connect iperf server: iperf -c $wth"
    echo "connect test iperf server us-west 18.144.21.59 "
    iperf -c 18.144.21.59
    #pause
}
function cpu_info(){
    write_header " Cpu core and Model "
    lscpu |grep "Model name:\|^CPU(s)"
    #pause
}

# Purpose - Display used and free memory info
function mem_info(){
    write_header " Free and used memory "
    free -m

    echo "*********************************"
    echo "*** Virtual memory statistics ***"
    echo "*********************************"
    vmstat
    echo "***********************************"
    echo "*** Top 5 memory eating process ***"
    echo "***********************************"
    ps auxf | sort -nr -k 4 | head -5
    #pause
}
# Purpose - Get input via the keyboard and make a decision using case..esac
function read_input(){
    local c
    read -p "Enter your choice [ 1 - 6 ] " c
    case $c in
        1)  os_info ;;
        2)  cpu_info ;;
        3)  net_info ;;
        4)  disk_info ;;
        5)  mem_info ;;
        6)  echo "Bye!"; exit 0 ;;
        *)
            echo "Please select between 1 to 6 choice only."
            pause
    esac
}

# ignore CTRL+C, CTRL+Z and quit singles using the trap
trap '' SIGINT SIGQUIT SIGTSTP

os_info |tee $log
cpu_info | tee -a $log
mem_info | tee -a $log
disk_info | tee -a $log
net_info | tee -a $log

write_header " Please send us the log file $log !!!! "
pause
# main logic
#while true
#do
#    clear
#    show_menu   # display memu
#    read_input  # wait for user input
#done
