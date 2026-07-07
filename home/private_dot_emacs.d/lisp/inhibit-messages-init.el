;;; inhibit-messages-init.el --- suppress annoying startup messages and default flair -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; no minibuffer startup message
(defun display-startup-echo-area-message ()
  "Do nothing."
  (lambda ()))


;; settings
(setq
  inhibit-startup-echo-area-message t
  ;; no splash message
  inhibit-startup-message t ;; (older)
  inhibit-splash-screen t
  ;; initial screen
  initial-scratch-message (concat ";; *scratch*\n;; Created: " (current-time-string))) ;; scratch message

(provide 'inhibit-messages-init)
;;; inhibit-messages-init.el ends here
