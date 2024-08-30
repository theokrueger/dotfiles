;; inhibit-messages-init.el
;; suppress annoying startup messages and default flair

;; no minibuffer startup message
(setq inhibit-startup-echo-area-message t)
(defun display-startup-echo-area-message ()
  (lambda ()))

;; no splash message
(setq inhibit-startup-message t) ;; (older)
(setq inhibit-splash-screen t)

;; initial screen
(setq initial-scratch-message (concat ";; *scratch*\n;; Created: " (current-time-string))) ;; scratch message

;; dont touch this
(provide 'inhibit-messages-init)
