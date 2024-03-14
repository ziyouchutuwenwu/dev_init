;; 包管理器
;; https://github.com/jwiegley/use-package
(unless (require 'use-package nil 'noerror)
  (package-refresh-contents)
  (package-install 'use-package)
)

(require 'use-package)
(setq use-package-always-ensure t)
