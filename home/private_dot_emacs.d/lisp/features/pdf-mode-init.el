;;; pdf-mode-init.el --- settings related to pdf files and pdf-mode
;;; Commentary:
;;; none

;;; Code:

(require-package 'pdf-tools)
(use-package pdf-tools
  :commands pdf-mode
  :config
  (pdf-tools-install)
  :hook (
          ;; disable line-number-mode in pdf-mode
          (pdf-mode-hook . (lambda () (line-number-mode -1)))
          ;; revert pdf files after tex compilation
          (TeX-after-compilation-finished-functions . TeX-revert-document-buffer)
          )
  )

(provide 'pdf-mode-init)
;;; pdf-mode-init.el ends here
