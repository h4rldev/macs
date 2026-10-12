;;; macs-erlang.el --- Erlang indentation -*- lexical-binding: t; -*-
;;; Commentary:
;;; Erlang buffers (incl. erlang-ts-mode) use the classic erlang-mode
;;; indentation engine; record fields indent one level in.
;;; Ported from petring's .dir-locals.el.
;;;
;;; Code:

(defvar erlang-indent-level)

(defun macs-erlang--record-context ()
  "Return `close', `field', or nil for the current line."
  (save-excursion
    (beginning-of-line)
    (let ((bol (point))
          (close (looking-at "[ \t]*})[ \t]*\\.")))
      (when (re-search-backward "^[ \t]*-record\\b" nil t)
        (if (save-excursion
              (goto-char (match-beginning 0))
              (re-search-forward ")[ \t]*\\." bol t))
            nil
          (if close 'close 'field))))))

(defun macs-erlang--record-indent (orig)
  "Indent record fields by `erlang-indent-level' based on ORIG;
delegate otherwise."
  (let ((ctx (and (not (save-excursion
                         (beginning-of-line)
                         (looking-at "[ \t]*-record\\b")))
                  (macs-erlang--record-context))))
    (cond
     ((eq ctx 'close)
      (let ((old (current-indentation)))
        (indent-line-to 0)
        (- old)))
     ((eq ctx 'field)
      (let ((old (current-indentation)))
        (indent-line-to erlang-indent-level)
        (- erlang-indent-level old)))
     (t (funcall orig)))))

;; erlang-indent-region has its own parser and bypasses `erlang-indent-line'.
;; Nil falls back to the generic line-by-line indenter, so the advice applies.
(defun macs-erlang--region ()
  "Make `indent-region' use the per-line indenter, so the advice applies."
  (setq-local indent-region-function nil))

(with-eval-after-load 'erlang
  (setq erlang-indent-level 2)
  (advice-add 'erlang-indent-line :around #'macs-erlang--record-indent)
  (add-hook 'erlang-mode-hook #'macs-erlang--region)
  (add-hook 'erlang-ts-mode-hook #'macs-erlang--region))

;; rebar.config(.script) is Erlang term syntax; `conf-mode' otherwise claims
;; the `.config' suffix and opens it as a Unix config.
(add-to-list 'auto-mode-alist '("rebar\\.config\\(?:\\.script\\)?\\'" . erlang-mode))

(provide 'macs-erlang)
;;; macs-erlang.el ends here.
