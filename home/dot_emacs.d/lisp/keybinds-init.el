;; keybinds-init.el
;; provides custom keybinds / functions

;; window navigation
(global-set-key (kbd "M-S-<up>")    'windmove-up)
(global-set-key (kbd "M-S-<down>")  'windmove-down)
(global-set-key (kbd "M-S-<left>")  'windmove-left)
(global-set-key (kbd "M-S-<right>") 'windmove-right)

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

;; dont touch this
(provide 'keybinds-init)
