#!/usr/bin/env bash

# Arguments
test_name=$1

# Constants
logging_dir=/tmp
case_dir=$logging_dir/$test_name
case_files_dir=$case_dir/files
package_versions_dir=$case_dir/versions
processes_to_kill=(top iostat nmon)
log_dirs=(/var/log/vdsm/import /var/log/ovirt-imageio-daemon)
files_to_collect=(/var/log/vdsm/vdsm.log /etc/ovirt-imageio-daemon/daemon.conf /var/log/messages)
packages=(vdsm virt-v2v nbdkit ovirt-imageio-daemon qemu-img)

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters given"
    exit
fi

for process in "${processes_to_kill[@]}"; do
    echo "Killing process: $process..."
    killall $process
done

mkdir $case_files_dir

for file_to_copy in "${files_to_collect[@]}"; do
    echo "Copying specific file: $file_to_copy..."
    cp -f $file_to_copy $case_files_dir
done

for log_dir in "${log_dirs[@]}"; do
    echo "Copying specific folder: $log_dir"
    cp -rf $log_dir $case_files_dir
done

mkdir $package_versions_dir

for pkg in "${packages[@]}"; do
    echo "Collecting package: $pkg version..."
    rpm -qa | grep "$pkg" >> $package_versions_dir/packages.log
done

echo "Saving vddk plugin dump output..."
echo `LD_LIBRARY_PATH="/opt/vmware-vix-disklib-distrib/lib64" nbdkit --dump-plugin vddk` > $package_versions_dir/vddk_plugin.log

file=$(date '+%Y-%m-%d_%H-%M-%S')_$(hostname -s)_$test_name-conv_host.tar.gz
echo "Compressing logs into $file..."
cd $case_dir && tar cvzf /root/$file * && cd ~

echo "Removing test case temporary folder... $case_dir"
rm -rf $case_dir
