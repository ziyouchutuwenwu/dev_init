;; 补全后端
(use-package cape
  :ensure t
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-keyword)
  (add-to-list 'completion-at-point-functions #'cape-history)
  (global-corfu-mode)
  )

;; 输入补全前端
(use-package corfu
  :ensure t
  :hook (prog-mode . corfu-mode)
  :bind (:map corfu-map
              ("C-n" . corfu-next)
              ("C-p" . corfu-previous)
              ("<escape>" . corfu-quit)
	      )
  :config
  (setq corfu-auto t
        corfu-auto-prefix 1
        corfu-auto-delay 0.1
        corfu-quit-no-match t
        corfu-quit-at-boundary nil)
  (add-hook 'multiple-cursors-mode-enabled-hook (lambda () (corfu-mode -1)))
  (add-hook 'multiple-cursors-mode-disabled-hook (lambda () (corfu-mode 1))))

;; 设置前景色和背景色
(custom-set-faces
  '(corfu-current ((t (:background "#55aaff" :foreground "#232323"))))
  '(corfu-default ((t (:background "#3f3f3f" :foreground "#96bb64"))))
)