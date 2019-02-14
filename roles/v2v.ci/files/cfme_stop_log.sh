#!/usr/bin/env bash

# Arguments
test_name=$1

# Constants
logging_dir=/tmp
case_dir=$logging_dir/$test_name
case_files_dir=$case_dir/files
package_versions_dir=$case_dir/versions
processes_to_kill=(nmon)
log_files=(/var/www/miq/vmdb/log/evm* /var/www/miq/vmdb/log/automation* /var/log/messages)
packages=(cfme)

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters given"
    exit
fi

for process in "${processes_to_kill[@]}"; do
    echo "Killing process: $process..."
    killall $process
done

mkdir $case_files_dir

for file in "${log_files[@]}"; do
    echo "Copying specific file: $file..."
    cp -f $file $case_files_dir
done

mkdir $package_versions_dir

for pkg in "${packages[@]}"; do
    echo "Collecting package: $pkg version..."
    rpm -qa | grep "$pkg" >> $package_versions_dir/packages.log
done

file=$(date '+%Y-%m-%d_%H-%M-%S')_$(hostname -s)_$test_name-cfme.tar.gz
echo "Compressing logs into $file..."
cd $case_dir && tar cvzf /root/$file * && cd ~

echo "Removing test case temporary folder..."
rm -rf $case_dir
