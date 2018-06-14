#!/bin/bash
DoGet='false'
DoMake='false'
ShowHelp='false'
for i in $*
do
case "$i" in
	'--get'|'-g')
	DoGet='true'
	;;
	'--make'|'-m')    
        DoMake='true'
        ;;
	'--help'|'-h')
	ShowHelp='true'
	;;
	*)
	echo "error: unknown parameter"
	esac
done
if [ $ShowHelp = 'true' ] || (($#==0))
then
	echo "usage: $script_name [params]"
	echo "params list:"
	echo "-g  --get  download sources"
	echo "-c  --make meke cuda_text"
	echo "-h  --help show this message"
	exit 0
fi
Repos=$(cat cudaup.repos)
Packets=$(cat cudaup.packets)
if ! [ -d "$HOME/cudatext_up/" ]
then
	mkdir "$HOME/cudatext_up/"
fi
cd "$HOME/cudatext_up/"
if [ $DoGet = 'true' ]
then
	if ! [ -d 'src' ]
	then
		mkdir 'src'
	fi
	cd src
	for i in $Repos
	do	
		temp=${i/'https://github.com/Alexey-T/'/''}
		fl=${temp/'.git'/''}
		if ! [ -d "$fl" ]
		then
			mkdir "$fl"
		fi
		if ! [ -d "$fl/.git" ]
		then
			git clone "$i"	
		else
			cd "$fl"
			git pull origin master
			cd ../
		fi
	done
	cd ../
fi
if [ $DoMake = 'true' ]
then
	inc=''
	for i in $Packets
	do
		lazbuild "$HOME/cudatext_up/src/$i"
		lazbuild --add-package "$HOME/cudatext_up/src/$i"
	done
	lazbuild uniqueinstance_package
	lazbuild --add-package uniqueinstance_package
	lazbuild "$HOME/cudatext_up/src/CudaText/app/cudatext.lpi"
fi
