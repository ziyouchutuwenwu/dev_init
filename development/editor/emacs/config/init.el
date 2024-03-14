;; 顺序不可以变
(load-file "~/.config/emacs/package/pkg-mirror.el")
(load-file "~/.config/emacs/package/use-package.el")

;; 通用配置
(mapc 'load (directory-files "~/.config/emacs/" t "^[a-zA-Z0-9].*.el$"))

;; 编程配置
(mapc 'load (directory-files "~/.config/emacs/programing/" t "^[a-zA-Z0-9].*.el$"))