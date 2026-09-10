;;; tabs-init.el --- settings for top tab bar -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; defaults
(tab-bar-mode 1)

;; browser-like keybinds
(global-unset-key (kbd "C-t"))
(global-set-key   (kbd "C-<tab>")     'tab-bar-switch-to-next-tab)
(global-set-key   (kbd "C-S-<tab>")   'tab-bar-switch-to-prev-tab)
(global-set-key   (kbd "C-t C-<tab>") 'tab-bar-switch-to-recent-tab)
(global-set-key   (kbd "C-t C-f")     'tab-bar-switch-to-tab)
(global-set-key   (kbd "C-t C-t")     'tab-bar-new-tab)
(global-set-key   (kbd "C-t C-r")     'tab-bar-rename-tab)
(global-set-key   (kbd "C-t C-w")     'tab-bar-close-tab)
(global-set-key   (kbd "C-t C-n")     'make-frame)
(global-set-key   (kbd "C-t C-S-t")   'tab-bar-undo-close-tab)

;; `C-t 1' ... `C-t 9' select the tab at that position, `C-t 0' the last one
(dolist (n (number-sequence 1 9))
  (global-set-key (kbd (format "C-t %d" n))
    (lambda () (interactive) (tab-bar-select-tab n))))
(global-set-key (kbd "C-t 0") 'tab-bar-switch-to-last-tab)

(provide 'tabs-init)
;;; tabs-init.el ends here
