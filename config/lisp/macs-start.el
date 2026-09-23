;;; -*- lexical-binding: t; -*-

                                        ; === === === === === === ;
                                        ;        macs start       ;
                                        ;                         ;
                                        ;       Start-screen      ;
                                        ;       specifics.        ;
                                        ;                         ;
                                        ; === === === === === === ;



;;; Start screen
(defgroup macs nil
  "macs start screen."
  :group 'emacs)

(defcustom macs-project-roots
  (or (seq-filter #'file-directory-p
                  (mapcar #'expand-file-name
                          '("~/projects" "~/Projects" "~/code" "~/src"
                            "~/dev" "~/repos" "~/git")))
      (list (expand-file-name "~/projects")))
  "Directories scanned for projects by the macs start screen.
  Set this to your projects directory, e.g. (list \"~/work\")."
  :type '(repeat directory)
  :group 'macs)

(defconst macs-start-recent-count 10
  "How many recent projects the macs dashboard shows by default.")

(defvar-local macs-start-show-all nil
  "When non-nil, the macs dashboard lists every known project.")

(defconst macs-start-banner
  '("  _____ _____    ____   ______"
    " /     \\\\__  \\ _/ ___\\ /  ___/"
    "|  Y Y  \\/ __ \\\\  \\___ \\___ \\ "
    "|__|_|  (____  /\\___  >____  >"
    "      \\/     \\/     \\/     \\/ ")
  "ASCII banner for the macs dashboard.")

(defface macs-title '((t :inherit default :weight extra-bold :height 1.4))
  "Face for the macs dashboard banner."
  :group 'macs)
(defface macs-dim '((t :inherit shadow))
  "Dimmed face for paths and hints on the macs dashboard."
  :group 'macs)

(defun macs-open-project (dir)
  "Make DIR the active project and open the explorer on it."
  (setq default-directory (file-name-as-directory dir))
  (treemacs-add-and-display-current-project-exclusively))

(defun macs-start--rows (projects)
  (mapcar (lambda (d)
            (let ((path (directory-file-name d)))
              (list (file-name-nondirectory path)
                    (abbreviate-file-name (file-name-directory path))
                    d)))
          projects))

(defvar macs-start--mtime-cache-file
  (expand-file-name "macs-projects.eld" user-emacs-directory)
  "Where the project mtime cache is persisted between sessions.")

(defvar macs-start--mtime-cache
  (when (file-readable-p macs-start--mtime-cache-file)
    (with-temp-buffer
      (insert-file-contents macs-start--mtime-cache-file)
      (read (current-buffer))))
  "Alist of (ROOT . MTIME-SECONDS), loaded from `macs-start--mtime-cache-file'.")

(defconst macs-start--skip-dirs
  '(".git" "node_modules" ".venv" "venv" "target" "build" "dist" ".cache"
    ".direnv" ".mypy_cache" "__pycache__" ".next" ".turbo")
  "Directory names skipped when measuring a project's last edit time.")

(defun macs-start--project-mtime (root)
  "Newest file modification time (seconds) under ROOT."
  (let ((newest 0))
    (dolist (file (directory-files-recursively
                   root "\\`[^.]" nil
                   (lambda (dir)
                     (not (member (file-name-nondirectory dir)
                                  macs-start--skip-dirs)))))
      (let ((m (file-attribute-modification-time (file-attributes file))))
        (when (and m (> (float-time m) newest))
          (setq newest (float-time m)))))
    newest))

(defun macs-start--ranked-projects ()
  "Known project roots, most recently edited first."
  (let ((roots (project-known-project-roots)))
    (if macs-start--mtime-cache
        (sort (copy-sequence roots)
              (lambda (a b)
                (> (or (cdr (assoc a macs-start--mtime-cache)) 0)
                   (or (cdr (assoc b macs-start--mtime-cache)) 0))))
      roots)))

(defun macs-start--recompute-mtimes ()
  "Scan known projects for their newest file mtime, then redraw."
  (setq macs-start--mtime-cache
        (mapcar (lambda (r) (cons r (macs-start--project-mtime r)))
                (project-known-project-roots)))
  (with-temp-file macs-start--mtime-cache-file
    (prin1 macs-start--mtime-cache (current-buffer)))
  (when (get-buffer "*macs*")
    (with-current-buffer "*macs*"
      (macs-start-refresh))))

(defun macs-start-refresh ()
  (interactive)
  (let* ((inhibit-read-only t)
         (all (macs-start--ranked-projects))
         (projects (if macs-start-show-all
                       all
                     (seq-take all macs-start-recent-count)))
         (rows (macs-start--rows projects))
         (sub (format "%d %sproject%s"
                      (length projects)
                      (if macs-start-show-all "" "recent ")
                      (if (= (length projects) 1) "" "s")))
         (hint "r scan   a all/recent   g refresh   q quit")
         (row-widths (mapcar (lambda (r) (+ (length (nth 0 r)) 2 (length (nth 1 r))))
                             rows))
         (banner-width (apply #'max (mapcar #'length macs-start-banner)))
         (width (apply #'max (max banner-width (length sub) (length hint))
                       row-widths))
         (margin (make-string (max 0 (/ (- (window-width) width) 2)) ?\s)))
    (erase-buffer)
    (dolist (line macs-start-banner)
      (insert (propertize " " 'display
                          `(space :align-to
                                  (- center ,(list (/ (string-pixel-width
                                                       (propertize line 'face 'macs-title))
                                                      2)))))
              (propertize (concat line "\n") 'face 'macs-title)))
    (insert "\n" margin (propertize (concat sub "\n\n") 'face 'macs-dim))
    (if rows
        (dolist (row rows)
          (insert margin)
          (let ((d (nth 2 row)))
            (insert-text-button (nth 0 row)
                                'action (lambda (_) (macs-open-project d))
                                'follow-link t
                                'help-echo d))
          (insert "  ")
          (insert (propertize (nth 1 row) 'face 'macs-dim))
          (insert "\n"))
      (insert margin
              (propertize (format "no projects yet — press r to scan %s\n"
                                  (mapconcat #'abbreviate-file-name macs-project-roots ", "))
                          'face 'macs-dim)))
    (insert "\n" margin (propertize (concat hint "\n") 'face 'macs-dim))
    (let* ((win (get-buffer-window (current-buffer)))
           (height (if win (window-body-height win) (window-body-height)))
           (lines (count-lines (point-min) (point-max)))
           (pad (max 0 (/ (- height lines) 2))))
      (goto-char (point-min))
      (insert (make-string pad ?\n))
      (let ((btn (next-button (point-min))))
        (when btn (goto-char (button-start btn)))))))

(defun macs-start--window-size-changed (frame)
  (let ((win (get-buffer-window "*macs*" frame)))
    (when win
      (with-current-buffer "*macs*"
        (macs-start-refresh)))))

(add-hook 'window-size-change-functions #'macs-start--window-size-changed)

(defun macs-start-scan ()
  "Scan `macs-project-roots' for projects, then refresh."
  (interactive)
  (dolist (root macs-project-roots)
    (when (file-directory-p root)
      (project-remember-projects-under root)))
  (macs-start-refresh))

(defun macs-start-toggle-all ()
  "Toggle between recent projects and every known project."
  (interactive)
  (setq macs-start-show-all (not macs-start-show-all))
  (macs-start-refresh))

(defun macs-start ()
  "Populate and return the macs start buffer."
  (with-current-buffer (get-buffer-create "*macs*")
    (special-mode)
    (setq-local truncate-lines t)
    (setq-local display-line-numbers nil)
    (display-line-numbers-mode -1)
    (local-set-key (kbd "r") #'macs-start-scan)
    (local-set-key (kbd "a") #'macs-start-toggle-all)
    (local-set-key (kbd "g") #'macs-start-refresh)
    (if (null (project-known-project-roots))
        (macs-start-scan)
      (macs-start-refresh))
    (current-buffer)))

(setq initial-buffer-choice #'macs-start)

(provide 'macs-start)
