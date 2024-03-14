(use-package markdown-mode
 :ensure t
 :defer t
 :mode ("README\\.md\\'" . gfm-mode)
 :init (setq markdown-command "multimarkdown"))