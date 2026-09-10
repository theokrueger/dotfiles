;;; ui-init.el --- settings related to the TUI/GUI -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; C-z wont minimise under GUI
(defun maybe-suspend-frame ()
  "Suspend frame unless running under a window system."
  (interactive)
  (unless window-system
    (suspend-frame)))
(global-set-key (kbd "C-z") 'maybe-suspend-frame)

;; remove gui elements
(setopt
  menu-bar-mode nil       ;; disable altbar
  tool-bar-mode nil       ;; disable fat buttons
  scroll-bar-mode nil)    ;; disable scrollbar
(set-scroll-bar-mode nil) ;; disable scrollbar
(tool-bar-mode -1)        ;; disable fat buttons
(menu-bar-mode -1)        ;; disable altbar

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

;; make the first click but not move cursor
(setopt ns-click-through nil)

;; rebalance windows automatically when splitting
(setopt window-combination-resize t)
;; prefer horizontal splitting
(setopt split-window-preferred-direction 'longest)

;; make right-click do something sensible and shift-drag behave better
(when (display-graphic-p)
  (mouse-shift-adjust-mode)
  (context-menu-mode))

;; continuiously refresh input keystrokes thingy
(setopt view-lossage-auto-refresh t)

;; show available keybinds after short delay
(use-package which-key
  :demand t
  :config
  (which-key-mode))

;; goodbye decoration
(setopt default-frame-alist '(
                               (vertical-scroll-bars . nil)
                               (horizontal-scroll-bars . nil)
                               (ns-appearance . dark)
                               (ns-transparent-titlebar . t)
                               (undecorated-round . t)
                               (internal-border-width . 3)
                               ))

;; scrolling
(setopt mouse-wheel-tilt-scroll t)
(setopt mouse-wheel-flip-direction t)
(pixel-scroll-precision-mode) ; Smooth scrolling

;; TUI
(add-hook
  'tty-setup-hook
  #'(lambda ()
      ;; terminal mouse support
      (require 'mouse)
      (xterm-mouse-mode t)
      (gpm-mouse-mode t)
      ))

;; Update the cursor shape inside a terminal
(setopt xterm-update-cursor t)

(provide 'ui-init)
;;; ui-init.el ends here
