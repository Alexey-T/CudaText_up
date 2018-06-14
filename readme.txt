Bash script to download all CudaText sources and build them.
Working dir is ~/cudatext_up
Build results are in subdir /bin

Download+build for current platform:
$ ./cudaup.sh -g -I -m
Download+build for current platform, with custom path to Lazarus:
$ ./cudaup.sh -g -I -m -l /path/to/lazarus
Download+ cross compile to another platform:
$ ./cudaup.sh -g -I -m -l -O system -C arch
  
Possible values of "system": win32, win64, linux
Possible values of "arch" (only for system=linux): i386, x86_64

Author: @Artem3213212
License: MIT
