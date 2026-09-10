;;; yaml-mode-init.el --- yaml mode settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package yaml-mode
  :init
  (add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))

  :commands yaml-mode
  )

(provide 'yaml-mode-init)
;;; yaml-mode-init.el ends here
