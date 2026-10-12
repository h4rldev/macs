;;; macs-terminals.el --- Configures vterm and sets up 3 terminal windows. - -*- lexical-binding: t; -*-
;;; Commentary:
;;; Sets up 3 terminal types:
;;; - Floating
;;; - Vertical
;;; - Horizontal
;;; And binds under C-c t
;;;
;;; Code:

(require 'vterm)
(require 'project)
(require 'treemacs)
(require 'catppuccin-theme)

(setenv "COLORTERM" "truecolor")
(setq vterm-max-scrollback 100000
      vterm-kill-buffer-on-exit t
      vterm-term-environment-variable "xterm-256color")

(with-eval-after-load 'catppuccin-theme
  (set-face-attribute 'child-frame-border nil
                      :background (catppuccin-color 'teal)))
(setq-default cursor-type 'bar)

(defun macs--vterm-root ()
  "Root directory for terminals.
The treemacs root when an explorer is open, else the current project root."
  (or (ignore-errors
        (treemacs-project->path
         (car (treemacs-workspace->projects (treemacs-current-workspace)))))
      (when-let* ((proj (project-current)))
        (project-root proj))
      default-directory))

(defun macs--vterm-name (id)
  "Buffer name for the ID terminal, scoped to the current project."
  (format "*vterm:%s:%s*" id
          (abbreviate-file-name (directory-file-name (macs--vterm-root)))))

(defun macs--vterm (name)
  "Return a vterm buffer NAME, starting a shell in it if needed."
  (require 'vterm)
  (let ((buf (get-buffer-create name)))
    (with-current-buffer buf
      (unless (derived-mode-p 'vterm-mode)
        (setq default-directory (file-name-as-directory (macs--vterm-root)))
        (vterm-mode))
      (display-line-numbers-mode -1)
      (setq-local mode-line-format nil))
    buf))

(defun macs--vterm-toggle (id side)
  "Toggle the ID terminal for the current project in a SIDE window."
  (let* ((name (macs--vterm-name id))
         (buf (get-buffer name))
         (win (and buf (get-buffer-window buf))))
    (if win
        (delete-window win)
      (select-window
       (display-buffer
        (macs--vterm name)
        (if (eq side 'below)
            `((display-buffer-reuse-window display-buffer-below-selected)
              (window-height . 0.3))
          `((display-buffer-reuse-window display-buffer-in-side-window)
            (side . ,side)
            (window-width . 0.4))))))))

(defun macs-vterm-vertical ()
  "Toggle a terminal on the right, keeping its session."
  (interactive)
  (macs--vterm-toggle "right" 'right))

(defun macs-vterm-horizontal ()
  "Toggle a terminal below, keeping its session."
  (interactive)
  (macs--vterm-toggle "below" 'below))

(defun macs--center-frame (frame)
  "Center child FRAME over its parent frame."
  (let ((parent (frame-parent frame)))
    (when parent
      (set-frame-position
       frame
       (round (/ (- (frame-pixel-width parent) (frame-pixel-width frame)) 2.0))
       (round (/ (- (frame-pixel-height parent) (frame-pixel-height frame)) 2.0))))))

(defun macs--keep-frame-centered (_)
  "Recenter every macs floating vterm frame on its parent."
  (dolist (frame (frame-list))
    (when (and (frame-live-p frame)
               (frame-parameter frame 'macs-float)
               (frame-parent frame))
      (macs--center-frame frame))))

(add-hook 'window-size-change-functions #'macs--keep-frame-centered)

(defvar macs-vterm-float-frame nil
  "The live frame of the macs floating terminal, or nil.")

(defun macs-vterm-floating ()
  "Toggle a vterm in a centered floating child frame, keeping its buffer."
  (interactive)
  (if (and (frame-live-p macs-vterm-float-frame)
           (frame-parent macs-vterm-float-frame))
      (progn
        (select-frame-set-input-focus (frame-parent macs-vterm-float-frame))
        (delete-frame macs-vterm-float-frame)
        (setq macs-vterm-float-frame nil))
    (let* ((buf (macs--vterm (macs--vterm-name "float")))
           (win (display-buffer
                 buf
                 '((display-buffer-reuse-window display-buffer-in-child-frame)
                   (child-frame-parameters
                    . ((minibuffer . nil)
                       (undecorated . t)
                       (width . 0.6)
                       (height . 0.4)
                       (internal-border-width . 2)
                       (left-fringe . 0)
                       (right-fringe . 0))))))
           (frame (window-frame win)))
      (setq macs-vterm-float-frame frame)
      (set-frame-parameter frame 'macs-float t)
      (macs--center-frame frame)
      (select-frame-set-input-focus frame))))

(defun macs-vterm-kill-ring-save ()
  "Copy the active region; with none, enter `vterm-copy-mode' to select."
  (interactive)
  (if (use-region-p)
      (kill-ring-save (region-beginning) (region-end))
    (vterm-copy-mode 1)
    (message "Copy mode: select text, then M-w")))

(keymap-set vterm-mode-map "M-w" #'macs-vterm-kill-ring-save)

(defun macs--vterm-exited (buf _event)
  "Close the window (or child frame) showing BUF when its shell exits."
  (when-let* ((win (and (buffer-live-p buf) (get-buffer-window buf t))))
    (let ((frame (window-frame win)))
      (if (frame-parameter frame 'macs-float)
          (progn
            (setq macs-vterm-float-frame nil)
            (delete-frame frame))
        (delete-window win)))))

(add-hook 'vterm-exit-functions #'macs--vterm-exited)

(define-key global-map (kbd "C-c t v") #'macs-vterm-vertical)
(define-key global-map (kbd "C-c t h") #'macs-vterm-horizontal)
(define-key global-map (kbd "C-c t f") #'macs-vterm-floating)
(repeat-mode 1)

(provide 'macs-terminals)
;;; macs-terminals.el ends here.
