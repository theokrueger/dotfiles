;;; minibuffer-init.el --- settings for the minibuffer -*- lexical-binding: t -*-
;;; Commentary:
;;; Taken significantly from Emacs Bedrock
;;; Code:

(setopt enable-recursive-minibuffers t)                ;; Use the minibuffer whilst in the minibuffer
(setopt completion-cycle-threshold 1)                  ;; TAB cycles candidates
(setopt completions-detailed t)                        ;; Show annotations
(setopt tab-always-indent 'complete)                   ;; When I hit TAB, try to complete, otherwise, indent
(setopt completion-styles '(basic initials substring)) ;; Different styles to match input to candidates

(setopt minibuffer-visible-completions t)              ;; Use ↑↓ to select candidates
(setopt completion-auto-help 'always)                  ;; Open completion always; `lazy' another option
(setopt completions-max-height 20)                     ;; This is an arbitrary value
(setopt completions-format 'one-column)                ;; Makes it easier to scroll
(setopt completions-group t)

;; Eager completion setup: show *Completions* buffer immediately
(setopt completion-auto-select 'second-tab)            ;; Much more eager
(setopt completion-eager-display t)                    ;; Show the completions buffer immediately
(setopt completion-eager-update t)                     ;; Update display as-you-type

(completion-preview-mode) ;; automatic inline completion previews

(keymap-set minibuffer-mode-map "TAB" 'minibuffer-complete) ;; TAB acts more like how it does in the shell

(provide 'minibuffer-init)
;;; minibuffer-init.el ends here
