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

;; dont display line numbers in these modes
(let ((undisp (lambda ()
                (display-line-numbers-mode -1)
                ;; buffer-local: `column-number-mode' is a global mode, so
                ;; calling the command here would disable it everywhere
                (setq-local column-number-mode nil))))
  (dolist (mode '(term-mode-hook
                   eshell-mode-hook
                   pdf-view-mode-hook))
    (add-hook mode undisp)))

;; highlight line mode
(setopt global-hl-line-sticky-flag 'window)
(global-hl-line-mode 1)

;; save place in files
(save-place-mode 1)

;; reload unmodified buffers when file changed
(setopt
  auto-revert-avoid-polling t
  auto-revert-interval 5
  auto-revert-check-vc-info t)
(global-auto-revert-mode 1)

;; save history of minibuffer
(savehist-mode 1)

;; remove trailing whitespaces
;; NB: `fundamental-mode' does not run `fundamental-mode-hook', so hooking
;; the mode there (or in a hook that never runs) would never activate it.
(use-package whitespace-cleanup-mode
  :hook (after-init . global-whitespace-cleanup-mode))

;; settings
(setopt
  ;; navigation
  sentence-end-double-space nil
  ;; search function
  search-highlight t         ;; highlight matches
  search-whitespace-regexp "[ \t\n]+" ;; a space matches any whitespace run
  ;; kill
  save-interprogram-paste-before-kill t ;; save clipboard to killring
  kill-do-not-save-duplicates t         ;; dedup killring
  )

;; all confirmation prompts use y/n
(setopt use-short-answers t)

;; don't ping url-looking things when running find-file
(setopt ffap-machine-p-known 'reject)

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

;; redefine hspace as leading space
(setopt whitespace-hspace-regexp "\\(^ +\\)")

(with-eval-after-load 'whitespace
  (set-face-attribute 'whitespace-hspace nil
    :foreground (face-foreground 'window-divider-first-pixel nil t)
    :background 'unspecified)
  (set-face-attribute 'whitespace-space nil
    :foreground (face-background 'default nil t)
    :background 'unspecified)
  (set-face-attribute 'whitespace-trailing nil
    :foreground 'unspecified
    :background (face-foreground 'ansi-color-bright-red nil t))
  )

;; filter for buffer cycling
(defcustom cyclable-buffer-exclude-regexps
  '("\\`\\*helm"             ;; *helm M-x*, *helm find-files*, ...
     "\\`\\*Messages\\*"
     "\\`\\*Backtrace\\*"
     "\\`\\*Warnings\\*"
     "\\`\\*Compile-Log\\*"
     "\\`\\*Flycheck errors\\*")
  "Regexps for buffers to skip when cycling with `next-buffer'."
  :type '(repeat regexp)
  :group 'convenience)

(defun cyclable-buffer-p (buffer)
  "Return non-nil if BUFFER should be reachable when cycling buffers."
  (not (seq-some (lambda (regexp) (string-match-p regexp (buffer-name buffer)))
         cyclable-buffer-exclude-regexps)))

(add-to-list 'default-frame-alist '(buffer-predicate . cyclable-buffer-p))
(set-frame-parameter nil 'buffer-predicate #'cyclable-buffer-p)

(provide 'fundamental-mode-init)
;;; fundamental-mode-init.el ends here
