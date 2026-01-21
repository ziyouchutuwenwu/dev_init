# !/bin/bash

cd openocd_github_src
git pull
autoupdate
./bootstrap
./configure --enable-jlink --prefix=$HOME/dev/embedded/openocd/openocd
make install
git reset --hard
