;;; LSP Bridge Org Babel Configuration
;;; Replace the "LSP in Org Source Blocks" section in your config.org

;;; ============================================================
;;; LSP Bridge Configuration (Updated)
;;; ============================================================

(use-package! lsp-bridge
  :config
  (global-lsp-bridge-mode)

  ;; Python multi-server: basedpyright for completion + ruff for linting
  (setq lsp-bridge-python-multi-lsp-server "basedpyright_ruff"
        lsp-bridge-tex-lsp-server "texlab"
        lsp-bridge-nix-lsp-server "nil")

  ;; ============================================================
  ;; Org Babel Support - ENABLE THIS for in-buffer LSP
  ;; ============================================================
  ;; This enables LSP completion/diagnostics directly in org source blocks
  (setq lsp-bridge-enable-org-babel t
        ;; nil = enable for all languages, or specify: '("python" "bash")
        lsp-bridge-org-babel-lang-list nil)

  ;; ACM (completion menu) settings
  (setq acm-enable-doc nil
        acm-enable-jupyter t
        acm-enable-doc-markdown-render 'async
        acm-enable-icon t
        acm-candidate-match-function 'orderless-literal
        acm-backend-search-file-words-enable-fuzzy-match t)

  ;; LSP Bridge behavior
  (setq lsp-bridge-enable-hover-diagnostic t
        lsp-bridge-enable-auto-format-code nil))

;;; ============================================================
;;; LSP in Org Source Blocks (org-edit-special) with lsp-bridge
;;; ============================================================
;;; This provides full file context when editing blocks with C-c '
;;; by loading the tangled file and narrowing to the current block.

(defgroup +org-src-lsp-bridge nil
  "LSP support for org source blocks via lsp-bridge."
  :group 'org)

(defcustom +org-src-lsp-bridge-enabled-modes '(python-mode python-ts-mode)
  "Major modes where lsp-bridge LSP should be enabled in org-src buffers.
Add modes here that you want to have LSP support when editing
source blocks with `org-edit-special'."
  :type '(repeat symbol)
  :group '+org-src-lsp-bridge)

(defvar-local +org-src-lsp-bridge--tangle-file nil
  "The tangled file associated with this org-src buffer.")

(defvar-local +org-src-lsp-bridge--original-content nil
  "Original block content before loading tangled file.")

(defun +org-src-lsp-bridge--edit-prep (info)
  "Setup lsp-bridge in org-src buffer using tangled file content.
INFO is the return value of `org-babel-get-src-block-info'.

This loads the tangled file into the org-src buffer, narrows to
the current block, then enables lsp-bridge. The LSP server sees
the complete file context for accurate analysis."
  (let ((ok t)
        (point (point))
        (body (nth 1 info))
        (params (nth 2 info))
        filename)

    ;; Verify we're in org-src-mode
    (unless (bound-and-true-p org-src-mode)
      (setq ok nil))

    ;; Get tangle filename from header args
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

    ;; Load tangled file, narrow to block, setup lsp-bridge
    (when ok
      ;; Store original content for cleanup
      (setq-local +org-src-lsp-bridge--original-content
                  (buffer-substring-no-properties (point-min) (point-max)))
      (setq-local +org-src-lsp-bridge--tangle-file filename)

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

      ;; Ensure lsp-bridge starts for this buffer
      ;; lsp-bridge checks buffer-file-name to determine the language server
      (when (fboundp 'lsp-bridge-mode)
        (lsp-bridge-mode 1)))))

;; Register edit-prep functions for Python variants
(defun org-babel-edit-prep:python (info)
  "Setup LSP for Python source blocks."
  (+org-src-lsp-bridge--edit-prep info))

(defun org-babel-edit-prep:jupyter-python (info)
  "Setup LSP for Jupyter Python source blocks."
  (+org-src-lsp-bridge--edit-prep info))

(defun +org-src-lsp-bridge--cleanup ()
  "Remove hidden text before saving/exiting org-src buffer.
When we load the tangled file and narrow, text outside the narrowed
region must be deleted before writing back to the org file."
  (when (and (bound-and-true-p org-src-mode)
             (apply #'derived-mode-p +org-src-lsp-bridge-enabled-modes)
             ;; Only cleanup if we have hidden content
             (or (> (point-min) 1)
                 (< (point-max) (buffer-size))))
    (save-excursion
      (let ((narrow-beg (point-min))
            (narrow-end (point-max)))
        (widen)
        (delete-region (point-min) narrow-beg)
        (delete-region narrow-end (point-max))))))

(advice-add 'org-edit-src-exit :before #'+org-src-lsp-bridge--cleanup)
(advice-add 'org-edit-src-save :before #'+org-src-lsp-bridge--cleanup)

;;; ============================================================
;;; Comments Link Toggle (unchanged)
;;; ============================================================

(defconst +org-src-lsp-bridge--comments-link-re
  "\\( :comments link\\)\\|\\( *$\\)"
  "Regexp to match :comments link or end of header-args line.")

(defun +org-src-lsp-bridge-toggle-comments-link ()
  "Toggle :comments link in Python header-args property.
When enabled, tangled files include comments linking back to the
org file, which helps with synchronization and debugging."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((ha-re "^[[:blank:]]*#\\+property:[[:blank:]]+header-args:python"))
      (if (re-search-forward ha-re nil t)
          (when (re-search-forward +org-src-lsp-bridge--comments-link-re (line-end-position) t)
            (if (match-string 1)
                (replace-match "")
              (replace-match " :comments link"))
            (org-ctrl-c-ctrl-c)
            (message "Python :comments link %s"
                     (if (match-string 1) "disabled" "enabled")))
        (user-error "No Python header-args property found")))))

;;; ============================================================
;;; Helper Functions
;;; ============================================================

(defun +org-src-lsp-bridge/tangle-and-edit ()
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

(defun +org-src-lsp-bridge/verify-setup ()
  "Verify lsp-bridge and org-babel configuration."
  (interactive)
  (let ((results '()))
    ;; Check lsp-bridge
    (push (format "lsp-bridge loaded: %s" (featurep 'lsp-bridge)) results)
    (push (format "lsp-bridge-mode active: %s" (bound-and-true-p lsp-bridge-mode)) results)

    ;; Check org-babel settings
    (push (format "lsp-bridge-enable-org-babel: %s"
                  (if (boundp 'lsp-bridge-enable-org-babel)
                      lsp-bridge-enable-org-babel
                    "NOT DEFINED"))
          results)

    ;; Check python server
    (push (format "Python multi-server: %s"
                  (if (boundp 'lsp-bridge-python-multi-lsp-server)
                      lsp-bridge-python-multi-lsp-server
                    "NOT SET"))
          results)

    (message "%s" (string-join (nreverse results) "\n"))))

;;; ============================================================
;;; Keybindings
;;; ============================================================

(map! :leader
      (:prefix ("j" . "jupyter/lsp-bridge")
       :desc "Refresh kernelspecs"       "r" #'jupyter-refresh-kernelspecs
       :desc "Verify setup"              "v" #'+org-src-lsp-bridge/verify-setup
       :desc "Tangle & edit with LSP"    "e" #'+org-src-lsp-bridge/tangle-and-edit
       :desc "Toggle :comments link"     "c" #'+org-src-lsp-bridge-toggle-comments-link))

;; Org-src-mode keybindings for lsp-bridge features
(map! :after org-src
      :map org-src-mode-map
      :localleader
      :desc "Exit and save"        "'" #'org-edit-src-exit
      :desc "Abort edit"           "k" #'org-edit-src-abort
      :desc "Save"                 "s" #'org-edit-src-save
      (:prefix ("c" . "code/LSP")
       :desc "Find definition"     "d" #'lsp-bridge-find-def
       :desc "Find references"     "R" #'lsp-bridge-find-references
       :desc "Show documentation"  "h" #'lsp-bridge-popup-documentation
       :desc "Rename"              "r" #'lsp-bridge-rename
       :desc "Code actions"        "a" #'lsp-bridge-code-action
       :desc "Format buffer"       "=" #'apheleia-format-buffer))

;; Global lsp-bridge keybindings (update your existing ones)
(map! :leader
      (:prefix ("c" . "code")
       :desc "Format buffer"            "=" #'apheleia-format-buffer
       :desc "Rename"                   "r" #'lsp-bridge-rename
       :desc "Find references"          "R" #'lsp-bridge-find-references
       :desc "Show documentation"       "h" #'lsp-bridge-popup-documentation
       :desc "Code actions"             "a" #'lsp-bridge-code-action
       :desc "Find definition"          "d" #'lsp-bridge-find-def
       :desc "Find type definition"     "D" #'lsp-bridge-find-type-def
       :desc "Go back"                  "b" #'lsp-bridge-find-def-return
       :desc "Peek definition"          "p" #'lsp-bridge-peek
       :desc "List diagnostics"         "x" #'lsp-bridge-diagnostic-list))
