;;; compile-init.el --- settings related to bytecode and native compilation -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(setq-default
  package-native-compile t        ;; native compile packages
  native-comp-always-compile t    ;; always compile with native comp
  native-comp-async-jobs-number 0 ;; native compile using half of cpu threads
  native-comp-speed 3             ;; use -O3 optimisation for native comp
  load-prefer-newer t             ;; load most recent version of a file
  compilation-ask-about-save nil) ;; do not ask to save for compile command

(provide 'compile-init)
;;; compile-init.el ends here
