(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :init
  (setq doom-modeline-support-imenu t)
  :custom-face
  (doom-modeline ((t (:family "Segoe Print" :height 0.9))))
  (doom-modeline-inactive ((t (:family "Segoe Print" :height 0.9))))
  (doom-modeline-battery-full ((t (:inherit success :weight extra-bold))))
  :custom
  (inhibit-compacting-font-caches t)
  (doom-modeline-minor-modes t)
  (doom-modeline-height 10)
  (doom-modeline-bar-width 2)
  (doom-modeline-enable-word-count t)
  (doom-modeline-indent-info t)
  (doom-modeline-set-pdf-modeline)
  (doom-modeline-github t)
  (doom-modeline-buffer-file-name-style 'file)
  (doom-modeline-project-detection 'ffip))