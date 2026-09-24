;;; macs-clipboard.el --- Clipboard patch for PGTK -*- lexical-binding: t; -*-
;;; Commentary:
;;; Emacs' native pgtk clipboard write is unreliable: kills frequently
;;; never show up in other apps' paste buffers (M-w reports success but
;;; the system clipboard stays empty).  wl-copy always lands the text on
;;; the Wayland clipboard, from both GUI and TTY frames, so route kills
;;; through it.  Paste still uses Emacs' native reader.
;;;
;;; Code:

(defun macs-clipboard--copy (text &rest _)
  "Copy TEXT to the Wayland clipboard via wl-copy.
Extra args are ignored, matching `interprogram-cut-function'."
  (when (and select-enable-clipboard (stringp text) (> (length text) 0))
    (with-temp-buffer
      (insert text)
      (call-process-region (point-min) (point-max) "wl-copy" nil 0 nil))))

(setq interprogram-cut-function
      (if (executable-find "wl-copy")
          #'macs-clipboard--copy
        #'gui-select-text))

(provide 'macs-clipboard)
;;; macs-clipboard.el ends here.
