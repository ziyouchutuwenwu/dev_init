;; 自带的目录浏览
;; 鼠标点击以后，在当前窗口打开
(defun single-buffer/dired-mouse-find-file (event)
  (interactive "e")
  (dired-mouse-find-file event 'find-alternate-file 'find-alternate-file)
)

(defun custom-dired-setting ()
  (put 'dired-find-alternate-file 'disabled nil)
  (define-key dired-mode-map (kbd "RET") 'dired-find-alternate-file)
  (define-key dired-mode-map (kbd "M-<left>") (lambda ()
    (interactive)
    (find-alternate-file "..")
  ))

  (advice-add 'dired-mouse-find-file-other-window :override 'single-buffer/dired-mouse-find-file)
)
(add-hook 'dired-mode-hook 'custom-dired-setting)
