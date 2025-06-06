;;; python-mode-init.el --- settings related to python programming mode -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:
(setq-default
  ;; 4 space tabs because of black
  python-indent-offset 4
  ;; python version
  pythol-shell-interpreter "python3")

(provide 'python-mode-init)
;;; python-mode-init.el ends here
