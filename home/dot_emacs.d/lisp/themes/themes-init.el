;;; themes-init.el --- settings relating to colour theme -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; load themes
(setq custom-safe-themes t)
(add-to-list 'custom-theme-load-path
             (expand-file-name "lisp/themes/" user-emacs-directory))

;; default theme of choice
(if (or (display-graphic-p) (daemonp))
  (load-theme 'lightblue)    ;; GUI theme (also used if daemon as it is preferred theme)
  (load-theme 'leuven-dark)) ;; TUI theme

(provide 'themes-init)
;;; themes-init.el ends here
