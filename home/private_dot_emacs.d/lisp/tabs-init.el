;; tabs-init.el
;; settings for top tab bar

;; defaults
(setq-default
  tab-bar-mode t
  )

;; browser-like keybinds
(global-unset-key (kbd "C-t"))
(global-set-key   (kbd "C-<tab>")     'tab-bar-switch-to-next-tab)
(global-set-key   (kbd "C-S-<tab>")   'tab-bar-switch-to-previous-tab)
(global-set-key   (kbd "C-t C-<tab>") 'tab-bar-switch-to-recent-tab)
(global-set-key   (kbd "C-t C-f")     'tab-bar-switch-to-tab)
(global-set-key   (kbd "C-t C-t")     'tab-bar-new-tab)
(global-set-key   (kbd "C-t C-r")     'tab-bar-rename-tab)
(global-set-key   (kbd "C-t C-w")     'tab-bar-close-tab)
(global-set-key   (kbd "C-t C-n")     'make-frame)
(global-set-key   (kbd "C-t C-S-t")   'tab-undo)

(dolist (num '("1" "2" "3" "4" "5" "6" "7" "8" "9" "0"))
  (global-set-key (kbd (concat "C-t C-" num))
    (lambda () (interactive) (tab-bar-select-tab 'num))))


(tab-bar-mouse-move-tab 1)
;; dont touch this
(tab-bar-mode 1)

(provide 'tabs-init)
