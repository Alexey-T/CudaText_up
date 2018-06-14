Bash script to download all CudaText sources and build them.
Working dir is ~/cudatext_up
Build results are in subdir /bin

Download+build for current platform:
$ ./cudaup.sh -g -p -m
Download+build for current platform, with custom path to Lazarus:
$ ./cudaup.sh -g -p -m -l /path/to/lazarus
Download+ cross-compile to another platform:
$ ./cudaup.sh -g -p -m -l /path/to/lazarus -o system -c cpu
  
Possible values of "system": win32, win64, linux, freebsd, darwin
Possible values of "cpu" (not for win32, win64): i386, x86_64, arm
To cross-compile to another platform, you need to use FpcUpDeluxe and install cross-compilers in its GUI.

Author: @Artem3213212
License: MIT
