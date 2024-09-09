;; rust-init.el
;; rust settings

(require-package 'rust-mode)

(setq-default
  rust-format-on-save t)
;(add-hook 'rust-mode-hook
;  (lambda () (setq indent-tabs-mode nil)))

;; dont touch this
(provide 'rust-init)
