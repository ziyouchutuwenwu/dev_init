;; tab 插件
;; https://github.com/ema2159/centaur-tabs
(use-package centaur-tabs
  :demand
  :config
  (centaur-tabs-mode t)
  (centaur-tabs-headline-match)
  :custom
  (centaur-tabs-show-navigation-buttons t)
  (centaur-tabs-style "chamfer")
  (centaur-tabs-height 36)
  (centaur-tabs-set-icons t)
  (centaur-tabs-gray-out-icons 'buffer)
  (centaur-tabs-close-button "x")
  (centaur-tabs-set-modified-marker t)
  (centaur-tabs--buffer-show-groups nil)
  :hook
  (dired-mode . centaur-tabs-local-mode)
  :bind
  ("M-<left>" . centaur-tabs-backward)
  ("M-<right>" . centaur-tabs-forward)
  ("C-S-<left>" . centaur-tabs-move-current-tab-to-left)
  ("C-S-<right>" . centaur-tabs-move-current-tab-to-right)
)

;; 配置为两个缓冲区，一个给 emacs，一个给编辑的时候
(defun centaur-tabs-buffer-groups ()
  (list
   (cond
      ((or (string-equal "*" (substring (buffer-name) 0 1)))
      "emacs"
      )
      (t
      "editing"
      )
    )
  )
)
