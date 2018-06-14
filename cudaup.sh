#!/bin/bash
OS="linux"
CPU="$HOSTTYPE"
DoGet='false'
DoInstallLibs='false'
DoMake='false'
ShowHelp='false'
NextParLazdir='false'
NextParOS='false'
NextParCPU='false'
lazdir='/usr/lib/lazarus'
for i in $*
do
	if [ "$NextParLazdir" = 'true' ]
	then
		NextParLazdir='false'
		lazdir=$i
		continue
	fi
	if [ "$NextParOS" = 'true' ]
	then
		NextParOS='false'
		OS=$i
		continue
	fi
	if [ "$NextParCPU" = 'true' ]
	then
		NextParCPU='false'
		CPU=$i
		continue
	fi
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
	'--lazdir'|'-l')
	NextParLazdir='true'
	;;
	'--cpu'|'-c')
	NextParCPU='true'
	;;
	'--os'|'-o')
	NextParOS='true'
	;;
	'--packs'|'-p')
	DoInstallLibs='true'
	;;
	*)
	echo "error: unknown parameter"
	esac
done
if [ $ShowHelp = 'true' ] || (($#==0))
then
	if [ "$script_name" = '' ]
	then
		echo 'usage: ./cudaup.sh [params]'
	else
		echo "usage: $script_name [params]"
	fi
	echo "params list:"
	echo "-g  --get                 download sources"
	echo "-p  --packs               install packages to Lazarus"
	echo "-m  --make                compile CudaText"
	echo "-l  --lazdir <directiory> set Lazarus directory"
	echo "-o  --os <system>         set target OS (win32/win64/linux/freebsd/darwin)"
	echo "-c  --cpu <arch>          set target CPU (i386/x86_64/arm)"
	echo "-h  --help                show this message"
	exit
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
if [ $DoInstallLibs = 'true' ]
then
	for i in $Packets
	do
		"$lazdir/lazbuild" -q --lazarusdir="$lazdir" "$HOME/cudatext_up/src/$i"
		"$lazdir/lazbuild" -q --lazarusdir="$lazdir" --add-package "$HOME/cudatext_up/src/$i"
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
	"$lazdir/lazbuild" $inc -q --lazarusdir="$lazdir" "$HOME/cudatext_up/src/CudaText/app/cudatext.lpi"
	if ! [ -d "$HOME/cudatext_up/bin" ]
	then
		mkdir "$HOME/cudatext_up/bin"
	fi
	if ! [ -d "$HOME/cudatext_up/bin/$OS-$CPU" ]
	then
		mkdir "$HOME/cudatext_up/bin/$OS-$CPU"
	fi
	if [ $OS = 'win32' ] || [ $OS = 'win64' ]
	then
		cp $HOME/cudatext_up/src/CudaText/app/cudatext.exe $HOME/cudatext_up/bin/$OS-$CPU/cudatext.exe
	else
		cp $HOME/cudatext_up/src/CudaText/app/cudatext $HOME/cudatext_up/bin/$OS-$CPU/cudatext
	fi
fi
