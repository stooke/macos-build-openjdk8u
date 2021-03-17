# Compiling OpenJDK 8u on Big Sur using Xcode 12

How to compile JDK 8 with the latest Xcode on the latest macOS.

Currently (March 2021), OpenJDK jdk8u can only be compiled with Xcode 4, which won't run on the latest macOS.
This repo contains patches and information for setting up an environment to compile a JDK using the very latest tools.

This patch can build an x86_64 jdk on eithea an Intel or aarch64 Mac, but cannot yet build a native aarch64 JDK.

### Quick start:

The easiest way to get a working JDK8u is:

```
  mkdir workdir
  cd workdir
  git clone https://github.com/stooke/jdk8u-xcode10.git
  ./jdk8u-xcode10/build8.sh
  ./jdk8u-dev/build/maxosx-x86_64-normal-server-release/images/j2sdk-image/bin/java -version
  
```

### Caveats:
- This patch only works with XCode 9, 10, 11 or 12. (Actually 9 and 11 have not been tested recently)
- Some of the patches included may apply with offsets, etc.
- This patch will produce a JDK that runs on macOS 10.9 and above[1]; the original code runs on macOS 10.7 and above.
- The resultant JDK has not been run through TCK.

[1] Actual OS compatiblity has not been tested.

