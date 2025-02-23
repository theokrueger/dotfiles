;;; format-all-init.el --- settings related to formatt-all package -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(require-package 'format-all)
(use-package format-all
  :commands format-all-mode
  :hook (prog-mode . format-all-mode)
  )

(provide 'format-all-init)
;;; format-all-init.el ends here
