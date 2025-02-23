;;; keybinds-init.el --- custom keybinds / functions -*- lexical-binding: t -*-
;;; Commentary:
;;; Does not include package-specific binds (such as helm-M-x).
;;; Those are defined in relevant feature or language files
;;; Code:

;; launch the terminal
(global-set-key (kbd "C-<return>") (lambda () (interactive) (term "/bin/bash")))

;; window navigation
(global-set-key (kbd "M-s-<up>")    'windmove-up)
(global-set-key (kbd "M-s-<down>")  'windmove-down)
(global-set-key (kbd "M-s-<left>")  'windmove-left)
(global-set-key (kbd "M-s-<right>") 'windmove-right)
(global-set-key (kbd "M-s-k") 'windmove-up)
(global-set-key (kbd "M-s-j") 'windmove-down)
(global-set-key (kbd "M-s-h") 'windmove-left)
(global-set-key (kbd "M-s-l") 'windmove-right)

;; rename file (C-x C-S-s)
(defun rename-this-file-and-buffer (new-name)
  "Renames both current buffer and file it's visiting to NEW-NAME."
  (interactive "sNew name: ")
  (let ((name (buffer-name))
         (filename (buffer-file-name)))
    (unless filename
      (error "Buffer '%s' is not visiting a file!" name))
    (progn
      (when (file-exists-p filename)
        (rename-file filename new-name 1))
      (set-visited-file-name new-name)
      (rename-buffer new-name))))
(global-set-key (kbd "C-x C-S-s") 'rename-this-file-and-buffer)

(provide 'keybinds-init)
;;; keybinds-init.el ends here
