set nu
syntax enable
set background=dark
set term=xterm-256color

"支持在Visual模式下，通过C-c复制到系统剪切板
vnoremap <C-c> "+y
"支持在normal模式下，通过C-v粘贴系统剪切板
nnoremap <C-v> "*p

if system('uname') == "Linux\n"
    let g:solarized_termcolors=256
    let g:solarized_termctrans=1

    "开启linux下的灰蒙蒙的遮罩
    let g:solarized_termtrans=1
endif
colorscheme solarized
