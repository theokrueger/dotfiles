;;; util-init.el --- utility functions used by other files
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

(provide 'util-init)
;;; util-init.el ends here
