Bash script to download all CudaText sources and build them.
Working dir is ~/cudatext_up.
Build results are in subdir /bin.

Download + build for current platform:
```shell
./cudaup.sh -g -m
```
Download + build for current platform and install packages in Lazarus:
```shell
./cudaup.sh -g -p -m
```
Download + build for current platform, with custom path to Lazarus:
```shell
./cudaup.sh -g -m -l /path/to/lazarus
```
Download + cross-compile to another platform:
```shell
./cudaup.sh -g -m -l /path/to/lazarus -o system -c cpu
```
  
* Possible values of "system": win32, win64, linux, darwin, freebsd, openbsd, netbsd, dragonfly, solaris, haiku.
* Possible values of "cpu" (not for win32, win64): i386, x86_64, arm, aarch64, sparc.
* Better run script via "sudo", otherwise new folders will have mode rw-r--r-- and resulting CudaText binary cannot create its config settings/user.json

To cross-compile to another platform, you need to use FpcUpDeluxe and install cross-compilers in its GUI.

* Author: Artem Gavrilov (@Artem3213212)
* License: MIT
