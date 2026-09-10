;;; rust-mode-init.el --- rust settings -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package rust-mode
  :commands rust-mode
  :custom
  (rust-indent-offset 8)
  )

(setopt rust-ts-indent-offset 4) ;; ts-mode counterpart of rust-indent-offset

;; lsp settings
(setopt
  ;; must be the symbol, lsp-rust compares it with `eq'
  lsp-rust-server 'rust-analyzer
  lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial"
  lsp-rust-analyzer-display-chaining-hints t
  lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names nil
  lsp-rust-analyzer-display-closure-return-type-hints t
  lsp-rust-analyzer-display-parameter-hints nil
  lsp-rust-analyzer-display-reborrow-hints "never")

;; cargo minor mode
(use-package cargo
  :commands cargo-minor-mode
  )

;; flycheck for rust
(use-package flycheck-rust
  :commands flycheck-rust-setup
  :hook ((rust-mode    . flycheck-rust-setup)
          (rust-ts-mode . flycheck-rust-setup))
  )

(provide 'rust-mode-init)
;;; rust-mode-init.el ends here
