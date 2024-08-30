;; text-mode-init.el
;; general text editor settings

;; line numbers
(column-number-mode)
(global-display-line-numbers-mode t)
(let ((undisp (lambda () (display-line-numbers-mode nil))))
  (dolist (mode '(term-mode-hook
                   eshell-mode-hook))
    (add-hook mode undisp))) ;; dont display linenumbers in these modes

;; wrapping
(setq-default truncate-lines nil) ;; enable line wrapping

;; highlight line mode
(global-hl-line-mode 1)

;; save place in files
(save-place-mode 1)

;; search function
(setq-default
  case-fold-search t          ;; case-insensitive search
  search-highlight t          ;; highlight matches
  search-whitespace-regexp t) ;; search inc whitespace

;; reload unmodified buffers when file changed
(global-auto-revert-mode 1)
(setq-default global-auto-revert-non-file-buffers t) ;; reload others buffer types too

;; trailing whitespace
(setq-default show-trailing-whitespace t)

;; dont touch this
(provide 'text-mode-init)
