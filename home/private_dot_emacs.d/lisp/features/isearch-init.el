;;; isearch-init.el --- init settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Significant portions of this configuration are from Emacs Bedrock.
;;; Code:

(use-package isearch
  :ensure nil                           ; already installed
  :bind
  (:map isearch-mode-map
    ("C-." . isearch-forward-thing-at-point)) ; Search for thing under cursor
  :custom
  (lazy-count-prefix-format "(%s/%s) ")
  (isearch-lazy-count t)                 ; show match count
  (isearch-allow-motion t)
  (isearch-allow-scroll t)               ; lets you scroll without breaking search
  (isearch-repeat-on-direction-change t) ; C-r immediately goes to previous match
  (isearch-wrap-pause 'no-ding)          ; Automatically wrap search to top
  )

(provide 'isearch-init)
;;; isearch-init.el ends here
