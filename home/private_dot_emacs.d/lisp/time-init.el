;;; time-init.el --- settings related to time -*- lexical-binding: t -*-
;;; Commentary:
;;; Changes clock format and measures startup time
;;; Code:

;; display time mode in mode line
(setopt
  display-time-default-load-average nil
  display-time-day-and-date nil)
(display-time-mode 1)

(add-hook 'after-init-hook
  (lambda () (message "Startup took %s" (emacs-init-time))))

(provide 'time-init)
;;; time-init.el ends here
