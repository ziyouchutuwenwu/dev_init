alias pacman-mirror-select="sudo pacman-mirrors -i -tz -m rank"

# 清除所有无用包
alias pacman-clear='sudo pacman -Qtdq | if [ -n "$(cat)" ]; then xargs -r sudo pacman -Rns -; fi'
