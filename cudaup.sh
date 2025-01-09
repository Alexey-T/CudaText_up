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

[ -z "$lazdir" -a -x "$HOME/Applications/Lazarus/lazbuild" ] && \
  lazdir="$HOME/Applications/Lazarus"
[ -z "$lazdir" -a -x "/Applications/Lazarus/lazbuild" ] && \
  lazdir=/Applications/Lazarus

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

while [ $# -gt 0 ]; do
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
	*)
		echo "$usage"
		exit 1
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
	mkdir -pv 'src'
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
			stashed=false
			stash_list_before=$(git stash list)
			git stash push --quiet
			stash_list_after=$(git stash list)
			if [ "$stash_list_before" != "$stash_list_after" ]; then
				stashed=true
			fi
			
			originmaster=$(git rev-parse --abbrev-ref HEAD@{upstream}) # origin/master
			origin_master=$(echo $originmaster | sed 's#/# #')         # origin master
			
			git fetch $origin_master --quiet --no-tags
			last_commit_current_branch=$(git rev-parse HEAD)
			last_commit_origin_master=$(git rev-parse $originmaster)
			
			if [ "$last_commit_current_branch" != "$last_commit_origin_master" ]; then
				git merge $originmaster                     # this will show changed files
				git fetch --depth 1 $origin_master --quiet --no-tags  # now do shallow fetch
				git reset --hard $originmaster --quiet      # and switch to it
				git tag -d $(git tag -l) > /dev/null
				git reflog expire --expire=all --all
				git gc --prune=all
			fi
			
			if [ "$stashed" = true ]; then
				echo Restoring stash
				git stash pop --quiet
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
	if [ "$OS" != 'linux' ]
	then
		inc="$inc --os=$OS"
	fi
	if [ "$OS" = 'win32' ]
	then
		CPU='i386'
	fi
	if [ "$OS" = 'win64' ]
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
	rm -f "./src/CudaText/app/cudatext"
	mkdir -p ./src/CudaText/app/cudatext.app/Contents/MacOS
	"$lazdir/lazbuild" $inc -q --lazarusdir="$lazdir" "./src/CudaText/app/cudatext.lpi"
	OUTDIR="./bin/$OS-$CPU-$WS"
	mkdir -pv $OUTDIR
	if [ "$OS" = 'win32' ] || [ "$OS" = 'win64' ]
	then
		cp ./src/CudaText/app/cudatext.exe $OUTDIR/cudatext.exe
	else
		cp ./src/CudaText/app/cudatext $OUTDIR/cudatext
	fi
fi
