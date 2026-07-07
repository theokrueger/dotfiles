;;; company-init.el --- company install and settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require-package 'company)
(use-package company
  :defer t
  :commands company-mode
  :config
  (setq company-idle-delay 0.5)
  :hook
  (prog-mode . company-mode))

(provide 'company-init)
;;; company-init.el ends here
