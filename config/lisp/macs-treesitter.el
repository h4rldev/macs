;;; macs-treesitter.el --- Treesitter Specifics - -*- lexical-binding: t; -*-
;;; Commentary:
;;; Sets up treesitter for general lsp use,
;;; Asks for grammar installation when required.
;;;
;;; Code:

(require 'treesit)
(require 'treesit-auto)
(require 'kdl-mode)

;; Emacs' built-in markdown-ts-mode is experimental and needs a second
;; grammar (`markdown-inline') that treesit-auto does not manage; use the
;; mature `markdown-mode' instead, so drop markdown from treesit-auto.
(setq treesit-auto-recipe-list
      (seq-remove (lambda (r) (eq (treesit-auto-recipe-lang r) 'markdown))
                  treesit-auto-recipe-list))

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

;; kdl-mode auto-installs a grammar; pin v2.0.0 so we get KDL v2, not v1.
(add-to-list 'treesit-language-source-alist
             '(kdl "https://github.com/tree-sitter-grammars/tree-sitter-kdl" "v2.0.0" "src"))

;; kdl-mode's `node_field_comment' rule is malformed; its nested query
;; hangs Emacs's query compiler.  The flat patterns match the same nodes.
(with-eval-after-load 'kdl-mode
  (setq kdl-treesit-font-locks
        (mapcar
         (lambda (setting)
           (let* ((query (treesit-font-lock-setting-query setting))
                  (source (if (treesit-compiled-query-p query)
                              (treesit-query-source query)
                            query)))
             (when (string-match-p "node_field_comment" (prin1-to-string source))
               (setcar setting
                       '((node_comment) @font-lock-comment-face
                         (node_field_comment) @font-lock-comment-face
                         (node_children_comment) @font-lock-comment-face))))
           setting)
         kdl-treesit-font-locks)))

(add-to-list 'auto-mode-alist '("\\.\\(csproj\\|props\\|targets\\)\\'" . nxml-mode))
;; erlang-ts' `builtin' and `guards' features hand OTP's Emacs-syntax regexps
;; to tree-sitter's :match predicate; libtree-sitter 0.26 segfaults on them
;; during font-lock. Drop just those two features.
(defun macs-erlang-ts--font-lock-setup ()
  "Disable erlang-ts features that crash tree-sitter 0.26."
  (treesit-font-lock-recompute-features nil '(builtin guards)))
(add-hook 'erlang-ts-mode-hook #'macs-erlang-ts--font-lock-setup)

(add-to-list 'major-mode-remap-alist '(erlang-mode . erlang-ts-mode))

(provide 'macs-treesitter)
;;; macs-treesitter.el ends here
