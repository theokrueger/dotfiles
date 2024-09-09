;; util-init.el
;; utility functions

;; exist funcs
(defun window-exist-p (window)
  "return t if window exists."
  (and window (window-live-p window)))

(defun buffer-exist-p (buffer)
  "return t if buffer exists."
  (and buffer (buffer-live-p buffer)))

;; dont touch this
(provide 'util-init)
