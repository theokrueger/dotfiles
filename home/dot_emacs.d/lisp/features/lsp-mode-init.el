;;; lsp-mode-init.el --- settings related to language server protocol -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:
(use-package lsp-mode
  :hook ((c-mode c-ts-mode c++-mode c++-ts-mode
           c-or-c++-mode c-or-c++-ts-mode          ;; clangd
           rust-mode rust-ts-mode                  ;; rust-analyzer
           python-mode python-ts-mode              ;; pylsp / pyright
           go-mode go-ts-mode java-mode java-ts-mode
           js-mode js-ts-mode js-jsx-mode          ;; typescript-language-server
           typescript-ts-mode tsx-ts-mode
           js-json-mode json-ts-mode               ;; vscode-json
           yaml-mode yaml-ts-mode                  ;; yaml-language-server
           sh-mode bash-ts-mode                    ;; bash-language-server
           html-mode html-ts-mode mhtml-mode       ;; vscode-html
           css-mode css-ts-mode                    ;; vscode-css
           conf-toml-mode toml-ts-mode             ;; taplo
           markdown-mode markdown-ts-mode          ;; marksman
           lua-mode lua-ts-mode dockerfile-mode dockerfile-ts-mode
           latex-mode LaTeX-mode)                  ;; texlab
          . lsp-deferred)
  :custom
  (lsp-auto-guess-root t)        ;; project.el finds the root, no import prompt
  (lsp-enable-snippet nil)       ;; yasnippet is not installed
  :bind
  ("C-x n i" . lsp-ui-imenu))

(use-package lsp-ui
  :commands (lsp-ui-mode
              lsp-ui-imenu)
  :custom
  (lsp-ui-peek-always-show t)
  ;; inline diagnostic text for the line at point only
  (lsp-ui-sideline-show-diagnostics nil)
  (lsp-ui-sideline-show-hover t)
  (lsp-ui-doc-position 'at-point))

(use-package helm-lsp
  :commands (helm-lsp-workspace-symbol
              helm-lsp-code-actions
              helm-lsp-diagnostics))

(provide 'lsp-mode-init)
;;; lsp-mode-init.el ends here
