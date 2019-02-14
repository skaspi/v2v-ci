#!/usr/bin/env bash

# Arguments
test_name=$1
io_paths_ids=($(multipath -l | grep dm- | cut -d' ' -f2))

# Constants
logging_dir=/tmp
case_dir=$logging_dir/$test_name
processes_to_monitor=(ovirt-imageio-daemon)
services_to_restart=(ovirt-imageio-daemon)
monitor_processes=(nmon iostat top)
log_folders=(/var/log/vdsm/import /var/log/ovirt-imageio-daemon)

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters given."
    exit
fi

echo "[Initializing] Creating a temporary folder to store logs..."
rm -rvf $case_dir
mkdir $case_dir

for folder in "${log_folders[@]}"; do
    echo "[Initializing] Removing log files from $folder..."
    rm -rvf $folder/*
done

for service in "${services_to_restart[@]}"; do
    echo "[Initializing] Restarting service: $service..."
    systemctl restart $service
    sleep 3s
done

mkdir $case_dir/iostat
for id in "${io_paths_ids[@]}"; do
    echo "[Running] Running iostat on multipath path ID: $id..."
    iostat -xdm $id 1 &> $case_dir/iostat/$id.log &
done

# TODO:
# add nbdkit - this could be many processes per plan
mkdir $case_dir/top
for proc in "${processes_to_monitor[@]}"; do
    echo "[Running] Monitoring process: $proc..."
    top -p $(pgrep -d',' -f $proc) -w512 -b -d 2 &> $case_dir/top/$proc.log &
done

echo "[Running] Running nmon..."
mkdir $case_dir/nmon
nmon -f -s 5 -T -c 83000 -m $case_dir/nmon &

sleep 1s

success=true
for proc in "${monitor_processes[@]}"; do
    echo "[Validating] Process: $proc..."
    if [ -z "$(pgrep $proc)" ]; then
    	echo "Proccess: $proc is not running!"
	success=false
    fi
done

if $success; then
    echo "+++ Validation passed +++"
else
    echo "!!! Validation failed !!!"
fi
