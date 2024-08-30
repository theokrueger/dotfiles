;; time-init.el
;; time measurement and benchmarking of initialisation time

;; display time mode in mode line
(setq-default display-time-default-load-average nil)
(setq-default display-time-24hr-format t)
(setq-default display-time-day-and-date t)
(setq-default display-time-format "%H:%M %a %b %d")
(display-time-mode 1)

;; measure init time benchmark
(message (concat "Startup took " (emacs-init-time)))

;; dont touch this
(provide 'time-init)
