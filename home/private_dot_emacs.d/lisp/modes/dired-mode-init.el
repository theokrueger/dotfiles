;;; dired-mode-init.el --- dired-mode settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(setq-default
  dired-kill-when-opening-new-dired-buffer t ;; avoid accumulating so many dired buffers
  )

(provide 'dired-mode-init)
;;; dired-mode-init.el ends here
