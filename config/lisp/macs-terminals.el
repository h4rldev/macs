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
(require 'catppuccin-theme)

(setenv "COLORTERM" "truecolor")
(setq vterm-max-scrollback 100000
      vterm-kill-buffer-on-exit nil
      vterm-term-environment-variable "xterm-256color")

(with-eval-after-load 'catppuccin-theme
  (set-face-attribute 'child-frame-border nil
                      :background (catppuccin-color 'teal)))
(setq-default cursor-type 'bar)

(defun macs--vterm (name)
  "Return a live vterm buffer NAME, restarting it if its shell has exited."
  (require 'vterm)
  (let ((buf (get-buffer-create name)))
    (with-current-buffer buf
      (when (and (derived-mode-p 'vterm-mode)
                 (not (and vterm--process (process-live-p vterm--process))))
        (setq-local vterm--process nil))
      (unless (derived-mode-p 'vterm-mode)
        (vterm-mode))
      (display-line-numbers-mode -1)
      (setq-local mode-line-format nil))
    buf))

(defun macs--vterm-close-on-exit (buf _event)
  "Close the side window showing BUF when its shell exits.
Floating terminals live in child frames and are handled separately."
  (let ((win (and buf (get-buffer-window buf))))
    (when (and win (not (frame-parent (window-frame win))))
      (delete-window win))))

(defun macs--vterm-toggle (name side)
  "Toggle the NAME terminal in a SIDE window, keeping its buffer alive."
  (let* ((buf (get-buffer name))
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
            (window-width . 0.4)))))
      (with-current-buffer (get-buffer name)
        (add-hook 'vterm-exit-functions #'macs--vterm-close-on-exit nil t)))))

(defun macs-vterm-vertical ()
  "Toggle a terminal on the right, keeping its session."
  (interactive)
  (macs--vterm-toggle "*vterm:right*" 'right))

(defun macs-vterm-horizontal ()
  "Toggle a terminal below, keeping its session."
  (interactive)
  (macs--vterm-toggle "*vterm:below*" 'below))

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
    (let* ((buf (macs--vterm "*vterm:float*"))
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
      (with-current-buffer buf
        (add-hook 'vterm-exit-functions
                  (lambda (_buf _event)
                    (when (frame-live-p frame) (delete-frame frame))
                    (setq macs-vterm-float-frame nil))
                  nil t))
      (select-frame-set-input-focus frame))))


(define-key global-map (kbd "C-c t v") #'macs-vterm-vertical)
(define-key global-map (kbd "C-c t h") #'macs-vterm-horizontal)
(define-key global-map (kbd "C-c t f") #'macs-vterm-floating)
(repeat-mode 1)

(provide 'macs-terminals)
;;; macs-terminals.el ends here.
