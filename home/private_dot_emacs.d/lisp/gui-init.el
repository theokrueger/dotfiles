;; gui-init.el
;; settings related to the emacs X window

;; C-z wont minimise under X11
(defun maybe-suspend-frame ()
  "suspend frame unless running under window system"
  (interactive)
  (unless window-system
    (suspend-frame)))
(global-set-key (kbd "C-z") 'maybe-suspend-frame)

;; remove gui elements
(setq-default
  menu-bar-mode nil    ;; disable altbar
  tool-bar-mode nil    ;; disable fat buttons
  scroll-bar-mode nil) ;; disable scrollbar
(set-scroll-bar-mode nil)

;; disable gui popups
(setq-default
  use-file-dialog nil
  use-dialog-box nil)

;; X window settings
(setq-default
 window-resize-pixelwise t
 frame-resize-pixelwise t)

;; dont touch this
(provide 'gui-init)
