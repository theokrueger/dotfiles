;;; flycheck-init.el --- flycheck install and settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package flycheck
  :commands (flycheck-mode flyspell-mode)
  :hook
  (prog-mode . flycheck-mode)
  (text-mode . flyspell-mode)
  )

(provide 'flycheck-init)
;;; flycheck-init.el ends here
