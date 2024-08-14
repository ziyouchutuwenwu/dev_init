alias pacman-mirror-select="sudo pacman-mirrors -i --geoip -m rank"

# 清除所有无用包
alias pacman-clear="sudo pacman -Qtdq | xargs -r sudo pacman -Rns -"
