;;; tui-init.el --- settings related to the emacs TUI
;;; Commentary:
;;; settings that overlap between TUI and GUI belong in GUI settings
;;; Code:

;; terminal mouse support
(require 'mouse)
(xterm-mouse-mode t)
(gpm-mouse-mode t)

(provide 'tui-init)
;;; tui-init.el ends here
