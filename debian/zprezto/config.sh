#! /usr/bin/env /bin/bash

git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

ln -s "${ZDOTDIR:-$HOME}/.zprezto/runcoms/zlogin" ~/.zlogin
ln -s "${ZDOTDIR:-$HOME}/.zprezto/runcoms/zlogout" ~/.zlogout
ln -s "${ZDOTDIR:-$HOME}/.zprezto/runcoms/zpreztorc" ~/.zpreztorc
ln -s "${ZDOTDIR:-$HOME}/.zprezto/runcoms/zprofile" ~/.zprofile
ln -s "${ZDOTDIR:-$HOME}/.zprezto/runcoms/zshenv" ~/.zshenv
ln -s "${ZDOTDIR:-$HOME}/.zprezto/runcoms/zshrc" ~/.zshrc

sed -i "s/theme 'sorin'/theme 'skwp'/g" ${ZDOTDIR:-$HOME}/.zprezto/runcoms/zpreztorc

echo "pyenv update; rbenv update; sudo apt update; sudo apt-file update; sudo apt upgrade -y; sudo apt full-upgrade -y; sudo apt install build-essential; sudo apt autoremove -y; sudo apt autoclean;" > ~/.zhistory
chmod -w ~/.zhistory

rm -rf ~/.bashrc
rm -rf ~/.bash_history
rm -rf ~/.bash_logout

# ------------------------------------------------------------------------
# 注意必须在ln以后，不然会错误，得用"${ZDOTDIR:-$HOME}/.zprezto/runcoms/zshrc"
echo "source ~/.profile\n" >> ~/.zshrc

# 抄袭fish的语法高亮的主题
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/plugins/zsh-syntax-highlighting
echo "source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc

# 增加fish的补全插件
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
echo "source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh\n" >> ~/.zshrc

mkdir -p ~/.zsh/colors
CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
cp -rf $CURRENT_DIR/shell_color/dircolors.ansi-dark ~/.zsh/colors

echo "eval \`dircolors ~/.zsh/colors/dircolors.ansi-dark\`\n" >> ~/.zshrc