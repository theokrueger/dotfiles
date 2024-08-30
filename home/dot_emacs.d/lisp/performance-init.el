;; performance-init.el
;; settings relating to performance of emacs

;; garbage collector settings
(setq-default
  read-process-output-max (* 6 1024 1024) ;; 6mb process reads
  gc-cons-threshold most-positive-fixnum) ;; infinite gc threshold for startup

(add-hook 'emacs-startup-hook
  (lambda () (setq gc-cons-threshold (eval-when-compile(* 256 1024 1024))))) ;; 256 mb gc threshold after startup

;; few messages
(setq-default message-log-max 50)
;;(kill-buffer "*Messages*") ;; uncomment and set message-log-max to nil for no messages buffer

;; dont touch this
(provide 'performance-init)
