;;; pest-mode-init.el --- pest settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; pest-mode
(require-package 'pest-mode)
(use-package pest-mode
  :defer t
  :commands pest-mode
  :hook (pest-mode . flymake-mode)
  :mode "\\.pest\\'"
;;  :config
;;  (setq-default)
  )

;; flycheck for pest
(require-package 'flycheck-pest)
(use-package flycheck-pest
  :defer t
  )

(provide 'pest-mode-init)
;;; pest-mode-init.el ends here
