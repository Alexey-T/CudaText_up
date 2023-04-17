#!/bin/bash

#set -e
OS="linux"
CPU="$HOSTTYPE"
WS=""
DoGet='false'
DoInstallLibs='false'
DoMake='false'
DoClean='false'
lazdir=$(which lazbuild 2> /dev/null) && \
lazdir=$(readlink -f "$lazdir") && \
lazdir=$(dirname "$lazdir")

usage="
Usage: $(basename $0) [option...]

Options:
  -g  --get                  download packages
  -p  --packs                install packages to Lazarus
  -m  --make                 compile CudaText
  -l  --lazdir <directiory>  set Lazarus directory
  -o  --os <system>          set target OS (win32/win64/linux/freebsd/darwin/solaris)
  -c  --cpu <arch>           set target CPU (i386/x86_64/arm)
  -w  --ws <widgetset>       override WidgetSet (gtk2/gtk3/qt/qt5/cocoa)
      --clean                delete temp Free Pascal folders (src/*/*/lib/*-*)
  -h  --help                 show this message
"

[ $# -eq 0 ] && { echo "$usage"; exit 0; }

OPTIONS=hgpml:o:c:w:
LONGOPTS=clean,help,get,packs,make,lazdir:,os:,cpu:,ws:
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
	echo "$usage"  
	exit 2
fi
eval set -- "$PARSED"

while true; do
	case "$1" in
	--clean)
		DoClean=true
		shift
		;;
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
	-w|--ws)
		WS=$2
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

if [ $DoMake = "true" ]; then
  	if [ -z "$lazdir" ]; then
    	echo "Couldn't find Lazarus directory"
    	echo "Use -l <path> option"
    	exit 1
  	fi

    if [ ! -x "$lazdir/lazbuild" ]; then
    	echo "Couldn't find lazbuild"
    	echo "Use -l <path> option"
    	exit 1
    fi
fi

cd $(dirname "$0")
Repos=$(cat cudaup.repos)
Packets=$(cat cudaup.packets)

if [ $DoClean = 'true' ]
then
	if [ -d src ]
	then
		rm -rf src/*/*/lib/*-*
	fi
fi
if [ $DoGet = 'true' ]
then
	mkdir -m=rwxrwxrw -pv 'src'
	cd src
	for i in $Repos
	do	
		i=${i%%[[:space:]]} # removes line breaks from the right end of the var!
		temp=${i/'https://github.com/Alexey-T/'/''}
		temp=${temp/'https://github.com/bgrabitmap/'/''}
		if [ ! -d "$temp/.git" ]; then
			echo Cloning "$i"
			git clone --depth 1 "$i"	
		else
			cd "$temp"
			echo Pulling "$i"
			last_commit="$(git log -n 1 --pretty=format:'%H')"
			git stash > /dev/null
			git pull --depth 1 --rebase --no-tags
			git stash pop > /dev/null 2>&1
			if [ "$last_commit" != "$(git log -n 1 --pretty=format:'%H')" ]; then
				# There are new commits, so make size smaller like a new shallow clone
				git tag -d $(git tag -l)
				git reflog expire --expire=all --all
				git gc --prune=all
			fi
			cd ../
		fi
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
	if [ '$OS' != 'linux' ]
	then
		inc="$inc --os=$OS"
	fi
	if [ '$OS' = 'win32' ]
	then
		CPU='i386'
	fi
	if [ '$OS' = 'win64' ]
	then
		CPU='x86_64'
	fi
	if [ "$CPU" != "$HOSTTYPE" ]
	then
		inc="$inc --cpu=$CPU"
	fi
	if [ "$WS" != "" ]
	then
		inc="$inc --ws=$WS"
	fi
	if [ $DoInstallLibs = 'false' ]
	then
		for i in $Packets
		do
			"$lazdir/lazbuild" $inc -q --lazarusdir="$lazdir" "./src/$i"
		done
	fi
	rm "./src/CudaText/app/cudatext"
	"$lazdir/lazbuild" $inc -q --lazarusdir="$lazdir" "./src/CudaText/app/cudatext.lpi"
	OUTDIR="./bin/$OS-$CPU-$WS"
	mkdir -pv $OUTDIR
	if [ '$OS' = 'win32' ] || [ '$OS' = 'win64' ]
	then
		cp ./src/CudaText/app/cudatext.exe $OUTDIR/cudatext.exe
	else
		cp ./src/CudaText/app/cudatext $OUTDIR/cudatext
	fi
fi
