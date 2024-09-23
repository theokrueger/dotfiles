;;; pdf-mode-init.el --- settings related to pdf files and pdf-mode
;;; Commentary:
;;; Code:

(require-package 'pdf-tools)
(use-package pdf-tools
  :commands pdf-mode
  :config
  (pdf-tools-install)
  :hook
  ;; revert pdf files after tex compilation
  (TeX-after-compilation-finished-functions . TeX-revert-document-buffer)

  )

(provide 'pdf-mode-init)
;;; pdf-mode-init.el ends here
