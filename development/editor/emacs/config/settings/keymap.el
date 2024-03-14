;; 退出 emacs
(global-set-key (kbd "C-x C-c") nil)
(global-set-key (kbd "C-q") 'save-buffers-kill-terminal)

;; 全选
(global-set-key (kbd "C-x C-a") 'mark-whole-buffer)

;; 复制 alt w
(global-set-key (kbd "C-x C-c") 'clipboard-kill-ring-save)

;; 粘贴 ctrl y
(global-set-key (kbd "C-x C-v") 'clipboard-yank)

;; 剪切 ctrl w
(global-set-key (kbd "C-x C-x") 'clipboard-kill-region)

;; 撤销，反转的话，按 C-g 以后，再按 C-z
(global-set-key (kbd "C-z") 'undo)

;; 搜索
(global-set-key (kbd "C-f") nil)
(global-set-key (kbd "C-f") 'swiper-isearch)

;; 替换
(global-set-key (kbd "C-r") 'query-replace)
(global-set-key (kbd "C-S-r") 'replace-string)

;; 切换注释
(global-set-key (kbd "C-/") 'comment-line)
