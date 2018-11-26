#!/bin/bash

#set -e
OS="linux"
CPU="$HOSTTYPE"
DoGet='false'
DoInstallLibs='false'
DoMake='false'
lazdir=$(dirname "$(readlink -f "$(which lazbuild 2> /dev/null)")")
usage="
Usage: $(basename $0) [OPTION...]

Options:
  -g  --get                  download sources
  -p  --packs                install packages to Lazarus
  -m  --make                 compile CudaText
  -l  --lazdir <directiory>  set Lazarus directory
  -o  --os <system>          set target OS (win32/win64/linux/freebsd/darwin)
  -c  --cpu <arch>           set target CPU (i386/x86_64/arm)
  -h  --help                 show this message
"

[ $# -eq 0 ] && { echo "$usage"; exit 0; }

OPTIONS=hgpml:o:c:
LONGOPTS=help,get,packs,make,lazdir:,os:,cpu:
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
	echo "$usage"  
	exit 2
fi
eval set -- "$PARSED"

while true; do
	case "$1" in
	-g|--get)
		DoGet=true
		shift
		;;
	-m|--make)
		DoMake=true
		shift
		;;
	-h|--help)
		echo "$usage"
		exit 0
		;;
	-l|--lazdir)
		lazdir="$2"
		shift 2
		;;
	-c|--cpu)
		CPU=$@
		shift 2
		;;
	-o|--os)
		OS=$2
		shift 2
		;;
	-p|--packs)
		DoInstallLibs=true
		shift
		;;
	--)
		shift
		break
		;;
	esac
done

if [[ ! -x $lazdir/lazbuild ]]; then
	echo "Couldn't find lazbuild"
	echo "Use -l <path> option"
	exit 1
fi

cd $(dirname "$0")
Repos=$(cat cudaup.repos)
Packets=$(cat cudaup.packets)
if [ $DoGet = 'true' ]
then
	mkdir -pv 'src'
	cd src
	for i in $Repos
	do	
		temp=${i/'https://github.com/Alexey-T/'/''}
		[ ! -d "$temp/.git" ] && git clone "$i"	
		cd "$temp"
		git pull origin master
		cd ../
	done
	cd ../
fi
if [ $DoInstallLibs = 'true' ]
then
	for i in $Packets
	do
		"$lazdir/lazbuild" -q --lazarusdir="$lazdir" "./src/$i"
		"$lazdir/lazbuild" -q --lazarusdir="$lazdir" --add-package "./src/$i"
	done
	"$lazdir/lazbuild" -q --build-ide=
fi
if [ $DoMake = 'true' ]
then
	inc=''
	if [ $OS != 'linux' ]
	then
		inc="$inc --os=$OS"
	fi
	if [ $OS = 'win32' ]
	then
		CPU='i386'
	fi
	if [ $OS = 'win64' ]
	then
		CPU='x86_64'
	fi
	if [ $CPU != "$HOSTTYPE" ]
	then
		inc="$inc --cpu=$CPU"
	fi
	if [ $DoInstallLibs = 'false' ]
	then
		for i in $Packets
		do
			"$lazdir/lazbuild" $inc -q --lazarusdir="$lazdir" "./src/$i"
		done
	fi
	"$lazdir/lazbuild" $inc -q --lazarusdir="$lazdir" "./src/CudaText/app/cudatext.lpi"
	mkdir -pv "./bin/$OS-$CPU"
	if [ $OS = 'win32' ] || [ $OS = 'win64' ]
	then
		cp ./src/CudaText/app/cudatext.exe ./bin/$OS-$CPU/cudatext.exe
	else
		cp ./src/CudaText/app/cudatext ./bin/$OS-$CPU/cudatext
	fi
fi
