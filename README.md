# Compiling OpenJDK 8u on Big Sur/Monterey using Xcode 12/13

How to compile JDK 8 with the latest Xcode on the latest macOS.

Currently (January 2022), this repo is not really required; the only known current issue is that the build will fail on Xcode 13.
For historical purposes, the patches and their descriptions still appear in the script directory.  At this time, only
one patch is applied - to fix the version test.

This patch can build an x86_64 jdk on either an Intel or aarch64 Mac, but cannot yet build a native aarch64 JDK.
To cross-compile from an Apple Silicon mac, the script respawns itself under Rosetta and starts again.

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
- This patch only works with XCode 9 to 13. (Actually Xcode 11 down have not been tested recently)
- Some of the patches included may apply with offsets, etc.
- This patch will produce a JDK that runs on macOS 10.9 and above[1]; the original code runs on macOS 10.7 and above.
- The resultant JDK has not been run through TCK.

[1] Actual OS compatiblity has not been tested.

