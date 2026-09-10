;;; flycheck-init.el --- flycheck install and settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package flycheck
  :hook ((after-init . global-flycheck-mode)
          ;; show diagnostics inline
          (after-init . global-flycheck-annotate-mode))
  :custom
  ;; only annotate the line at point
  (flycheck-annotate-other-lines-style nil))

(provide 'flycheck-init)
;;; flycheck-init.el ends here
