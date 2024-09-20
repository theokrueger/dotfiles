;;; gui-init.el --- settings related to the emacs GUI window
;;; Commentary:
;;; Overlap between gui and tui settings belong in gui settings

;;; Code:

;; C-z wont minimise under GUI
(defun maybe-suspend-frame ()
  "Suspend frame unless running under a window system."
  (interactive)
  (unless window-system
    (suspend-frame)))
(global-set-key (kbd "C-z") 'maybe-suspend-frame)

;; remove gui elements
(setq-default
  menu-bar-mode nil       ;; disable altbar
  tool-bar-mode nil       ;; disable fat buttons
  scroll-bar-mode nil)    ;; disable scrollbar
(set-scroll-bar-mode nil) ;; disalbe scrollbar
(tool-bar-mode -1)        ;; disable fat buttons
(menu-bar-mode -1)        ;; disable altbar

;; disable gui popups
(setq-default
  use-file-dialog nil
  use-dialog-box nil)

;; GUI window settings
(setq-default
  window-resize-pixelwise t
  frame-resize-pixelwise t)

(provide 'gui-init)
;;; gui-init.el ends here
