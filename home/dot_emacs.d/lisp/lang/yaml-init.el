;; yaml-init.el
;; yaml mode settings

(require-package 'yaml-mode)

(add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))

;; dont touch this
(provide 'yaml-init)
