;;; flycheck-init.el --- flycheck install and settings
;;; Commentary:
;;; none

;;; Code:

(require-package 'flycheck)
(use-package flycheck
  :defer t
  :hook (
          (prog-mode . flycheck-mode))
  )

(provide 'flycheck-init)
;;; flycheck-init.el ends here
