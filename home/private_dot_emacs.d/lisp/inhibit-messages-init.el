;; inhibit-messages-init.el
;; suppress annoying startup messages and default flair

;; no minibuffer startup message
(setq-default inhibit-startup-echo-area-message t)
(defun display-startup-echo-area-message ()
  (lambda ()))

;; no splash message
(setq-default inhibit-startup-message t) ;; (older)
(setq-default inhibit-splash-screen t)

;; initial screen
(setq-default initial-scratch-message (concat ";; *scratch*\n;; Created: " (current-time-string))) ;; scratch message

;; dont touch this
(provide 'inhibit-messages-init)
