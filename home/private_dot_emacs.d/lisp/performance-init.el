;;; performance-init.el --- settings relating to performance of emacs -*- lexical-binding: t -*-
;;; Commentary:
;;; Designed to reduce startup time, does not focus on memory usage too hard
;;; Code:

;; garbage collector settings
(setq-default
  read-process-output-max (* 24 1024 1024) ;; 24mb process reads
  gc-cons-threshold most-positive-fixnum)  ;; infinite gc threshold for startup

(add-hook 'after-init-hook
  (lambda ()
    ;; revert `file-name-handler-alist` for performance
    (setq-default file-name-handler-alist
      ;; merge instead of overwrite
      (delete-dups (append file-name-handler-alist fnh-alist-old)))
    (makunbound 'fnh-alist-old)

    ;; 256 mb gc threshold after startup
    (setq-default gc-cons-threshold (eval-when-compile(* 256 1024 1024)))))

;; gcmh
(require-package 'gcmh)
(use-package gcmh)
(gcmh-mode 1)

;; few messages
(setq-default message-log-max 200)
;;(kill-buffer "*Messages*") ;; uncomment and set message-log-max to nil for no messages buffer

(provide 'performance-init)
;;; performance-init.el ends here
