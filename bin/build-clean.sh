#!/bin/bash

usage() {
  echo "Usage: build-clean.sh --slug productname --main main.coffee --remote-disk \"/path/to\" --remote \"/path/to/remote\" --cert-pass password"
}

info() {
  echo -e "\n[\033[0;35mbuild-clean\033[0m] $1\n"
}

while [[ $# > 1 ]]
do
  key="$1"
  shift
  case $key in
    --slug)
    PRODUCT_SLUG="$1"
    shift
    ;;

    --main)
    MAIN="$1"
    shift
    ;;

    --remote)
    REMOTE="$1"
    shift
    ;;

    --remote-disk)
    REMOTE_DISK="$1"
    shift
    ;;

    --cert-pass)
    CERT_PASS="$1"
    shift
    ;;

    -h|--help)
    usage
    exit 0
    ;;
  esac
done

if [ "x$PRODUCT_SLUG" == "x" ]; then info "No slug provided." && usage && exit 1; fi

HASH=`git rev-parse --short HEAD`
BRANCH=`git rev-parse --abbrev-ref HEAD`
START=`date +%s`

info "Checking for clean repo ..."
# Cancel when repo dirty
git diff-index --quiet HEAD
if [ "$?" != "0" ]; then
  echo "Please clean up your Git repo first."
  exit 1
fi

info "Detaching HEAD ..."
# Detache from HEAD
git checkout --quiet --detach `git rev-parse HEAD`

if [ -e "$MAIN" ]; then
  info "Setting PRODUCTION var ..."
  # Set production flag
  sed -i 's/[[:space:]]*PRODUCTION[[:space:]]*=.*/PRODUCTION = true/' "$MAIN"
fi

info "Cleaning, linking and installing dependencies ..."
# build Generator plugin
# refresh deps, build prodution and optimize deps
# linking direct csshat repo to build src
rm -rf node_modules && \
npm link "../$PRODUCT_SLUG-panel/" && \
npm install

info "Packaging and flattening Generator plugin ..."
npm pack && \
npm run flatten

info "Creating build commit ..."
# Wont create commit if there are no changes
git commit --quiet "$MAIN" -m "Built at `date`" && \
git tag "build-$HASH"

info "Packaging extension ..."
# build CC extension
npm run extension <<< "$CERT_PASS"


BUILD_FILE=`ls -t *-photoshop-*.build.tgz`
BUILD_NAME=`basename -s .tgz $BUILD_FILE`

# include Git hash in filename
mv "$BUILD_NAME.tgz" "$BUILD_NAME.$HASH.tgz"


if [ -e "$REMOTE_DISK" ]; then
  info "Copying build to \"$REMOTE\" ..."
  mkdir -p "$REMOTE" && \
  cp extension.zip "$REMOTE" && \
  cp "$BUILD_NAME.$HASH.tgz" "$REMOTE"
fi

info "Checking out master ..."
# Get back
git checkout --quiet "$BRANCH"

END=`date +%s`
TOTAL=`echo "$END - $START" | bc`
info "Build $HASH took $TOTAL seconds"
