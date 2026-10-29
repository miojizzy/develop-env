#!/bin/bash

G_BIN_PATH="/root/bin"
#
# update config files
#
setup_configs(){
	if [ ! -d $G_BIN_PATH ]; then
		mkdir $G_BIN_PATH
	fi
	if [ `cat /root/.bashrc|grep "${G_BIN_PATH}"|wc -l` -gt 0 ]; then 
		return
	fi
	cat ./configs/bashrc >> /root/.bashrc
	cat ./configs/vimrc >> /root/.vimrc
	cat ./configs/gitconfig >> /root/.gitconfig
	cat ./configs/dbinit_stl_views-1.03.txt >> /root/.gdbinit
}

setup_configs