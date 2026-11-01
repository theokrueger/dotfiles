;;; keybinds-init.el --- custom keybinds / functions -*- lexical-binding: t -*-
;;; Commentary:
;;; Does not include package-specific binds (such as helm-M-x).
;;; Those are defined in relevant feature or language files
;;; Code:

;; launch the terminal
;;(global-set-key (kbd "C-<return>") (lambda () (interactive) (term "/bin/bash")))

;; window navigation
(global-set-key (kbd "C-M-<up>")    'windmove-up)
(global-set-key (kbd "C-M-<down>")  'windmove-down)
(global-set-key (kbd "C-M-<left>")  'windmove-left)
(global-set-key (kbd "C-M-<right>") 'windmove-right)

(global-set-key (kbd "C-x C-S-s") 'rename-visited-file)

;; delete instead of kill word
(defun delete-word (arg)
  "Delete characters forward until encountering the end of a word.
With argument ARG, do this that many times."
  (interactive "p")
  (delete-region (point) (progn (forward-word arg) (point))))

(defun backward-delete-word (arg)
  "Delete characters backward until encountering the beginning of a word.
With argument ARG, do this that many times."
  (interactive "p")
  (delete-word (- arg)))

(global-set-key (kbd "C-<delete>") 'delete-word)
(global-set-key (kbd "M-d") 'delete-word)
(global-set-key (kbd "C-<backspace>") 'backward-delete-word)
(global-set-key (kbd "M-DEL") 'backward-delete-word) ;; same as M-<backspace>

(provide 'keybinds-init)
;;; keybinds-init.el ends here
