;; latex-init.el
;; latex mode settings

;; pdf-tools for previews
(require-package 'pdf-tools)
(pdf-loader-install)

;; text menubar
(add-hook 'reftex-load-hook 'imenu-add-menubar-index)
(add-hook 'reftex-mode-hook 'imenu-add-menubar-index)
(global-set-key (kbd "C-x n") 'imenu)

;; settings

;; dont touch this
(provide 'latex-init)
