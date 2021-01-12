filetype plugin indent on

autocmd BufNewFile,BufRead SConstruct :set filetype=python
autocmd BufNewFile,BufRead SConscript :set filetype=python

" 这是一个测试的文件类型配置
autocmd BufNewFile,BufRead *.abc :set filetype=aaa
