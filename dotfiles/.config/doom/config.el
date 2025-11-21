;; User Information
(setq user-full-name "Ahsanur Rahman"
      user-mail-address "ahsanur041@proton.me")

(use-package! catppuccin-theme
  :config
  (setq catppuccin-flavor 'mocha)
  ;; Enable Catppuccin quality-of-life features
  (setq catppuccin-italic-comments t
        catppuccin-italic-blockquotes t
        catppuccin-italic-variables nil
        catppuccin-highlight-matches t
        catppuccin-dark-line-numbers-background t)

  (setq doom-theme 'catppuccin)

  (custom-theme-set-faces! 'catppuccin
    '(default :background "#1e1e2e" :foreground "#cdd6f4")
    '(corfu-default :background "#1e1e2e" :foreground "#cdd6f4")
    '(solaire-mode-bg-face :background "#11111b")
    '(hl-line :background "#11111b" :extend t)
    '(org-block :background "#313244" :foreground "#cdd6f4" :extend t)
    '(org-block-begin-line :background "#313244" :foreground "#6c7086" :extend t)
    '(org-block-end-line :background "#313244" :foreground "#6c7086" :extend t)
    '(org-meta-line :foreground "#6c7086")
    '(org-document-info-keyword :foreground "#6c7086")
    '(mode-line :background "#181825" :foreground "#cdd6f4")
    '(mode-line-inactive :background "#11111b" :foreground "#6c7086")
    '(region :background "#585b70" :extend t)
    '(cursor :background "#f5e0dc")
    '(show-paren-match :foreground "#f5c2e7" :background "#45475a" :weight bold)
    '(sp-show-pair-match-face :background "#b4befe" :foreground "black")
    '(minibuffer-prompt :foreground "#89dceb" :weight bold)
    '(pdf-view-highlight-face :background "#f9e2af" :foreground "#1e1e2e")
    '(pdf-view-link-face :foreground "#89b4fa")
    '(pdf-view-active-link-face :foreground "#cba6f7")))

(add-hook! 'doom-first-buffer-hook
  (size-indication-mode -1)
  (setq-default mode-line-percent-position nil))

(after! doom-modeline
  (setq doom-modeline-height 25
        doom-modeline-column-zero-based nil
        doom-modeline-bar-width 3

        ;; File/buffer name settings
        doom-modeline-buffer-file-size nil
        doom-modeline-buffer-file-name-style 'file-name  ; Only show filename, not full path

        doom-modeline-buffer-encoding nil ; Hide UTF-8 encoding display
        doom-modeline-percent-position nil ; Hide percentage position
        doom-modeline-major-mode-icon nil ; Hide major mode icon
        doom-modeline-major-mode-color-icon nil ; Disable colored major mode icon

        ;; VCS settings - show icon but hide branch name
        doom-modeline-vcs-icon t ; Keep VCS icon
        doom-modeline-vcs-max-length 0)) ; Hide branch name

;; Enable absolute line numbers globally by default.
(setq display-line-numbers-type t)

;; Disable line numbers in modes where they aren't useful.
(add-hook! '(org-mode-hook
             dired-mode-hook
             magit-status-mode-hook
             eshell-mode-hook
             vterm-mode-hook
             help-mode-hook
             doom-dashboard-mode-hook)
           #'(lambda () (display-line-numbers-mode -1)))

(setq doom-font (font-spec :family "JetBrains Mono" :size 13.0 :weight 'medium)
      doom-variable-pitch-font (font-spec :family "JetBrains Mono" :size 13.0)
      doom-big-font (font-spec :family "JetBrains Mono" :size 24))

(use-package! rainbow-delimiters
  :hook ((text-mode . rainbow-delimiters-mode)
         (LaTeX-mode . rainbow-delimiters-mode)
         (org-src-mode . rainbow-delimiters-mode)
         (prog-mode . rainbow-delimiters-mode))
  :config
  (custom-set-faces!
   '(rainbow-delimiters-depth-1-face :foreground "#89b4fa")
   '(rainbow-delimiters-depth-2-face :foreground "#cba6f7")
   '(rainbow-delimiters-depth-3-face :foreground "#f9e2af")
   '(rainbow-delimiters-depth-4-face :foreground "#89dceb")
   '(rainbow-delimiters-depth-5-face :foreground "#f38ba8")
   '(rainbow-delimiters-depth-6-face :foreground "#a6e3a1")
   '(rainbow-delimiters-depth-7-face :foreground "#fab387")
   '(rainbow-delimiters-depth-8-face :foreground "#cdd6f4")
   '(rainbow-delimiters-depth-9-face :foreground "#bac2de")))

(use-package! rainbow-mode
  :hook ((prog-mode . rainbow-mode)
         (org-mode . rainbow-mode)))

(after! which-key
  (setq which-key-idle-delay 0.3
        which-key-allow-imprecise-window-fit nil
        which-key-separator " → "
        which-key-max-display-columns nil
        which-key-popup-type 'side-window
        which-key-side-window-max-width 0.33))

(use-package! sudo-edit
  :commands sudo-edit)

(set-selection-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(setq locale-coding-system 'utf-8)
;; Treat clipboard input as UTF-8 string first; compound text next, etc.
(when (display-graphic-p)
  (setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING)))

(after! dired
  (setq dired-listing-switches "-agho --group-directories-first"
        delete-by-moving-to-trash t
        dired-dwim-target t))

(use-package! dired-open
  :after dired
  :config
  (setq dired-open-extensions '(("png" . "imv")
                                ("mp4" . "mpv"))))

(global-so-long-mode 1)
(size-indication-mode -1)

(after! evil
  (setq evil-want-fine-undo t
        evil-vsplit-window-right t
        evil-split-window-below t
        evil-move-beyond-eol t))

(after! evil-escape
  (setq evil-escape-key-sequence "jk"
        evil-escape-delay 0.2))

;; Use visual line navigation, which is more intuitive when working with wrapped lines.
(map! :nv "j" #'evil-next-visual-line
      :nv "k" #'evil-previous-visual-line)

(setq-default internal-border-width 5)
(add-to-list 'default-frame-alist '(internal-border-width . 5))

(setq frame-title-format
      '((:eval (if (buffer-file-name)
                   (abbreviate-file-name (buffer-file-name))
                 "%b"))
        " - Doom Emacs"))

(setq-default indent-tabs-mode nil
              tab-width 2
              fill-column 80

              ;; Line spacing
              line-spacing 0.02)

(setq confirm-kill-emacs nil)

(setq-default scroll-conservatively 20
              scroll-margin 0
              scroll-preserve-screen-position t)

(setq warning-suppress-types '((org-element)))

(setq split-width-threshold 170
      split-height-threshold nil)

(setq-default bidi-inhibit-bpa t) ;; Emacs 27+ recommended
(setq-default bidi-display-reordering nil) ;; Use with caution, unsupported in some older Emacs versions

(defvar my/org-directory "~/org/" "The root directory for Org files.")
(defvar my/org-roam-directory (expand-file-name "roam/" my/org-directory) "The directory for Org Roam files.")

(after! org
  (add-hook! 'org-mode-hook #'(lambda () (org-indent-mode -1)))
  (add-hook! 'org-babel-after-execute-hook #'org-redisplay-inline-images)

  (setq org-directory my/org-directory
        org-agenda-files (list (expand-file-name "inbox.org" my/org-directory)
                               (expand-file-name "projects.org" my/org-directory)
                               (expand-file-name "habits.org" my/org-directory))
        org-default-notes-file (expand-file-name "inbox.org" my/org-directory)

        ;;Optimizations
        org-src-fontify-natively t
        org-hide-emphasis-markers nil
        org-hide-leading-stars nil
        org-pretty-entities nil
        org-fontify-quote-and-verse-blocks nil
        org-fontify-whole-heading-line nil
        org-fontify-done-headline nil
        org-highlight-latex-and-related nil
        org-startup-folded 'showeverything
        org-startup-with-latex-preview nil
        org-startup-with-inline-images nil
        org-cycle-separator-lines 2

        ;; Babel setings
        org-confirm-babel-evaluate nil

        ;; Element cache - ESSENTIAL for large files
        org-element-use-cache t
        org-element-cache-persistent t

        ;; Agenda optimization
        org-agenda-inhibit-startup t
        org-agenda-dim-blocked-tasks nil
        org-agenda-use-tag-inheritance nil
        org-agenda-ignore-properties '(effort appt category)
        org-agenda-span 'day

        ;; Image settings
        org-image-actual-width 600

        ;; TODO keywords
        org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "PROG(p)" "WAIT(w@/!)" "|" "DONE(d!)" "CANCEL(c@)")
          (sequence "PLAN(P)" "ACTIVE(A)" "PAUSED(x)" "|" "ACHIEVED(a)" "DROPPED(D)"))

        org-archive-location (concat my/org-directory "archive/%s_archive::")
        org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "PROG(p)" "WAIT(w@/!)" "|" "DONE(d!)" "CANCEL(c@)")
          (sequence "PLAN(P)" "ACTIVE(A)" "PAUSED(x)" "|" "ACHIEVED(a)" "DROPPED(D)"))

        org-todo-keyword-faces
        '(("TODO"      . (:foreground "#f38ba8" :weight bold))
          ("NEXT"      . (:foreground "#fab387" :weight bold))
          ("PROG"      . (:foreground "#89b4fa" :weight bold))
          ("WAIT"      . (:foreground "#f9e2af" :weight bold))
          ("DONE"      . (:foreground "#a6e3a1" :weight bold))
          ("CANCEL"    . (:foreground "#6c7086" :weight bold))
          ("PLAN"      . (:foreground "#94e2d5" :weight bold))
          ("ACTIVE"    . (:foreground "#cba6f7" :weight bold))
          ("PAUSED"    . (:foreground "#bac2de" :weight bold))
          ("ACHIEVED"  . (:foreground "#a6e3a1" :weight bold))
          ("DROPPED"   . (:foreground "#6c7086" :weight bold)))))


(use-package! org-super-agenda
  :after org-agenda
  :hook (org-agenda-mode-hook . org-super-agenda-mode))

(after! smartparens
  (show-paren-mode -1)
  (show-smartparens-global-mode +1))

(after! org-modern
  (setq
   org-modern-hide-stars "· "
   org-modern-star '("◉" "○" "◈" "◇" "◆" "▷")
   org-modern-list '((43 . "➤") (45 . "–") (42 . "•"))
   org-modern-table-vertical 1
   org-modern-table-horizontal 0.1
   org-modern-block-name '(("src" "»" "«")
                           ("example" "»" "«")
                           ("quote" "❝" "❞"))
   org-modern-checkbox '((todo . "☐") (done . "☑") (cancel . "☒") (priority . "⚑") (on . "◉") (off . "○"))
   org-modern-tag-faces `((:foreground ,(face-attribute 'default :foreground) :weight bold :box (:line-width (1 . -1) :color "#45475a")))))

(after! org-roam
  (setq org-roam-directory my/org-roam-directory
        org-roam-db-gc-threshold most-positive-fixnum
        org-roam-completion-everywhere t))

(use-package! org-roam-ui
  :after org-roam
  :config (setq org-roam-ui-sync-theme t
                org-roam-ui-follow t
                org-roam-ui-update-on-save t))

(use-package! consult-org-roam
  :after org-roam
  :init (consult-org-roam-mode 1))

(after! corfu
  (corfu-popupinfo-mode -1))

(use-package! eldoc-box
  :hook (eglot-managed-mode . eldoc-box-hover-at-point-mode)
  ;; :init
  ;; (setq eldoc-box-clear-with-C-g t
  ;;       eldoc-box-only-multi-line t
  ;;       eldoc-idle-delay 0.3)

  :config
  (custom-set-faces!
   '(eldoc-box-body :background "#313244" :foreground "#cdd6f4")
   '(eldoc-box-border :background "#45475a"))

  (setq eldoc-box-max-pixel-width 800
        eldoc-box-max-pixel-height 400))

;;; Disable flymake-popon in favor of eldoc-box
(after! flymake-popon
  ;; Remove the hook that automatically enables flymake-popon-mode
  (remove-hook 'flymake-mode-hook #'flymake-popon-mode)

  ;; If flymake-popon-mode is already active, turn it off globally
  (when (fboundp 'global-flymake-popon-mode)
    (global-flymake-popon-mode -1)))

;; ═══════════════════════════════════════════════════════════════════════════
;; JUPYTER CORE CONFIGURATION
;; ═══════════════════════════════════════════════════════════════════════════

(after! ob-jupyter
  ;; Default header arguments for jupyter-python blocks
  (setq org-babel-default-header-args:jupyter-python
        '((:async . "yes")
          (:session . "py")
          (:kernel . "python3")
          (:exports . "both")
          (:results . "output")))

  ;; Override python blocks with jupyter AFTER ob-jupyter loads
  ;; This lets you use #+begin_src python instead of jupyter-python
  (org-babel-jupyter-override-src-block "python")

  ;; Resource directory for images and other outputs
  (setq org-babel-jupyter-resource-directory
        (expand-file-name ".jupyter-resources/" org-directory))

  ;; Pandoc integration for richer output rendering
  (when (executable-find "pandoc")
    (setq jupyter-org-pandoc-convertable
          '("text/html" "text/markdown" "text/latex"))))

;; ═══════════════════════════════════════════════════════════════════════════
;; DOOM LAZY LOADING INTEGRATION
;; ═══════════════════════════════════════════════════════════════════════════

;; Ensure jupyter is properly loaded when executing python blocks
(add-hook! '+org-babel-load-functions
  (defun +jupyter-load-and-override-h (lang)
    "Load jupyter for python and apply overrides."
    (when (eq lang 'python)
      (require 'ob-jupyter nil t)
      (when (featurep 'ob-jupyter)
        (org-babel-jupyter-make-local-aliases)
        (org-babel-jupyter-override-src-block "python")))))

;; ═══════════════════════════════════════════════════════════════════════════
;; CORFU COMPATIBILITY
;; ═══════════════════════════════════════════════════════════════════════════

(after! jupyter-org-client
  (defun +jupyter-disable-completion-h ()
    "Remove jupyter-org-completion-at-point to avoid Corfu conflicts."
    (setq-local completion-at-point-functions
                (delq 'jupyter-org-completion-at-point
                      completion-at-point-functions)))

  ;; Apply to org-mode and when jupyter-org-interaction-mode activates
  (add-hook 'org-mode-hook #'+jupyter-disable-completion-h)
  (add-hook 'jupyter-org-interaction-mode-hook #'+jupyter-disable-completion-h)

  ;; Enable request queuing for better async behavior
  (setq jupyter-org-queue-requests t))

;; ═══════════════════════════════════════════════════════════════════════════
;; LSP SUPPORT FOR ORG SOURCE BLOCKS
;; ═══════════════════════════════════════════════════════════════════════════

(defgroup +org-src-lsp nil
  "LSP support for org source blocks via Eglot."
  :group 'org)

(defcustom +org-src-lsp-enabled-modes '(python-mode python-ts-mode)
  "Major modes where LSP should be enabled in org-src buffers.
Add modes here that you want to have LSP support when editing
source blocks with `org-edit-special'."
  :type '(repeat symbol)
  :group '+org-src-lsp)

(defun +org-src-lsp--edit-prep (info)
  "Setup Eglot in org-src buffer using tangled file content.
INFO is the return value of `org-babel-get-src-block-info'.

This implements the oglot.el approach: load the tangled file into
the org-src buffer, narrow to the current block, then start Eglot.
The LSP server sees the complete file context for accurate analysis."
  (let ((ok t)
        (point (point))
        (body (nth 1 info))
        (params (nth 2 info))
        filename)

    ;; Verify we're in org-src-mode
    (unless (bound-and-true-p org-src-mode)
      (setq ok nil))

    ;; Get tangle filename
    (when ok
      (setq filename (cdr (assq :tangle params)))
      (when (or (null filename)
                (string= filename "no")
                (string= filename "yes"))
        (setq ok nil)
        (message "LSP requires :tangle header with explicit filename")))

    ;; Expand filename relative to org file directory
    (when ok
      (when-let* ((beg-marker org-src--beg-marker)
                  (org-buffer (marker-buffer beg-marker))
                  ((buffer-live-p org-buffer))
                  (org-file (buffer-file-name org-buffer))
                  (org-dir (file-name-directory org-file)))
        (setq filename (expand-file-name filename org-dir)))

      ;; Check file exists and is readable
      (unless (file-readable-p filename)
        (setq ok nil)
        (message "Tangled file %s not found - run org-babel-tangle first"
                 (abbreviate-file-name filename))))

    ;; Verify block appears exactly once in tangled file
    (when ok
      (with-temp-buffer
        (insert-file-contents filename 'visit nil nil 'replace)
        (goto-char (point-min))
        (let ((count 0))
          (while (search-forward body nil t)
            (cl-incf count))
          (cond
           ((= count 0)
            (setq ok nil)
            (message "Block not found in %s - tangle may be outdated"
                     (file-name-nondirectory filename)))
           ((> count 1)
            (setq ok nil)
            (message "Block appears %d times in %s - cannot disambiguate"
                     count (file-name-nondirectory filename)))))))

    ;; Load tangled file, narrow to block, start Eglot
    (when ok
      (goto-char (point-min))
      (insert-file-contents filename 'visit nil nil 'replace)
      (search-forward body)

      ;; Preserve cursor position within block
      (goto-char (+ (match-beginning 0) (1- point)))

      ;; Narrow to block region
      (narrow-to-region (match-beginning 0) (match-end 0))

      ;; Associate buffer with tangled file for LSP project detection
      (setq-local buffer-file-name filename)

      ;; Configure eldoc for org-src context
      (setq-local eldoc-echo-area-use-multiline-p nil)

      ;; Disable corfu-popupinfo to avoid display issues
      (when (bound-and-true-p corfu-popupinfo-mode)
        (corfu-popupinfo-mode -1))

      ;; Start Eglot
      (eglot-ensure))))

;; Register edit-prep functions for Python variants
(defun org-babel-edit-prep:python (info)
  "Setup LSP for Python source blocks."
  (+org-src-lsp--edit-prep info))

(defun org-babel-edit-prep:jupyter-python (info)
  "Setup LSP for Jupyter Python source blocks."
  (+org-src-lsp--edit-prep info))

;; ═══════════════════════════════════════════════════════════════════════════
;; CLEANUP ON SAVE/EXIT
;; ═══════════════════════════════════════════════════════════════════════════

(defun +org-src-lsp--cleanup ()
  "Remove hidden text before saving/exiting org-src buffer.
When we load the tangled file and narrow, text outside the narrowed
region must be deleted before writing back to the org file."
  (when (and (bound-and-true-p org-src-mode)
             (apply #'derived-mode-p +org-src-lsp-enabled-modes)
             ;; Only cleanup if we have hidden content (buffer was widened)
             (or (> (point-min) 1)
                 (< (point-max) (buffer-size))))
    (save-excursion
      ;; Delete content before narrowed region
      (let ((narrow-beg (point-min))
            (narrow-end (point-max)))
        (widen)
        (delete-region (point-min) narrow-beg)
        ;; Adjust for deleted content
        (delete-region narrow-end (point-max))))))

(advice-add 'org-edit-src-exit :before #'+org-src-lsp--cleanup)
(advice-add 'org-edit-src-save :before #'+org-src-lsp--cleanup)

;; ═══════════════════════════════════════════════════════════════════════════
;; COMMENTS LINK TOGGLE (from oglot.el)
;; ═══════════════════════════════════════════════════════════════════════════

(defconst +org-src-lsp--comments-link-re
  "\\( :comments link\\)\\|\\( *$\\)"
  "Regexp to match :comments link or end of header-args line.")

(defun +org-src-lsp-toggle-comments-link ()
  "Toggle :comments link in Python header-args property.
When enabled, tangled files include comments linking back to the
org file, which helps with synchronization and debugging."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((ha-re "^[[:blank:]]*#\\+property:[[:blank:]]+header-args:python"))
      (if (re-search-forward ha-re nil t)
          (when (re-search-forward +org-src-lsp--comments-link-re (line-end-position) t)
            (if (match-string 1)
                (replace-match "")
              (replace-match " :comments link"))
            (org-ctrl-c-ctrl-c)
            (message "Python :comments link %s"
                     (if (match-string 1) "disabled" "enabled")))
        (user-error "No Python header-args property found")))))

;; ═══════════════════════════════════════════════════════════════════════════
;; HELPER FUNCTIONS
;; ═══════════════════════════════════════════════════════════════════════════

(defun +jupyter/tangle-and-edit ()
  "Tangle current block then open for editing with LSP support.
Use this when you want to ensure the tangled file is up-to-date
before editing a source block."
  (interactive)
  (if (org-in-src-block-p)
      (let ((lang (org-element-property :language (org-element-at-point))))
        (message "Tangling %s blocks..." lang)
        (org-babel-tangle nil nil lang)
        (org-edit-special))
    (user-error "Not in a source block")))

(defun +jupyter/toggle-request-queuing ()
  "Toggle client-side request queuing for Jupyter."
  (interactive)
  (setq jupyter-org-queue-requests (not jupyter-org-queue-requests))
  (message "Jupyter request queuing: %s"
           (if jupyter-org-queue-requests "ON" "OFF")))

(defun +jupyter/verify-setup ()
  "Verify Jupyter and python override configuration."
  (interactive)
  (let ((results '()))
    ;; Check ob-jupyter
    (push (format "ob-jupyter loaded: %s" (featurep 'ob-jupyter)) results)

    ;; Check python override
    (push (format "python->jupyter override: %s"
                  (if (fboundp 'org-babel-execute:python)
                      (let ((fn (symbol-function 'org-babel-execute:python)))
                        (if (and (symbolp fn)
                                 (string-match "jupyter" (symbol-name fn)))
                            "YES"
                          "NO (using ob-python)"))
                    "NOT DEFINED"))
          results)

    ;; Check default header args
    (push (format "Default session: %s"
                  (or (cdr (assq :session org-babel-default-header-args:jupyter-python))
                      "NOT SET"))
          results)

    ;; Check kernel
    (push (format "Default kernel: %s"
                  (or (cdr (assq :kernel org-babel-default-header-args:jupyter-python))
                      "NOT SET"))
          results)

    (message "%s" (string-join (nreverse results) "\n"))))

(defun +jupyter/refresh-and-verify ()
  "Refresh kernelspecs and verify setup."
  (interactive)
  (jupyter-refresh-kernelspecs)
  (+jupyter/verify-setup))

;; ═══════════════════════════════════════════════════════════════════════════
;; ANSI COLOR SUPPORT IN RESULTS
;; ═══════════════════════════════════════════════════════════════════════════

(defun +org-babel-ansi-colors-h ()
  "Apply ANSI color codes in the current babel result block."
  (when-let ((beg (org-babel-where-is-src-block-result nil nil)))
    (save-excursion
      (goto-char beg)
      (when (looking-at org-babel-result-regexp)
        (let ((end (org-babel-result-end))
              (ansi-color-context-region nil))
          (ansi-color-apply-on-region beg end))))))

(add-hook 'org-babel-after-execute-hook #'+org-babel-ansi-colors-h)

;; ═══════════════════════════════════════════════════════════════════════════
;; KEYBINDINGS
;; ═══════════════════════════════════════════════════════════════════════════

(map! :leader
      (:prefix ("j" . "jupyter")
       :desc "Refresh kernelspecs"       "r" #'jupyter-refresh-kernelspecs
       :desc "Verify setup"              "v" #'+jupyter/verify-setup
       :desc "Refresh & verify"          "V" #'+jupyter/refresh-and-verify
       :desc "Toggle request queuing"    "q" #'+jupyter/toggle-request-queuing
       :desc "Tangle & edit with LSP"    "e" #'+jupyter/tangle-and-edit
       :desc "Toggle :comments link"     "c" #'+org-src-lsp-toggle-comments-link))

;; Org-src-mode keybindings for LSP features
(map! :after org-src
      :map org-src-mode-map
      :localleader
      :desc "Exit and save"        "'" #'org-edit-src-exit
      :desc "Abort edit"           "k" #'org-edit-src-abort
      :desc "Save"                 "s" #'org-edit-src-save
      (:prefix ("c" . "code/LSP")
       :desc "Format buffer"       "=" #'apheleia-format-buffer
       :desc "Code actions"        "a" #'eglot-code-actions
       :desc "Rename"              "r" #'eglot-rename
       :desc "Find definition"     "d" #'xref-find-definitions
       :desc "Find references"     "R" #'xref-find-references
       :desc "Show documentation"  "h" #'eldoc-box-help-at-point))

(after! magit
  (setq magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

(use-package! magit-todos
  :after magit
  :config (magit-todos-mode 1))

(setq forge-owned-accounts '(("aahsnr")))

(after! vertico
  (setq vertico-count 10))

(after! apheleia
  (setf (alist-get 'python-mode apheleia-mode-alist) '(ruff-isort ruff))
  (setf (alist-get 'python-ts-mode apheleia-mode-alist) '(ruff-isort ruff)))

(setq +python-ipython-repl-args '("-i" "--simple-prompt" "--no-color-info"))
(setq +python-jupyter-repl-args '("--simple-prompt"))

(after! eglot

  (set-eglot-client! '(python-mode python-ts-mode)
                     "pylsp" "pyls"
                     '("basedpyright-langserver" "--stdio")
                     '("pyright-langserver" "--stdio")
                     '("pyrefly" "lsp")
                     "jedi-language-server"
                     '("ruff" "server")
                     "ruff-lsp")

 (setq eglot-ignored-server-capabilities
       '(:hoverProvider
         :documentFormattingProvider
         :documentRangeFormattingProvider
         :documentOnTypeFormattingProvider
         :foldingRangeProvider))

 (setq-default eglot-workspace-configuration
               '(:basedpyright
                 (:analysis
                  (:typeCheckingMode "recommended"  ; Balance between strict and permissive

                   :diagnosticSeverityOverrides
                   (:reportUnusedImport "none"
                    :reportUnusedVariable "none"
                    :reportUnusedClass "none"
                    :reportUnusedFunction "none"
                    :reportUnusedCallResult "none"

                    ;; Module and import analysis
                    :reportMissingImports "warning"              ; Can't find module
                    :reportMissingModuleSource "warning"         ; Stub exists but no source

                    ;; Type consistency and safety
                    :reportUndefinedVariable "warning"           ; Variable not defined
                    :reportIncompatibleMethodOverride "warning"  ; Method signature mismatch
                    :reportIncompatibleVariableOverride "warning"; Variable type mismatch
                    :reportAttributeAccessIssue "warning"        ; Invalid attribute access

                    ;; Type stub and annotation support
                    :reportMissingTypeStubs "none"              ; Warning if stubs missing (can be noisy)
                    :reportMissingTypeArgument "warning"        ; Generic without type args

                    ;; Reduced noise from gradual typing
                    :reportUnknownMemberType "none"             ; Unknown member types (gradual typing)
                    :reportUnknownParameterType "none"          ; Unknown param types (gradual typing)
                    :reportUnknownVariableType "none"           ; Unknown var types (gradual typing)
                    :reportUnknownArgumentType "none")))))      ; Unknown arg types (gradual typing)

  ;; Configure eldoc and flymake to work together properly
  (add-hook 'eglot-managed-mode-hook
            (lambda ()
              ;; Prioritize flymake diagnostics in eldoc
              (setq-local eldoc-documentation-functions
                          (cons #'flymake-eldoc-function
                                (remove #'flymake-eldoc-function eldoc-documentation-functions)))

              ;; Use compose strategy to show all documentation
              (setq-local eldoc-documentation-strategy #'eldoc-documentation-compose)))
 )

(use-package! flymake-ruff
  :after flymake
  :hook (eglot-managed-mode . flymake-ruff-load))

(after! flymake
  (setq flymake-show-diagnostics-at-end-of-line nil  ;; Disable end-of-line diagnostics
        flymake-indicator-type 'fringes               ;; Only show in fringes
        flymake-no-changes-timeout 0.5
        flymake-start-on-save-buffer t))

(after! tex
  ;; Set Tectonic as the default engine
  (setq TeX-engine 'default)

  ;; Register Tectonic as a TeX engine
  (setq TeX-engine-alist '((default
                            "Tectonic"
                            "tectonic -X compile -f plain %T"
                            "tectonic -X watch"
                            nil)))

  ;; Simplify LaTeX command style for Tectonic compatibility
  (setq LaTeX-command-style '(("" "%(latex)")))

  (setq TeX-check-TeX nil
        TeX-process-asynchronous t)

  ;; Modify TeX and LaTeX commands for Tectonic
  (let ((tex-list (assoc "TeX" TeX-command-list))
        (latex-list (assoc "LaTeX" TeX-command-list)))
    (setf (cadr tex-list) "%(tex)"
          (cadr latex-list) "%l")))

;; Handle Tectonic project output directories (projectile-aware)
(defun +latex-tectonic-set-output-dir-h ()
  "Set TeX-output-dir for Tectonic projects."
  (when-let* ((project-p (and (featurep 'projectile)
                              (fboundp 'projectile-project-p)
                              (projectile-project-p)))
              (root (projectile-project-root))
              (toml-file (expand-file-name "Tectonic.toml" root))
              (toml-exists (file-exists-p toml-file)))
    (setq-local TeX-output-dir (expand-file-name "build/index" root))))

(add-hook 'LaTeX-mode-hook #'+latex-tectonic-set-output-dir-h)

(defun +latex-find-project-bibliographies ()
  "Find all .bib files in project (root, references/, bib/, bibliography/)."
  (when (and (featurep 'projectile)
             (fboundp 'projectile-project-p)
             (projectile-project-p))
    (when-let ((root (projectile-project-root)))
      (let ((bib-files '())
            (search-dirs (list root
                              (expand-file-name "references/" root)
                              (expand-file-name "bib/" root)
                              (expand-file-name "bibliography/" root))))
        (dolist (dir search-dirs)
          (when (file-directory-p dir)
            (dolist (file (directory-files dir t "\\.bib\\'"))
              (push file bib-files))))
        (delete-dups (nreverse bib-files))))))

(defun +latex-setup-project-bibliography ()
  "Setup bibliography infrastructure for current project."
  (interactive)
  (if (and (featurep 'projectile)
           (fboundp 'projectile-project-p)
           (projectile-project-p))
      (let* ((root (projectile-project-root))
             (bib-dir (expand-file-name "references/" root))
             (bib-file (expand-file-name "references.bib" bib-dir)))
        (unless (file-directory-p bib-dir)
          (make-directory bib-dir t))
        (unless (file-exists-p bib-file)
          (with-temp-file bib-file
            (insert "% Bibliography for "
                    (file-name-nondirectory (directory-file-name root)) "\n")
            (insert "% Created: " (format-time-string "%Y-%m-%d") "\n\n")))
        (message "Bibliography setup complete: %s" bib-file)
        bib-file)
    (message "Not in a project")))

(after! citar
  ;; Doom already sets up basic citar - we extend it
  (setq citar-bibliography '("~/references.bib")
        citar-library-paths '("~/Zotero/storage")
        citar-notes-paths (list my/org-roam-directory))

  ;; Register indicators
  (setq citar-indicators
        (list citar-indicator-files-icons
              citar-indicator-notes-icons
              citar-indicator-links-icons))

  ;; Dynamic bibliography function
  (defun +citar-get-bibliography ()
    "Return project bibliography or global fallback."
    (or (+latex-find-project-bibliographies) citar-bibliography))

  ;; Override citar's bibliography detection
  (advice-add 'citar--bibliography-files :override #'+citar-get-bibliography)

  ;; Set buffer-local bibliography
  (defun +citar-set-local-bibliography-h ()
    "Set buffer-local bibliography for current buffer."
    (when (and (buffer-file-name)
               (or (derived-mode-p 'org-mode)
                   (derived-mode-p 'LaTeX-mode)))
      (setq-local citar-bibliography (+citar-get-bibliography))
      ;; Also update org-cite
      (when (derived-mode-p 'org-mode)
        (setq-local org-cite-global-bibliography (+citar-get-bibliography)))))

  ;; Apply hooks after projectile is loaded
  (when (featurep 'projectile)
    (add-hook 'org-mode-hook #'+citar-set-local-bibliography-h)
    (add-hook 'LaTeX-mode-hook #'+citar-set-local-bibliography-h)))

;; RefTeX configuration - handle non-citation references only
;; Let Citar manage bibliographies
(after! reftex
  (setq reftex-default-bibliography '()))

(use-package! laas
  :hook (LaTeX-mode . laas-mode)
  :config
  (aas-set-snippets 'laas-mode
    ;; Math-only snippets
    :cond #'texmathp
    "supp" "\\supp"
    "inf" "\\infty"
    "lim" "\\lim"
    "On" "O(n)"
    "O1" "O(1)"
    "Olog" "O(\\log n)"
    "Olon" "O(n \\log n)"

    ;; Functions with yasnippet integration
    "Sum" (lambda () (interactive)
            (yas-expand-snippet "\\sum_{${1:i=1}}^{${2:n}} $0"))
    "Prod" (lambda () (interactive)
             (yas-expand-snippet "\\prod_{${1:i=1}}^{${2:n}} $0"))
    "Int" (lambda () (interactive)
            (yas-expand-snippet "\\int_{${1:a}}^{${2:b}} $0"))
    "Lim" (lambda () (interactive)
            (yas-expand-snippet "\\lim_{${1:x \\to \\infty}} $0"))
    "Span" (lambda () (interactive)
             (yas-expand-snippet "\\Span($1)$0"))

    ;; Accent snippets
    :cond #'laas-object-on-left-condition
    "qq" (lambda () (interactive) (laas-wrap-previous-object "sqrt"))
    "vv" (lambda () (interactive) (laas-wrap-previous-object "vec"))
    ".." (lambda () (interactive) (laas-wrap-previous-object "dot"))
    "::" (lambda () (interactive) (laas-wrap-previous-object "ddot"))
    "~~" (lambda () (interactive) (laas-wrap-previous-object "tilde"))
    "^^" (lambda () (interactive) (laas-wrap-previous-object "hat"))
    "--" (lambda () (interactive) (laas-wrap-previous-object "bar"))))

(after! tex
  ;; Extend Doom's existing prettify symbols
  (cl-callf2 append +latex-prettify-symbols-alist
            '(;; Additional Greek letters
              ("\\varepsilon" . "ε")
              ("\\varphi" . "φ")

              ;; Additional math operators
              ("\\iint" . "∬")
              ("\\iiint" . "∭")
              ("\\oint" . "∮")

              ;; Additional relations
              ("\\notin" . "∉")
              ("\\subseteq" . "⊆")
              ("\\supseteq" . "⊇")

              ;; Additional logic
              ("\\nexists" . "∄")
              ("\\land" . "∧")
              ("\\lor" . "∨")

              ;; Additional misc
              ("\\mp" . "∓")
              ("\\ell" . "ℓ")
              ("\\hbar" . "ℏ"))))

(after! org
  ;; Use Tectonic for Org LaTeX exports
  (setq org-latex-compiler "tectonic"
        org-latex-pdf-process '("tectonic -X compile %f"))

  ;; Add Tectonic preview process
  (add-to-list 'org-preview-latex-process-alist
               '(tectonic
                 :programs ("tectonic" "convert")
                 :description "pdf > png"
                 :message "you need to install: tectonic and imagemagick"
                 :image-input-type "pdf"
                 :image-output-type "png"
                 :image-size-adjust (1.0 . 1.0)
                 :latex-compiler
                 ("tectonic -Z shell-escape-cwd=%o --outfmt pdf --outdir %o %f")
                 :image-converter
                 ("convert -density %D -trim -antialias %f -quality 100 %O")))

  (setq org-preview-latex-default-process 'tectonic))

;; Org-fragtog for automatic LaTeX fragment preview
(use-package! org-fragtog
  :defer t
  :hook (org-mode . org-fragtog-mode))

(map! :after latex
      :map LaTeX-mode-map
      :localleader
      ;; Tectonic-specific build commands (extends Doom's defaults)
      (:prefix ("b" . "build")
       :desc "Compile with Tectonic" "t" (cmd! (TeX-command "Tectonic" 'TeX-master-file))
       :desc "Watch mode (Tectonic)" "w" (cmd! (TeX-command "Tectonic Watch" 'TeX-master-file)))

      ;; Citation management (extends Doom's citar keybindings)
      (:prefix ("r" . "references")
       :desc "Insert citation" "i" #'citar-insert-citation
       :desc "Open citation" "o" #'citar-open
       :desc "Open library file" "f" #'citar-open-library-file
       :desc "Open notes" "n" #'citar-open-notes
       :desc "Create note" "N" #'citar-create-note))

;; Org-mode LaTeX keybindings
(map! :after org
      :map org-mode-map
      :localleader
      (:prefix ("L" . "LaTeX")
       :desc "Preview fragment" "p" #'org-latex-preview
       :desc "Export to PDF" "e" #'org-latex-export-to-pdf
       :desc "Toggle fragtog" "f" #'org-fragtog-mode))

(setq-default pdf-view-display-size 'fit-page)
(add-hook! 'pdf-view-mode-hook #'pdf-view-midnight-minor-mode)

(map! :leader
      (:prefix ("t" . "toggle")
       :desc "Toggle eshell split"            "e" #'+eshell/toggle
       :desc "Toggle line highlight in frame" "h" #'hl-line-mode
       :desc "Toggle line highlight globally" "H" #'global-hl-line-mode
       :desc "Toggle line numbers"            "l" #'doom/toggle-line-numbers
       :desc "Toggle markdown-view-mode"      "m" #'dt/toggle-markdown-view-mode
       :desc "Toggle truncate lines"          "t" #'toggle-truncate-lines
       :desc "Toggle treemacs"                "T" #'+treemacs/toggle
       :desc "Toggle vterm split"             "v" #'+vterm/toggle))

(map! :leader
      (:prefix ("o" . "open here")
       :desc "Open eshell here"    "e" #'+eshell/here
       :desc "Open vterm here"     "v" #'+vterm/here))

(map! :leader
      :desc "M-x" "SPC" #'execute-extended-command)

(map! :leader
      (:prefix ("j" . "jupyter")
       :desc "Refresh kernelspecs"     "r" #'jupyter-refresh-kernelspecs
       :desc "Toggle raw output"       "o" (cmd! (setq +jupyter-raw-output-mode
                                                       (not +jupyter-raw-output-mode))
                                                 (message "Jupyter raw output: %s"
                                                          (if +jupyter-raw-output-mode "ON" "OFF")))))

(map! :leader
      (:prefix ("o" . "open")
        :desc "Insert template"         "t" #'+org-insert-scientific-template
        :desc "Toggle Python export"    "e" #'+org-toggle-python-export
        :desc "Set tangle file"         "f" #'+org-set-python-tangle-file
        :desc "Set subtree export"      "x" #'+org-set-subtree-export
        :desc "Insert source block"     "s" #'+org-insert-src-block))

(map! :leader
      (:prefix ("c" . "code")
       :desc "Format buffer"            "=" #'apheleia-format-buffer
       :desc "Organize imports"         "o" #'eglot-code-action-organize-imports
       :desc "Rename"                   "r" #'eglot-rename
       :desc "Find references"          "R" #'xref-find-references
       :desc "Show documentation"       "h" #'eldoc-doc-buffer
       :desc "Show doc in childframe"   "H" #'eldoc-box-help-at-point
       :desc "Code actions"             "a" #'eglot-code-actions
       :desc "Find definition"          "d" #'xref-find-definitions
       :desc "Find type definition"     "D" #'eglot-find-typeDefinition
       :desc "Go back"                  "b" #'xref-go-back))

;; Flymake diagnostics navigation
(map! :after flymake
      :map flymake-mode-map
      :n "]d" #'flymake-goto-next-error
      :n "[d" #'flymake-goto-prev-error
      :leader
      (:prefix ("c" . "code")
       :desc "List diagnostics"        "x" #'flymake-show-buffer-diagnostics
       :desc "List project diagnostics" "X" #'flymake-show-project-diagnostics))

;; Org-src-mode specific keybindings
(map! :map org-src-mode-map
      :localleader
      :desc "Exit and save"        "'" #'org-edit-src-exit
      :desc "Abort edit"           "k" #'org-edit-src-abort
      :desc "Format buffer"        "=" #'apheleia-format-buffer
      :desc "Show documentation"   "h" #'eldoc-box-help-at-point
      :desc "Code actions"         "a" #'eglot-code-actions)

(map! :leader
      (:prefix ("d" . "debug/dape")
       :desc "Debug"               "d" #'dape
       :desc "Toggle breakpoint"   "b" #'dape-breakpoint-toggle
       :desc "Continue"            "c" #'dape-continue
       :desc "Next"                "n" #'dape-next
       :desc "Step in"             "i" #'dape-step-in
       :desc "Step out"            "o" #'dape-step-out
       :desc "Restart"             "r" #'dape-restart
       :desc "Kill debug session"  "k" #'dape-kill
       :desc "Debug REPL"          "R" #'dape-repl))
