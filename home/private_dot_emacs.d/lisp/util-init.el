;;; util-init.el --- utility functions used by other files -*- lexical-binding: t -*-
;;; Commentary:
;;; This file contains general use functions used in other files
;;; Code:

;; read file to string
(defun file-to-string (filename)
  "Return the contents of FILENAME as a string."
  (with-temp-buffer
    (insert-file-contents filename)
    (buffer-string)))

;; package to globally bind a key
(use-package bind-key
  :demand t)

(provide 'util-init)
;;; util-init.el ends here
