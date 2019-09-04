#! /usr/bin/env /bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
source ~/.profile

nvm install stable
npm install -g yarn

sed -i "/# This loads nvm/d" ~/.profile
echo 'nvm() {
    echo "Lazy loading nvm..."
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm
}' >> ~/.profile
echo "-----------------------------------------------"
echo "node 的版本号需要手工改, nvm which default 可以获得"
echo "-----------------------------------------------"
echo 'export PATH=$HOME/.nvm/versions/node/这里替换版本号/bin/:$PATH' >> ~/.profile

echo 'export ELECTRON_MIRROR=https://npm.taobao.org/mirrors/electron/' >> ~/.profile

npm config set registry https://registry.npm.taobao.org
npm config set disturl https://npm.taobao.org/mirrors/node
yarn config set registry https://registry.npm.taobao.org