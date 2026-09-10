;;; ui-init.el --- settings related to the TUI/GUI -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; C-z wont minimise under GUI
(defun maybe-suspend-frame ()
  "Suspend the current frame unless it is displayed on a window system."
  (interactive)
  (unless (display-graphic-p)
    (suspend-frame)))
(global-set-key (kbd "C-z") 'maybe-suspend-frame)

;; menu-bar- and tool-bar-lines are zeroed in early-init.el
(menu-bar-mode -1)      ;; disable altbar
(tool-bar-mode -1)      ;; disable fat buttons
(scroll-bar-mode -1)    ;; disable scrollbar

;; disable mouse menus (they are annoying)
(bind-key* "C-<down-mouse-1>" 'ignore)
(bind-key* "C-<down-mouse-2>" 'ignore)
(bind-key* "C-<down-mouse-3>" 'ignore)

;; disable gui popups
(setopt
  use-file-dialog nil
  use-dialog-box nil)

;; ideal scaling
(setopt
  window-resize-pixelwise t
  frame-resize-pixelwise t)

;; make the first click go through without moving the cursor (macOS only)
(when (featurep 'ns)
  (setopt ns-click-through nil))

;; rebalance windows automatically when splitting
(setopt window-combination-resize t)

;; make right-click do something sensible and shift-drag behave better
(mouse-shift-adjust-mode 1)
(context-menu-mode 1)

;; continuiously refresh input keystrokes thingy
(setopt view-lossage-auto-refresh t)

;; show available keybinds after short delay
(use-package which-key
  :demand t
  :config
  (which-key-mode 1))

;; scrolling
(setopt mouse-wheel-tilt-scroll t)
(setopt mouse-wheel-flip-direction t)
(pixel-scroll-precision-mode 1) ; Smooth scrolling

;; TUI
(add-hook
  'tty-setup-hook
  #'(lambda ()
      ;; terminal mouse support
      (xterm-mouse-mode t)
      ))

;; Update the cursor shape inside a terminal
(setopt xterm-update-cursor t)

(provide 'ui-init)
;;; ui-init.el ends here
