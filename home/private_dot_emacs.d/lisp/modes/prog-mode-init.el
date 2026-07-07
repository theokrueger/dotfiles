;;; prog-mode-init.el --- settings for all programming modes -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; style settings
(setq
  c-default-style '(
                     (java-mode . "java")
                     (awk-mode  . "awk")
                     (other     . "linux")
                     )
  )

;; indentation settings
(setq
  indent-tabs-mode nil
  indent-line-function 'insert-tab
  tab-stop-list (number-sequence 8 160 8)
  tab-width 8
  standard-indent 8)
(global-set-key (kbd "RET") 'newline-and-indent)

;; rainbow delimiters
(require-package 'rainbow-delimiters)
(use-package rainbow-delimiters
  :defer t
  :commands rainbow-delimiters-mode
  :custom-face
  (rainbow-delimiters-depth-1-face ((t (:inherit rainbow-delimiters-base-face :foreground "dim gray"))))
  (rainbow-delimiters-depth-2-face ((t (:inherit rainbow-delimiters-base-face :foreground "magenta2"))))
  (rainbow-delimiters-depth-3-face ((t (:inherit rainbow-delimiters-base-face :foreground "orange"))))
  (rainbow-delimiters-depth-4-face ((t (:inherit rainbow-delimiters-base-face :foreground "yellow"))))
  (rainbow-delimiters-depth-5-face ((t (:inherit rainbow-delimiters-base-face :foreground "dark green"))))
  (rainbow-delimiters-depth-6-face ((t (:inherit rainbow-delimiters-base-face :foreground "royal blue"))))
  (rainbow-delimiters-depth-7-face ((t (:inherit rainbow-delimiters-base-face :foreground "dark violet"))))
  (rainbow-delimiters-depth-8-face ((t (:inherit rainbow-delimiters-base-face :foreground "hot pink"))))
  (rainbow-delimiters-depth-9-face ((t (:inherit rainbow-delimiters-base-face :foreground "light cyan"))))
  (rainbow-delimiters-mismatched-face ((t (:inherit rainbow-delimiters-unmatched-face :foreground "red" :weight bold))))
  (rainbow-delimiters-unmatched-face ((t (:inherit rainbow-delimiters-base-error-face :foreground "red" :weight bold))))
  :init
  (show-paren-mode 1) ;; highlight matching delimiters
  :hook (prog-mode . rainbow-delimiters-mode)
  )


;; indent highlighting
(require-package 'highlight-indent-guides)
(use-package highlight-indent-guides
  :defer t
  :commands highlight-indent-guides-mode
  :hook (prog-mode . highlight-indent-guides-mode)
  )

;; symbol overlays
(require-package 'symbol-overlay)
(use-package symbol-overlay
  :defer t
  :commands symbol-overlay-mode
  :hook (prog-mode . symbol-overlay-mode)
  :bind (
          ("M-i" . symbol-overlay-put)
          ("M-n" . symbol-overlay-switch-forward)
          ("M-p" . symbol-overlay-switch-backward)
          )
  )

;; shift lines up and down
(require-package 'move-dup)
(use-package move-dup
  :defer t
  :commands (
              move-dup-move-lines-up move-dup-move-lines-down
              )
  :bind (
          ("M-<up>"   . move-dup-move-lines-up)
          ("M-<down>" . move-dup-move-lines-down)
          )
  )

;; folding
(require-package 'hideshow)
(use-package hideshow
  :defer t
  :hook (prog-mode . hs-minor-mode)
  :bind
  (
    ("C-c f" . hs-toggle-hiding)
    ("C-c M-F" . hs-hide-all)
    ("C-c M-f" . hs-show-all)
    )
  )


(provide 'prog-mode-init)
;;; prog-mode-init.el ends here
