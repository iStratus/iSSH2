#!/bin/bash
#
# Created by Dan Jabbour on 10/29/21
# Copyright © 2021 iStratus. All rights reserved.
#


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORK_DIR=`mktemp -d -t iStratus`
if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
  echo "Could not create temp dir"
  exit 1
fi
function cleanup {
  rm -rf "$WORK_DIR"
  echo "Deleted temp working directory $WORK_DIR"
}
trap cleanup EXIT

PLATFORMS=("iphoneos" "iphonesimulator")

BUILDCRYPTO="xcodebuild -create-xcframework -output libcrypto.xcframework"
BUILDSSL="xcodebuild -create-xcframework -output libssl.xcframework"

for PLATFORM in "${PLATFORMS[@]}"
do
  $DIR/iSSH2.sh --platform=$PLATFORM --min-version=12.0 --build-only-openssl
  PLATFORMSRC="$DIR/openssl_$PLATFORM"
  PLATFORMTMP="$WORK_DIR/openssl_$PLATFORM"
  mkdir "$PLATFORMTMP"
  mkdir "$PLATFORMTMP/headers"
  mkdir "$PLATFORMTMP/headers/libcrypto"
  mkdir "$PLATFORMTMP/headers/libssl"
  mv $PLATFORMSRC/lib/libcrypto.a $PLATFORMTMP/libcrypto.a
  mv $PLATFORMSRC/lib/libssl.a $PLATFORMTMP/libssl.a
  mv $PLATFORMSRC/include/crypto $PLATFORMTMP/headers/libcrypto/
  mv $PLATFORMSRC/include/openssl $PLATFORMTMP/headers/libssl/
  rm -r $PLATFORMSRC
  BUILDCRYPTO="$BUILDCRYPTO\
    -library $PLATFORMTMP/libcrypto.a\
    -headers $PLATFORMTMP/headers/libcrypto"
  BUILDSSL="$BUILDSSL\
    -library $PLATFORMTMP/libssl.a\
    -headers $PLATFORMTMP/headers/libssl"
done

$BUILDCRYPTO
$BUILDSSL
