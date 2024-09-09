;; flycheck-init.el
;; flycheck install and settings

(package-require 'flycheck)

(add-hook 'after-init-hook #'global-flycheck-mode)

;; dont touch this
(provide 'flycheck-init)
