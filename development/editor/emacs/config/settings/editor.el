;; 字体
(set-face-attribute 'default nil :height 110)

;; 不创建备份
(setq make-backup-files nil)
(setq create-lockfiles nil)
(setq auto-save-default nil)

;; 设置默认的模式
(setq default-major-mode 'text-mode)

;; 打开大文件不要警告
(setq  large-file-warning-threshold nil)

;; 最近的文件个数
(setq recentf-max-saved-items 0)

;; 显示时间
(setq display-time-format "%Y-%m-%d %H:%M:%S %A")
(defun update-time-display ()
  (display-time-mode 1)
)
(run-with-timer 0 1 'update-time-display)

;; 高亮当前行
(global-hl-line-mode 1)

;; 确认缩写
(fset 'yes-or-no-p 'y-or-n-p)

;; 行号
(global-display-line-numbers-mode)

;; tab 换成 space
;; (setq-default indent-tabs-mode nil)
;; (setq-default tab-width 2)

;; 效果比较好，无视其它模式内的设置
(global-set-key (kbd "TAB") (lambda () (interactive) (insert-char 32 2)))
