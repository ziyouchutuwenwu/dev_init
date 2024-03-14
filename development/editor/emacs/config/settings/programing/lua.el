(use-package lua-mode
 :ensure t
 :defer t
 :mode ("\\.lua$'" . lua-mode)
 :config
 (add-to-list 'interpreter-mode-alist '("lua" . lua-mode))
)
