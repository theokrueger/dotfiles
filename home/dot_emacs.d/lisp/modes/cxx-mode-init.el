;;; cxx-mode-init.el --- c/c++/cxx settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(setopt
  tab-width 8                   ;; 8 column tab stops, as clang-format expects
  c-ts-mode-indent-style 'linux ;; kernel indentation rules, 8 columns wide
  c-ts-indent-offset 8          ;; 8 column indent (c-ts-mode, c++-ts-mode)
  )

(defun cxx-mode-init--use-spaces ()
  "Indent C/C++ buffers with spaces rather than tabs."
  (setq-local indent-tabs-mode nil))

(add-hook 'c-mode-common-hook #'cxx-mode-init--use-spaces) ;; c-mode, c++-mode
(add-hook 'c-ts-mode-hook     #'cxx-mode-init--use-spaces)
(add-hook 'c++-ts-mode-hook   #'cxx-mode-init--use-spaces)

(provide 'cxx-mode-init)
;;; cxx-mode-init.el ends here
