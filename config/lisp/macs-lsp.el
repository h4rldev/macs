;;; macs-lsp.el --- LSP Specifics - -*- lexical-binding: t; -*-
;;; Commentary:
;;; Sets up eglot for general lsp use,
;;; And sets up elisp linting.
;;;
;;; Code:

(require 'eglot)

;;; LSP
(setq eglot-autoshutdown t
      eglot-sync-connect 1
      eglot-events-buffer-config '(:size 0 :format full)
      flymake-inline-diagnostics 'short)

(add-hook 'emacs-lisp-mode-hook #'flymake-mode)

(defun macs-trust-dir ()
  "Trust the current project (or directory) for elisp compilation, persistently."
  (interactive)
  (let ((dir (file-name-as-directory
              (abbreviate-file-name
               (if-let* ((proj (project-current)))
                   (project-root proj)
                 default-directory)))))
    (add-to-list 'trusted-content dir)
    (customize-save-variable 'trusted-content trusted-content)
    (when (bound-and-true-p flymake-mode)
      (flymake-mode -1)
      (flymake-mode 1))
    (message "Trusted %s" dir)))

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
;;; macs-lsp.el ends here
