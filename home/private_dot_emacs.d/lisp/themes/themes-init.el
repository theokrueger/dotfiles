;;; themes-init.el --- settings relating to colour theme -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; load themes
(setq custom-safe-themes t)
(add-to-list 'custom-theme-load-path (concat user-emacs-directory "lisp/themes/"))

;; default theme of choice
(if (or window-system (daemonp))
  (load-theme 'lightblue)    ;; GUI theme (also used if daemon as it is preferred theme)
  (load-theme 'leuven-dark)) ;; TUI theme

(provide 'themes-init)
;;; themes-init.el ends here
