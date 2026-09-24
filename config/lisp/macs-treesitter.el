;;; macs-treesitter.el --- Treesitter Specifics - -*- lexical-binding: t; -*-
;;; Commentary:
;;; Sets up treesitter for general lsp use,
;;; Asks for grammar installation when required.
;;;
;;; Code:

(require 'treesit)

;; Emacs 31 behaviour: open files in their *-ts-mode whenever a grammar
;; is available, and offer to install it when it isn't.  `setopt' (not
;; `setq') so the option's :set fills `major-mode-remap-alist'.
(setopt treesit-enabled-modes t)
(setopt treesit-auto-install-grammar 'ask)

;; Nix ships no built-in tree-sitter mode; drive the third-party
;; `nix-ts-mode' through the same install-and-open dance.
(declare-function nix-ts-mode "nix-ts-mode")

(when (locate-library "nix-ts-mode")
  (add-to-list 'treesit-language-source-alist
               '(nix "https://github.com/nix-community/tree-sitter-nix"))

  (defun macs-nix-ts-mode-maybe ()
    "Use `nix-ts-mode' for Nix files, installing the grammar if needed."
    (when (and (treesit-ensure-installed 'nix)
               (treesit-ready-p 'nix t))
      (nix-ts-mode)))

  (add-to-list 'auto-mode-alist '("\\.nix\\'" . macs-nix-ts-mode-maybe)))

(provide 'macs-treesitter)
;;; macs-treesitter.el ends here
