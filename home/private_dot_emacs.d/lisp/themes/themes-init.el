;; themes-init.el
;; settings relating to colour theme

;; load themes
(setq-default custom-safe-themes t)
(add-to-list 'custom-theme-load-path (concat user-emacs-directory "lisp/themes/"))

;; theme of choice
(load-theme 'lightblue)

;; dont touch this
(provide 'themes-init)
