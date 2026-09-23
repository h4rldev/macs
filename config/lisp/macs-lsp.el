;;; -*- lexical-binding: t; -*-

                                        ; === === === === === === ;
                                        ;        macs lsp         ;
                                        ;                         ;
                                        ;       eglot setup       ;
                                        ;                         ;
                                        ; === === === === === === ;

;;; LSP
(setq eglot-autoshutdown t
      eglot-sync-connect 1
      eglot-events-buffer-size 0
      flymake-show-diagnostics-at-end-of-line 'short)

(defun macs-eglot-maybe ()
  "Run `eglot-ensure' only when a server is known for the mode."
  (require 'eglot)
  (when (cdr (eglot--lookup-mode major-mode))
    (eglot-ensure)))

(add-hook 'prog-mode-hook #'macs-eglot-maybe)
(with-eval-after-load 'eglot
  (define-key eglot-mode-map (kbd "C-c a") #'eglot-code-actions)
  (define-key eglot-mode-map (kbd "C-c f") #'eglot-format-buffer)
  (define-key eglot-mode-map (kbd "C-c r") #'eglot-rename))

(provide 'macs-lsp)
