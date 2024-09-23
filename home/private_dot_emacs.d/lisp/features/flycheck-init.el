;;; flycheck-init.el --- flycheck install and settings
;;; Commentary:
;;; Code:

(require-package 'flycheck)
(use-package flycheck
  :defer t
  :commands (flycheck-mode flyspell-mode)
  :hook
  (prog-mode . flycheck-mode)
  (text-mode . flyspell-mode)
  )

(provide 'flycheck-init)
;;; flycheck-init.el ends here
