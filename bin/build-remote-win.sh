#!/bin/bash

usage() {
  echo "Usage: build-remote-win.sh --remote \"192.168.1.2\" --remote-user Administrator --storage-disk \"/path/to\" --storage \"/path/to/remote\""
}

info() {
  echo -e "\n[\033[0;35mwin-build\033[0m] $1\n"
}

check_err() {
  #echo Last code: $?
  if [ $? -ne 0 ]; then
    echo 'Exiting build script ...'
    exit 1
  fi
}

# TODO: errors
# TODO: tests

while [[ $# > 1 ]]
do
  key="$1"
  shift
  case $key in
    --remote)
    REMOTE="$1"
    shift
    ;;

    --remote-user)
    REMOTE_USER="$1"
    shift
    ;;

    -h|--help)
    usage
    exit 0
    ;;
  esac
done

# Source HQ Win machine
# REMOTE="10.0.0.4"
# REMOTE_USER="ci"
# STORAGE_DISK="/Volumes/Source SW/"
# STORAGE="/Volumes/Source SW/pnghat/latest"

if [ "x$REMOTE" == "x" ]; then info "No remote provided." && usage && exit 1; fi
if [ "x$REMOTE_USER" == "x" ]; then info "No remote user provided." && usage && exit 1; fi

PING=`ping -c1 -t5 $REMOTE >/dev/null 2>&1`

if [ $? -ne 0 ]; then
  echo "Windows host at $REMOTE is not reachable. Is it turned on? Are you connected?"
  exit 1
fi

# build all first
#./cleanbuild.sh

BUILD=`ls -t *-photoshop-*.build.???????.tgz | head -1`

if [ "x$BUILD" == "x" ]; then info "Make a clean build first." && exit 1; fi

FOLDER=`basename -s .tgz $BUILD`

check_err

# use local config for win-remote
#npm link ~/Projects/win-remote

info "Copying build to remote machine ..."
# move build to test machine
smb-push "$BUILD"

# copy whole dir, skip .git dir
# ./node_modules/coffee-script/bin/coffee ./node_modules/win-remote/smb-tree.coffee . \(\?\!\\.git\/\)

check_err

info "Unpacking build ..."
# extract trasfered archive with the plugin production build
# Structure:
# ./folder_without_ext/
#   - package/ - contains the npm module
run ungzip C:/Users/$REMOTE_USER/.build/"$BUILD"

check_err

# Re/start SSHD service with
# taskkill /f /t /im FreeSSHDService.exe
# "C:\Program Files (x86)\freeSSHd\FreeSSHDService.exe"

# run plugin in PS's node
#run command "C:/Program Files/Adobe/Adobe Photoshop CC 2014/node.exe" "C:/Users/$REMOTE_USER/.build/pnghat-photoshop-1.1.3/package"

# Prerequisites
# https://github.com/adobe-photoshop/generator-core/wiki/Generator-Development-Environment-Setup#change-generator-settings-in-photoshop

# Running PS
#run command "C:/Program Files/Adobe/Adobe Photoshop CC 2014/Photoshop.exe"

info "Starting up Photoshop ..."
# Run async; http://superuser.com/a/341603/44834
run command cmd /c start "\\\"\\\"" "\\\"C:/Program Files/Adobe/Adobe Photoshop CC 2014/Photoshop.exe\\\""

check_err

info "Waiting ..."
# Wait for PS to load
sleep 10

# run PS's Generator standalone
#run command "C:/Program Files/Adobe/Adobe Photoshop CC 2014/node.exe" "\\\"C:/Program Files/Adobe/Adobe Photoshop CC 2014/Required/Generator-builtin\\\""

info "Running standalone Generator with our plugin ..."
# run PS's Generator standalone with custom plugins folder
run command "C:/Program Files/Adobe/Adobe Photoshop CC 2014/node.exe" "\\\"C:/Program Files/Adobe/Adobe Photoshop CC 2014/Required/Generator-builtin\\\"" -f "C:/Users/$REMOTE_USER/.build/$FOLDER/package" &
#> "C:/Users/$REMOTE_USER/.build/generator.log"

check_err

# :(
#run command "C:/Program Files/Adobe/Adobe Photoshop CC 2014/node.exe" "\\\"C:/Program Files/Adobe/Adobe Photoshop CC 2014/Required/Generator-builtin\\\"" \> "\\\"C:/Users/$REMOTE_USER/.build/generator.log\\\""

info "Waiting for plugin to boot up ..."
# Let the plugin run for a while
sleep 10

# Kill Photoshop
run command taskkill /f /t /im Photoshop.exe

check_err

# Print Generator log
info "Generator log pre 2014.2.0"
run command cmd /c type "\\\"C:\\Users\\$REMOTE_USER\\AppData\\Roaming\\Adobe\\Adobe Photoshop CC\\Generator\\logs\\generator_latest.txt\\\""
info "Generator log post 2014.2.0"
run command cmd /c type "\\\"C:\\Users\\$REMOTE_USER\\AppData\\Roaming\\Adobe\\Adobe Photoshop CC 2014\\Generator\\logs\\generator_latest.txt\\\""

info "Packing build ..."
# Gzip plugin back again
run gzip "C:/Users/$REMOTE_USER/.build/$FOLDER/package"

check_err

info "Copying back to local ..."
# Get back Win archive
smb-pull "$FOLDER"\\package.tgz

mv package.tgz "$FOLDER.win.tgz"

check_err

if [ -e "$STORAGE_DISK" ]; then
  info "Copying to build storage ..."
  mkdir -p "$STORAGE"
  cp "$FOLDER.win.tgz" "$STORAGE"
fi

check_err
