;;; time-init.el --- settings related to time -*- lexical-binding: t -*-
;;; Commentary:
;;; Changes clock format and measures startup time
;;; Code:

;; display time mode in mode line
(setq-default
  display-time-default-load-average nil
  display-time-24hr-format t
  display-time-day-and-date t
  display-time-format "[%a] %F %H:%M:%S")

(display-time-mode 1)

;; measure init time benchmark
(message (concat "Startup took " (emacs-init-time)))

(provide 'time-init)
;;; time-init.el ends here
