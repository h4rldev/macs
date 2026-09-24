;;; macs-ui.el --- UI specifics, fonts, themes, etc. -*- lexical-binding: t; -*-
;;; Commentary:
;;; Sets up the catppuccin theme, along with chrome,
;;; and modes such as winner and builtins.
;;;
;;; Code:

(require 'display-line-numbers)
(require 'catppuccin-theme)
(require 'nerd-icons-dired)
(require 'embark)
(require 'apheleia)
(require 'winner)

;;; Theme
(setq catppuccin-flavor 'mocha)
(add-to-list 'custom-theme-load-path (file-name-directory (locate-library "catppuccin-theme")))
(unless (custom-theme-enabled-p 'catppuccin)
  (load-theme 'catppuccin t))

;;; UI chrome
(menu-bar-mode -1)
(tool-bar-mode -1)
(tab-bar-mode -1)
(scroll-bar-mode -1)

;;; Smooth scrolling + window layout
(pixel-scroll-precision-mode 1)
(winner-mode 1)
(global-set-key (kbd "C-c <left>")  #'winner-undo)
(global-set-key (kbd "C-c <right>") #'winner-redo)

;;; Files
(setq create-lockfiles nil
      backup-directory-alist `(("." . ,(expand-file-name "backups/" user-emacs-directory)))
      custom-file (expand-file-name "custom.el" user-emacs-directory)
      confirm-kill-processes nil)
(load custom-file 'noerror)

(setq auto-save-file-name-transforms
      `(("\\`/[^/]*:\\([^/]*/\\)*\\([^/]*\\)\\'" "/tmp/\\2" t)
        (".*" ,(expand-file-name "auto-save/" user-emacs-directory) t)))
(make-directory (expand-file-name "auto-save/" user-emacs-directory) t)


;;; Editing
(setq-default indent-tabs-mode nil)
(setq tab-always-indent 't
      completion-cycle-threshold 3
      sentence-end-double-space nil
      read-process-output-max (* 1024 1024))
(electric-pair-mode 1)
(show-paren-mode 1)
(delete-selection-mode 1)
(global-auto-revert-mode 1)
(save-place-mode 1)
(savehist-mode 1)
(global-display-line-numbers-mode 1)

(when (find-font (font-spec :family "Maple Mono NF"))
  (set-face-attribute 'default nil :font "Maple Mono NF" :height 105))

(setq display-line-numbers-type 'relative)

(defun macs-toggle-relative-line-numbers ()
  "Toggle absolute/relative line numbers in all buffers."
  (interactive)
  (setq display-line-numbers-type
        (if (eq display-line-numbers-type 'relative) t 'relative))
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when display-line-numbers-mode
        (setq display-line-numbers display-line-numbers-type))))
  (message "Line numbers: %s"
           (if (eq display-line-numbers-type 'relative) "relative" "absolute")))

(global-set-key (kbd "C-c l") #'macs-toggle-relative-line-numbers)

;;; Dired icons
(with-eval-after-load 'dired
  (require 'nerd-icons-dired)
  (nerd-icons-dired-mode 1))

;;; Key aliases (avoid Shift+number / AltGr on sv-SE)
(global-set-key (kbd "C-c q") #'query-replace)            ; M-%    (Shift+5)
(global-set-key (kbd "C-c Q") #'query-replace-regexp)     ; C-M-%  (Alt+Shift+5)
(global-set-key (kbd "C-c u") #'undo)                     ; C-/  C-_  (Shift+7 / Shift+-)
(global-set-key (kbd "C-c x") #'shell-command)            ; M-!    (Shift+1)
(global-set-key (kbd "C-c X") #'shell-command-on-region)  ; M-|    (AltGr+<)
(global-set-key (kbd "C-c v") #'eval-expression)          ; M-:    (Shift+.)
(global-set-key (kbd "C-c w") #'embark-dwim)              ; C-;    (Shift+,)
(global-set-key (kbd "C-c p") #'backward-paragraph)       ; M-{    (AltGr+7)
(global-set-key (kbd "C-c P") #'forward-paragraph)        ; M-}    (AltGr+0)
(global-set-key (kbd "C-c F") #'apheleia-format-buffer)

(provide 'macs-ui)
;;; macs-ui.el ends here.
