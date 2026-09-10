;;; fundamental-mode-init.el --- general text editor settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; disable RTL languages
(setopt bidi-paragraph-direction 'left-to-right)
(setopt bidi-inhibit-bpa t)

;; default mode for *scratch*
(setopt initial-major-mode 'fundamental-mode)

;; line numbers
(column-number-mode t)
(line-number-mode t)
(global-display-line-numbers-mode t)
(setopt display-line-numbers-width 3)

(let ((undisp (lambda () (display-line-numbers-mode nil) (column-number-mode nil))))
  (dolist (mode '(term-mode-hook
                   pdf-mode-hook
                   eshell-mode-hook))
    (add-hook mode undisp))) ;; dont display linenumbers in these modes

;; highlight line mode
(setopt global-hl-line-sticky-flag 'window)
(global-hl-line-mode 1)

;; save place in files
(save-place-mode 1)

;; reload unmodified buffers when file changed
(global-auto-revert-mode 1)

;; save history of minibuffer
(savehist-mode)

;; remove trailing whitespaces
(use-package whitespace-cleanup-mode
  :commands whitespace-cleanup-mode
  :hook (fundamental-mode . whitespace-cleanup-mode)
  )

;; settings
(setopt
  ;; navigation
  sentence-end-double-space nil
  ;; enable line wrapping
  truncate-lines nil
  ;; search function
  case-fold-search t         ;; case-insensitive search
  search-highlight t         ;; highlight matches
  search-whitespace-regexp t ;; search inc whitespace
  ;; kill
  save-interprogram-paste-before-kill t ;; save clipboard to killring
  kill-do-not-save-duplicates t         ;; dedup killring
  )

;; painful defaults
(setopt sentence-end-double-space nil)

;; all confirmation prompts use y/n
(setopt use-short-answers t)

;; don't ping url-looking things when running find-file
(setopt ffap-machine-p-known 'reject)

;; revert on bufchange
(setopt auto-revert-avoid-polling t)
(setopt auto-revert-interval 5)
(setopt auto-revert-check-vc-info t)
(global-auto-revert-mode)

;; other
(setopt x-underline-at-descent-line nil)           ; Prettier underlines
(setopt switch-to-buffer-obey-display-actions t)   ; Make switching buffers more consistent
(setopt show-trailing-whitespace t)      ; underline trailing spaces
(setopt indicate-buffer-boundaries 'left)  ; Show buffer top and bottom in the margin

;; below from https://emacs.stackexchange.com/questions/82485/whitespace-mode-only-display-leading-whitespace
;; Use · for spaces
(setopt whitespace-display-mappings
  '(
     (space-mark ?\ [?·] [?·] [?.])
     (tab-mark ?\t [187 ?\t] [62 ?\t])
     ))

;; Enable for programming modes
(add-hook 'prog-mode-hook #'whitespace-mode)

;; Enable everything
(setopt whitespace-style
  '(face
     tabs
     tab-mark
     spaces
     space-mark
     trailing))

;; Redefine hspace as leading space
(setopt whitespace-hspace-regexp "\\(^ +\\)")

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

(provide 'fundamental-mode-init)
;;; fundamental-mode-init.el ends here
