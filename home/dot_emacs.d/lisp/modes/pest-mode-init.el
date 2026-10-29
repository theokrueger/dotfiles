;;; pest-mode-init.el --- pest settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; pest-mode
(use-package pest-mode
  :commands pest-mode
  :mode "\\.pest\\'")

;; flycheck for pest
(use-package flycheck-pest
  :after flycheck
  :demand t
  :config
  (flycheck-pest-setup))

(provide 'pest-mode-init)
;;; pest-mode-init.el ends here
