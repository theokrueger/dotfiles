;;; rust-init.el --- rust settings
;;; Commentary:
;;; none

;;; Code:

;; rust-mode
(require-package 'rust-mode)
(use-package rust-mode
  :defer t
  :commands rust-mode
  :hook (rust-mode-hook . lsp)
  :config
  (require-package 'cargo)
  (setq-default
    ;; rust-mode settings
    rust-format-on-save t
    ;; lsp settings
    lsp-rust-server "rust-analyzer"
    lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial"
    lsp-rust-analyzer-display-chaining-hints t
    lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names nil
    lsp-rust-analyzer-display-closure-return-type-hints t
    lsp-rust-analyzer-display-parameter-hints nil
    lsp-rust-analyzer-display-reborrow-hints nil)
  )

;; lsp for rust

;; flycheck for rust
(require-package 'flycheck-rust)
(use-package flycheck-rust
  :defer t
  :hook (
          (rust-mode-hook . flycheck-mode)
          (rust-mode-hook . flycheck-rust-setup)
          )
  )

(provide 'rust-init)
;;; rust-init.el ends here
