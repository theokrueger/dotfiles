;;; inhibit-messages-init.el --- suppress annoying startup messages and default flair -*- lexical-binding: t -*-
;;; Commentary:
;;; some inhibitions already set in early-init.el
;;; Code:

;; settings
(setopt
  inhibit-startup-echo-area-message user-login-name ;; no minibuffer startup message
  inhibit-startup-screen            t               ;; no splash screen
  ;; initial screen
  initial-scratch-message (concat ";; *scratch*\n;; Created: " (current-time-string)))

(setq ring-bell-function 'ignore) ;; disable bell

(provide 'inhibit-messages-init)
;;; inhibit-messages-init.el ends here
