;;; macs-treesitter.el --- Treesitter Specifics - -*- lexical-binding: t; -*-
;;; Commentary:
;;; Sets up treesitter for general lsp use,
;;; Asks for grammar installation when required.
;;;
;;; Code:

(require 'treesit)
(require 'treesit-auto)

;; treesit-auto owns mode selection: a file opens in its base mode, is
;; remapped to the *-ts-mode once the grammar is ready, and prompts to
;; install the grammar when it is missing.
(setopt treesit-auto-install 'prompt)
(setopt treesit-auto-install-grammar 'ask)

(global-treesit-auto-mode 1)

;; Expose treesit-auto's whole recipe catalog so
;; `M-x treesit-install-language-grammar` can install any language by hand.
(setq treesit-language-source-alist
      (treesit-auto--build-treesit-source-alist))

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

;; `glsl-ts-mode' inherits c-ts-mode's "C++" mode-line; relabel it.
(with-eval-after-load 'glsl-ts-mode
  (add-hook 'glsl-ts-mode-hook (lambda () (setq-local mode-name "GLSL"))))

(provide 'macs-treesitter)
;;; macs-treesitter.el ends here
