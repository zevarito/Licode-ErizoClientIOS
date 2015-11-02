#!/bin/bash

echo "Bundle WebRTC built libraries"
echo ""
echo "Starting..."
echo ""

if [ ! $1 ]; then
  echo "Error: You didn't provide an input directory!"
  echo ""
  echo "Usage"
  echo "-----"
  echo ""
  echo "bundle_webrtc.sh <input_dir>"
  echo ""
  echo "Input Directory should be 'src' directory inside 'webrtc' root directory."
  echo "It will create a directory libRTC in the current directory with merged libs."
  echo ""
  exit 1
else
  OUTPUT_DIR=`pwd`/libRTC
  if ! test -d $OUTPUT_DIR/Debug; then
    mkdir -pv $OUTPUT_DIR/Debug
    mkdir -pv $OUTPUT_DIR/Release
  fi
  printf "Working on $1\n\n"
  cd $1
fi

function bundleLib {
  INPUT_DIR=$1
  OUTPUT_FILE="$2/$4/libWebRTC-$3-$4.a"
  if test -d $INPUT_DIR ; then
    LIBS=`find $INPUT_DIR -name *.a -not -name *apprtc* -not -name *socketrocket*`
    read count <<< $(echo "$LIBS" | wc -l)
    echo "Input $INPUT_DIR - $count libs found"
    echo "Output $OUTPUT_FILE"
    libtool -static -o $OUTPUT_FILE $LIBS
  else
    echo "ios directory doesn't exist... skipping."
  fi
  printf "\n\n"
}

function copyHeaders {
  if ! test -d $OUTPUT_DIR/Public; then
    mkdir -pv $OUTPUT_DIR/Public
  fi
  cp ../talk/app/webrtc/objc/public/*.h $OUTPUT_DIR/Public
}

copyHeaders

bundleLib out_ios/Debug-iphoneos $OUTPUT_DIR armv7 Debug
bundleLib out_ios/Release-iphoneos $OUTPUT_DIR armv7 Release

bundleLib out_ios64/Debug-iphoneos $OUTPUT_DIR arm64 Debug
bundleLib out_ios64/Release-iphoneos $OUTPUT_DIR arm64 Release

bundleLib out_sim/Debug-iphonesimulator $OUTPUT_DIR i386 Debug
bundleLib out_sim/Release-iphonesimulator $OUTPUT_DIR i386 Release

lipo -create $OUTPUT_DIR/Debug/*.a -output $OUTPUT_DIR/libWebrtc-fat-Debug.a
lipo -create $OUTPUT_DIR/Release/*.a -output $OUTPUT_DIR/libWebrtc-fat-Release.a
