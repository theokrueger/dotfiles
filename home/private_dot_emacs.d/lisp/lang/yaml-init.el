;;; yaml-init.el --- yaml mode settings
;;; Commentary:
;;; none

;;; Code:

(require-package 'yaml-mode)
(use-package yaml-mode
  :init
  (add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))

  :commands yaml-mode
  )


(provide 'yaml-init)
;;; yaml-init.el ends here
