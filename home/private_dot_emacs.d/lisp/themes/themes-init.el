;;; themes-init.el --- settings relating to colour theme
;;; Commentary:
;;; none

;;; Code:

;; load themes
(setq-default custom-safe-themes t)
(add-to-list 'custom-theme-load-path (concat user-emacs-directory "lisp/themes/"))

;; default theme of choice
(load-theme 'lightblue)

(provide 'themes-init)
;;; themes0init.el ends here
