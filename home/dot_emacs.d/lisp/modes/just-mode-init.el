;;; just-mode-init.el --- justfile settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package just-mode
  :commands just-mode
  :mode ("/\\(?:\\.\\)?[jJ][uU][sS][tT][fF][iI][lL][eE]\\'" . just-mode)

  :custom
  (just-indent-offset 4)
  )

(provide 'just-mode-init)
;;; just-mode-init.el ends here
