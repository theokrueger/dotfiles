;; cxx-init.el
;; c/c++/cxx settings

;; 8 space tabs
(setq-default
  indent-tabs-mode nil
  indent-line-function 'insert-tab
  tab-stop-list (number-sequence 8 160 8)
  tab-width 8)
(add-hook 'text-mode-hook
      (lambda() (setq indent-line-function 'insert-tab)))

;; dont touch this
(provide 'lang-common-init)
