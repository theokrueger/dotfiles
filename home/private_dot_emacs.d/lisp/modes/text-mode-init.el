;;; text-mode-init.el --- general text editor settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; line numbers
(column-number-mode)
(global-display-line-numbers-mode t)
(let ((undisp (lambda () (display-line-numbers-mode nil))))
  (dolist (mode '(term-mode-hook
                   pdf-mode-hook
                   eshell-mode-hook))
    (add-hook mode undisp))) ;; dont display linenumbers in these modes

;; highlight line mode
(global-hl-line-mode 1)

;; save place in files
(save-place-mode 1)

;; reload unmodified buffers when file changed
(global-auto-revert-mode 1)

;; remove trailing whitespaces
(require-package 'whitespace-cleanup-mode)
(use-package whitespace-cleanup-mode
  :defer t
  :commands whitespace-cleanup-mode
  :hook (text-mode . whitespace-cleanup-mode)
  )

;; settings
(setq
  ;; navigation
  sentence-end-double-space nil
  ;; enable line wrapping
  truncate-lines nil
  ;; search function
  case-fold-search t         ;; case-insensitive search
  search-highlight t         ;; highlight matches
  search-whitespace-regexp t ;; search inc whitespace
  ;; reload buffers on file change
  global-auto-revert-non-file-buffers t)

;; below from https://emacs.stackexchange.com/questions/82485/whitespace-mode-only-display-leading-whitespace
;; Use · for spaces
(setq whitespace-display-mappings
  '(
     (space-mark ?\ [?·] [?·] [?.])
     (tab-mark ?\t [187 ?\t] [62 ?\t])
     ))

;; Enable for programming modes
(add-hook 'prog-mode-hook #'whitespace-mode)

;; Enable everything
(setq whitespace-style
  '(face
     tabs
     tab-mark
     spaces
     space-mark
     trailing))

;; Redefine hspace as leading space
(setq whitespace-hspace-regexp "\\(^ +\\)")x

(with-eval-after-load 'whitespace
  (set-face-attribute 'whitespace-hspace nil
    :foreground (face-foreground 'window-divider-first-pixel nil t)
    :background nil)
  (set-face-attribute 'whitespace-space nil
    :foreground (face-background 'default nil t)
    :background nil)
  (set-face-attribute 'whitespace-trailing nil
    :foreground nil
    :background (face-foreground 'ansi-color-bright-red nil t))
  )

(provide 'text-mode-init)
;;; text-mode-init.el ends here
