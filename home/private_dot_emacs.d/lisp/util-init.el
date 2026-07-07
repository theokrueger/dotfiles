;;; util-init.el --- utility functions used by other files -*- lexical-binding: t -*-
;;; Commentary:
;;; This file contains general use functions used in other files
;;; Code:

;; does [x] exist functions
(defun window-exist-p (window)
  "Return t if WINDOW exists."
  (and window (window-live-p window)))

(defun buffer-exist-p (buffer)
  "Return t if BUFFER exists."
  (and buffer (buffer-live-p buffer)))

;; read file to string
(defun file-to-string (filename)
  "Return the contents of FILENAME as a string."
  (with-temp-buffer
    (insert-file-contents filename)
    (buffer-string)))

;; package to globally bind a key
(require-package 'bind-key)
(use-package bind-key
  :defer t
  :commands bind-key*
  )

(provide 'util-init)
;;; util-init.el ends here
