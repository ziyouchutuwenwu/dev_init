;; 自定义函数
(defun kill-other-buffers ()
 "Kill all other buffers."
 (interactive)
 (mapc 'kill-buffer (delq (current-buffer) (buffer-list)))
)

(defun kill-all-buffers ()
 (interactive)
 (mapc 'kill-buffer (buffer-list))
)
