;;; company-init.el --- company install and settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package company
  :commands company-mode
  :config
  (setopt company-idle-delay 0.5)
  :hook
  (prog-mode . company-mode))

(provide 'company-init)
;;; company-init.el ends here
