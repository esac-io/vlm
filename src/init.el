;;; Package --- eos
;;; Commentary: ... Present day, present time ....
;;; Code:

;;; -*- lexical-binding: t -*-

(when (version< emacs-version "26.3")
  (error "This requires Emacs 26.3 and above!"))

;; (require 'org nil t)

;; threshold inital value
(setq gc-cons-threshold most-positive-fixnum ; 2^61 bytes
      gc-cons-percentage 0.5)

(defun eos/defer-gc-collection ()
  "Set `gc-cons-threshold' to most positive fix number,
The largest value that is representable in a Lisp integer."
  (setq gc-cons-threshold most-positive-fixnum))

(defun eos/reset-gc-collection ()
  "Reset garbage collection."
  (run-at-time
   1 nil
   (lambda ()
     (setq gc-cons-threshold 16777216))))

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold 16777216 ; 16mb
                  gc-cons-percentage 0.1)))

;; y or n
(defalias 'yes-or-no-p 'y-or-n-p)

(defvar eos-file-name-handler-alist
  file-name-handler-alist
  "Save file-name-handler-alist")

(defvar eos-tags-map
  (make-sparse-keymap)
  "Keymap for tags (navigation) keybinds.")

(defvar eos-pm-map
  (make-sparse-keymap)
  "Keymap for project manager keybinds.")

(defvar eos-sc-map
  (make-sparse-keymap)
  "Keymap for syntax check keybinds.")

(defvar eos-complete-map
  (make-sparse-keymap)
  "Keymap for (complete) keybinds.")

(defvar eos-window-map
  (make-sparse-keymap)
  "Keymap for window related keybinds.")

(defvar eos-docs-map
  (make-sparse-keymap)
  "Keymap for documentation keybinds.")

(defvar eos-find-map
  (make-sparse-keymap)
  "Keymap for find keybinds.")

(defvar eos-utils-map
  (make-sparse-keymap)
  "Keymap for utils keybinds.")

(defvar eos-rtags-map
  (make-sparse-keymap)
  "Keymap for rtag minor mode keybinds.")

(dolist (prefix-map '(eos-tags-map
                      eos-pm-map
                      eos-sc-map
                      eos-docs-map
                      eos-find-map
                      eos-utils-map
                      eos-window-map
                      eos-complete-map
                      eos-rtags-map))
  (define-prefix-command prefix-map))

;; clean file-name-handler-alist
(setq file-name-handler-alist nil)

;; restore file-name-handler-alist
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist eos-file-name-handler-alist)))

(require 'cl-seq nil t)

(defun eos-update-load-path (&rest _)
  "Update `load-path'."
  (dolist (dir '("site-lisp" "lisp"))
    (push (expand-file-name dir user-emacs-directory) load-path)))

(defun eos-add-subdirs-to-load-path (&rest _)
  "Add sub-directories to `load-path'."
  (interactive)
  (let ((default-directory (expand-file-name "site-lisp" user-emacs-directory)))
    (normal-top-level-add-subdirs-to-load-path)
    (cl-remove-duplicates load-path)))

(defun eos-load-file (file)
  "Load FILE if exists."
  (if (file-exists-p file)
      (load (expand-file-name file) t nil nil)
    (message "file %s not found" file)))

;; update load path
(eos-update-load-path)
(eos-add-subdirs-to-load-path)

(defun eos-call-proc (name &optional args)
  "Call (execute) a process by NAME with ARGS."
  (if (executable-find name)
      (if args
          (start-process name nil name args)
        (start-process name nil name)))
  nil)

(defun eos-call-func (func &rest args)
  "Call FUNC with ARGS, if it's bounded."
  (when (fboundp func)
    (funcall func args)))

(defun eos-edit-move-lines (n)
  "Move N lines, up if N is positive, else down."
  (let* (text-start
         text-end
         (region-start (point))
         (region-end region-start)
         swap-point-mark
         delete-latest-newline)

    ;; STEP 1: identifying the text to cut.
    (when (region-active-p)
      (if (> (point) (mark))
          (setq region-start (mark))
        (exchange-point-and-mark)
        (setq swap-point-mark t
              region-end (point))))

    ;; text-end and region-end
    (end-of-line)

    (if (< (point) (point-max))
        (forward-char 1)
      (setq delete-latest-newline t)
      (insert-char ?\n))
    (setq text-end (point)
          region-end (- region-end text-end))

    ;; text-start and region-start
    (goto-char region-start)
    (beginning-of-line)
    (setq text-start (point)
          region-start (- region-start text-end))

    ;; STEP 2: cut and paste.
    (let ((text (delete-and-extract-region text-start text-end)))
      (forward-line n)
      ;; If the current-column != 0, I have moved the region at the bottom of a
      ;; buffer doesn't have the trailing newline.
      (when (not (= (current-column) 0))
        (insert-char ?\n)
        (setq delete-latest-newline t))
      (insert text))

    ;; STEP 3: Restoring.
    (forward-char region-end)

    (when delete-latest-newline
      (save-excursion
        (goto-char (point-max))
        (delete-char -1)))

    (when (region-active-p)
      (setq deactivate-mark nil)
      (set-mark (+ (point) (- region-start region-end)))
      (if swap-point-mark
          (exchange-point-and-mark)))))

(defun eos/edit-move-lines-up (n)
  "Move N lines up."
  (interactive "p")
  (if (eq n nil)
      (setq n 1))
  (eos-edit-move-lines (- n)))

(defun eos/edit-move-lines-down (n)
  "Move N lines down."
  (interactive "p")
  (if (eq n nil)
      (setq n 1))
  (eos-edit-move-lines n))

(defun eos/edit-move-words-left (n)
  "Move word N times to the left."
  (interactive "p")
  (if (eq n nil)
      (setq n 1))
  (transpose-words (- n)))

(defun eos/edit-indent-buffer ()
  "Indent the currently visited buffer."
  (interactive)
  (indent-region (point-min) (point-max)))

(defun eos/edit-indent-region-or-buffer ()
  "Indent a region if selected, otherwise the whole buffer."
  (interactive)
  (save-excursion
    (if (region-active-p)
        (progn
          (indent-region (region-beginning) (region-end))
          (message "Indented selected region."))
      (progn
        (eos/edit-indent-buffer)
        (message "Indented buffer.")))))

(defun eos/edit-duplicate-current-line-or-region (arg)
  "Duplicates the current line or region ARG times.

If there's no region, the current line will be duplicated.
However, if there's a region, all lines that region covers will be duplicated."

  (interactive "p")
  (let (beg end (origin (point)))
    (if (and mark-active (> (point) (mark)))
        (exchange-point-and-mark))
    (setq beg (line-beginning-position))
    (if mark-active
        (exchange-point-and-mark))
    (setq end (line-end-position))
    (let ((region (buffer-substring-no-properties beg end))
          (i arg))
      (while (> i 0)
        (goto-char end)
        (newline)
        (insert region)
        (setq end (point))
        (setq i (1- i)))
      (goto-char (+ origin (* (length region) arg) arg)))))

(defun eos-copy-text-or-symbol-at-point ()
  "Get the text in region or symbol at point.
      If region is active, return the text in that region.  Else if the
      point is on a symbol, return that symbol name.  Else return nil."
  (cond ((use-region-p)
         (buffer-substring-no-properties
          (region-beginning) (region-end)))
        ((symbol-at-point)
         (substring-no-properties (thing-at-point 'symbol)))
        (t
         nil)))

(defun eos-copy-line (&optional arg)
  "Do a kill-line but copy rather than kill. This function directly calls
kill-line, so see documentation of kill-line for how to use it including prefix
argument and relevant variables. This function works by temporarily making the
buffer read-only."
  (interactive "P")
  (let ((buffer-read-only t)
        (kill-read-only-ok t))
    (kill-line arg))
  (move-beginning-of-line nil))

(defun eos/move-beginning-of-line (arg)
  "Move point back to indentation(ARG) start, or line(ARG) start."
  (interactive "^p")
  (setq arg (or arg 1))

  ;; Move lines first
  (when (/= arg 1)
    (let ((line-move-visual nil))
      (forward-line (1- arg))))

  (let ((orig-point (point)))
    (back-to-indentation)
    (when (= orig-point (point))
      (move-beginning-of-line 1))))

(defun eos-kill-buffer (buffer-name)
  "Kill BUFFER-NAME if exists."
  (when (get-buffer buffer-name)
    (kill-buffer buffer-name)))

(defun eos/kill-current-buffer ()
  "Kill the current buffer without prompting."
  (interactive)
  (kill-buffer (current-buffer)))

(defun eos-mkdir (dir)
  "Create DIR in the file system."
  (when (and (not (file-exists-p dir))
             (make-directory dir :parents))))

(defun eos/search-keymaps (key)
  "Search for KEY in all known keymaps.
Keymaps list will be printed on *Messages* buffer."
  (interactive "kPress key: ")
  (mapatoms (lambda (ob)
              (when (and (boundp ob) (keymapp (symbol-value ob)))
                (when (functionp (lookup-key (symbol-value ob) key))
                  (message "%s" ob))))))

(defun eos/set-frame-transparency (alpha)
  "Set transparency level defined by ALPHA in current frame."
  (interactive "nAlpha: ")
  (let ((alpha (or alpha 1.0)))
    (if (executable-find "transset")
        (async-shell-command (format "transset -a %.1f" alpha))
      (error "Transset not found"))))

;; add eos-theme-dir to theme load path
(add-to-list 'custom-theme-load-path
             (concat user-emacs-directory "themes"))

;; load theme
(load-theme 'mesk-term t)

;; clean esc map
(define-key esc-map (kbd "ESC") nil)
(define-key esc-map (kbd "<f10>") nil)

;; unbind
;; (define-key ctl-x-map (kbd "C-SPC") nil)
;; (define-key ctl-x-map (kbd "C-=") nil)
;; (define-key ctl-x-map (kbd "C-0") nil)
;; (define-key ctl-x-map (kbd "C--") nil)
;; (define-key ctl-x-map (kbd "ESC") nil)
;; (define-key ctl-x-map (kbd ".") nil)
;; (define-key ctl-x-map (kbd "C-l") nil)
;; (define-key ctl-x-map (kbd "C-x") nil)
;; (define-key ctl-x-map (kbd "C-<left>") nil)
;; (define-key ctl-x-map (kbd "C-<right>") nil)
;; (define-key ctl-x-map (kbd "C-<up>") nil)
;; (define-key ctl-x-map (kbd "C-<down>") nil)
(define-key ctl-x-map (kbd "<right>") nil)
(define-key ctl-x-map (kbd "<left>") nil)

(define-key ctl-x-map (kbd "C-o") nil)
(define-key ctl-x-map (kbd "C-d") nil)
(define-key ctl-x-map (kbd "C-c") nil)
(define-key ctl-x-map (kbd "C-j") nil)
(define-key ctl-x-map (kbd "C-+") nil)
(define-key ctl-x-map (kbd "C-a") nil)
(define-key ctl-x-map (kbd "C-r") nil)
(define-key ctl-x-map (kbd "C-n") nil)
(define-key ctl-x-map (kbd "C-z") nil)
(define-key ctl-x-map (kbd "C-p") nil)
(define-key ctl-x-map (kbd "C-h") nil)
(define-key ctl-x-map (kbd "C-u") nil)
(define-key ctl-x-map (kbd "C-\@") nil)
(define-key ctl-x-map (kbd "M-:") nil)

(define-key ctl-x-map (kbd "RET") nil)
(define-key ctl-x-map (kbd "`") nil)
(define-key ctl-x-map (kbd "]") nil)
;; (define-key ctl-x-map (kbd "[") nil)
(define-key ctl-x-map (kbd ")") nil)
(define-key ctl-x-map (kbd "(") nil)
(define-key ctl-x-map (kbd "<") nil)
(define-key ctl-x-map (kbd ">") nil)
(define-key ctl-x-map (kbd "\@") nil)
(define-key ctl-x-map (kbd "-") nil)
(define-key ctl-x-map (kbd ";") nil)
(define-key ctl-x-map (kbd "#") nil)
(define-key ctl-x-map (kbd "*") nil)
(define-key ctl-x-map (kbd "'") nil)
(define-key ctl-x-map (kbd "$") nil)
(define-key ctl-x-map (kbd "{") nil)
(define-key ctl-x-map (kbd "}") nil)
(define-key ctl-x-map (kbd "^") nil)
;; (define-key ctl-x-map (kbd "n") nil)
;; (define-key ctl-x-map (kbd "f") nil)
(define-key ctl-x-map (kbd "a") nil)
(define-key ctl-x-map (kbd "h") nil)
(define-key ctl-x-map (kbd "v") nil)
(define-key ctl-x-map (kbd "x") nil)
(define-key ctl-x-map (kbd "X") nil)

(setq minor-mode-map-alist nil)

;; unset
(global-unset-key (kbd "C-z"))
(global-unset-key (kbd "C-@"))
(global-unset-key (kbd "C-\\"))
(global-unset-key (kbd "C-_"))
(global-unset-key (kbd "M-l"))
(global-unset-key (kbd "M-h"))
(global-unset-key (kbd "M-\\"))
(global-unset-key (kbd "M-$"))
(global-unset-key (kbd "M-("))
(global-unset-key (kbd "M-)"))
(global-unset-key (kbd "M-r"))
(global-unset-key (kbd "M-{"))
(global-unset-key (kbd "M-}"))
(global-unset-key (kbd "S-SPC"))
(global-unset-key (kbd "<backtap>"))
(global-unset-key (kbd "M-="))
(global-unset-key (kbd "M-@"))
(global-unset-key (kbd "M-~"))

;; (global-unset-key (kbd "M-z"))
;; (global-unset-key (kbd "M-SPC"))
;; (global-unset-key (kbd "M-m"))
;; (global-unset-key (kbd "M-k"))
;; (global-unset-key (kbd "M-t"))
;; (global-unset-key (kbd "M-q"))

(global-unset-key (kbd "C-M-h"))
(global-unset-key (kbd "C-M-j"))
(global-unset-key (kbd "C-M-."))
(global-unset-key (kbd "C-M-l"))
(global-unset-key (kbd "C-M-/"))
(global-unset-key (kbd "C-M-;"))
(global-unset-key (kbd "C-M-@"))
(global-unset-key (kbd "C-M-\\"))
(global-unset-key (kbd "C-M-a"))
(global-unset-key (kbd "C-M-r"))
(global-unset-key (kbd "C-M-s"))
(global-unset-key (kbd "C-M-%"))
(global-unset-key (kbd "C-M-u"))
(global-unset-key (kbd "C-M-d"))
(global-unset-key (kbd "C-M-SPC"))
(global-unset-key (kbd "C-M-S-v"))

(global-unset-key (kbd "<C-M-end>"))
(global-unset-key (kbd "<C-M-home>"))
(global-unset-key (kbd "<C-S-backspace>"))
(global-unset-key (kbd "<C-backspace>"))
(global-unset-key (kbd "<C-delete>"))
(global-unset-key (kbd "<C-down>"))
(global-unset-key (kbd "<C-next>"))
(global-unset-key (kbd "<C-end>"))
(global-unset-key (kbd "<C-f10>"))
(global-unset-key (kbd "<M-f10>"))

(global-unset-key (kbd "<bottom-divider>"))
(global-unset-key (kbd "<bottom-edge>"))
(global-unset-key (kbd "<bottom-left-corner>"))
(global-unset-key (kbd "<bottom-right-corner>"))

(global-unset-key (kbd "<horizontal-scroll-bar>"))
(global-unset-key (kbd "<vertical-scroll-bar>"))

(global-unset-key (kbd "<left-edge>"))
(global-unset-key (kbd "<right-edge>"))

(global-unset-key (kbd "<undo>"))
(global-unset-key (kbd "<find>"))
(global-unset-key (kbd "<help>"))
(global-unset-key (kbd "<open>"))
(global-unset-key (kbd "<again>"))
(global-unset-key (kbd "<menu>"))
(global-unset-key (kbd "<header-line>"))
(global-unset-key (kbd "<mode-line>"))

(global-unset-key (kbd "<XF86Back>"))
(global-unset-key (kbd "<XF86Forward>"))
(global-unset-key (kbd "<XF86WakeUp>"))

(global-unset-key (kbd "<top-edge>"))
(global-unset-key (kbd "<top-left-corner>"))
(global-unset-key (kbd "<top-right-corner>"))

(global-unset-key (kbd "<mouse-1>"))
(global-unset-key (kbd "<mouse-2>"))
(global-unset-key (kbd "<mouse-3>"))
(global-unset-key (kbd "<mouse-4>"))
(global-unset-key (kbd "<mouse-5>"))
(global-unset-key (kbd "<mouse-6>"))
(global-unset-key (kbd "<mouse-7>"))

(global-unset-key (kbd "<right-divider>"))
(global-unset-key (kbd "<vertical-line>"))

(global-unset-key (kbd "<f10>"))
(global-unset-key (kbd "<f11>"))
(global-unset-key (kbd "<f16>"))
(global-unset-key (kbd "<f18>"))
(global-unset-key (kbd "<f20>"))

(global-unset-key (kbd "<drag-mouse-1>"))
(global-unset-key (kbd "<C-mouse-4>"))
(global-unset-key (kbd "<C-mouse-5>"))
(global-unset-key (kbd "<C-mouse-6>"))
(global-unset-key (kbd "<C-mouse-7>"))
(global-unset-key (kbd "<M-mouse-1>"))
(global-unset-key (kbd "<M-mouse-2>"))
(global-unset-key (kbd "<M-mouse-3>"))
(global-unset-key (kbd "<S-mouse-3>"))
(global-unset-key (kbd "<S-mouse-4>"))
(global-unset-key (kbd "<S-mouse-5>"))
(global-unset-key (kbd "<S-mouse-6>"))
(global-unset-key (kbd "<S-mouse-7>"))
(global-unset-key (kbd "<C-down-mouse-1>"))
(global-unset-key (kbd "<C-down-mouse-2>"))
(global-unset-key (kbd "<M-down-mouse-1>"))
(global-unset-key (kbd "<M-drag-mouse-1>"))
(global-unset-key (kbd "<S-down-mouse-1>"))

;; line movement
(global-set-key (kbd "C-a") 'eos/move-beginning-of-line)
(global-set-key (kbd "C-e") 'move-end-of-line)

;; word movement
;; (global-set-key (kbd "C-<left>") 'backward-word)
;; (global-set-key (kbd "C-<right>") 'forward-whitespace)

;; scroll movement
(global-set-key (kbd "C-M-v") 'scroll-other-window)
(global-set-key (kbd "C-M-y") 'scroll-other-window-down)

;; edit
(global-set-key (kbd "M-i") 'eos/edit-indent-region-or-buffer)
(global-set-key (kbd "M-j") 'eos/edit-duplicate-current-line-or-region)
(global-set-key (kbd "M-p") 'eos/edit-move-lines-up)
(global-set-key (kbd "M-n") 'eos/edit-move-lines-down)

;; kill
(define-key ctl-x-map (kbd "k") 'eos/kill-current-buffer)

;; mark
(define-key eos-utils-map (kbd "h") 'mark-whole-buffer)
(define-key eos-utils-map (kbd "s") 'mark-sexp)
(define-key eos-utils-map (kbd "p") 'mark-paragraph)
(define-key eos-utils-map (kbd "w") 'mark-word)

;; eos prefixs
(define-key ctl-x-map (kbd "p") 'eos-pm-map)
(define-key ctl-x-map (kbd "t") 'eos-tags-map)
(define-key ctl-x-map (kbd "c") 'eos-utils-map)
(define-key ctl-x-map (kbd "e") 'eos-sc-map)
(define-key ctl-x-map (kbd "f") 'eos-find-map)
(define-key ctl-x-map (kbd "l") 'eos-docs-map)
(define-key ctl-x-map (kbd "<tab>") 'eos-complete-map)

;; non-nil means to make the cursor very visible
(customize-set-variable 'visible-cursor nil)

;; scroll options
;; number of lines of margin at the top and bottom of a window
(customize-set-variable 'scroll-margin 0)

;; scroll up to this many lines, to bring point back on screen
(customize-set-variable 'scroll-conservatively 100)

;; t means point keeps its screen position
(customize-set-variable 'scroll-preserve-screen-position t)

;; non-nil means mouse commands use dialog boxes to ask questions
(customize-set-variable 'use-dialog-box nil)

;; set window margins
;; width in columns of left marginal area for display of a buffer
(customize-set-variable 'left-margin-width 1)

;; width in columns of right marginal area for display of a buffer.
(customize-set-variable 'right-margin-width 1)

;; if t, resize window combinations proportionally
(customize-set-variable 'window-combination-resize t)

;; if non-nil ‘display-buffer’ will try to even window sizes
(customize-set-variable 'even-window-sizes t)

;; if non-nil, left and right side windows occupy full frame height
(customize-set-variable 'window-sides-vertical nil)

;; binds (global)
(global-set-key (kbd "s-l") 'shrink-window-horizontally)
(global-set-key (kbd "s-h") 'enlarge-window-horizontally)
(global-set-key (kbd "s-j") 'shrink-window)
(global-set-key (kbd "s-k") 'enlarge-window)

;; next and previous buffer (on current window)
(define-key ctl-x-map (kbd "C-,") 'previous-buffer)
(define-key ctl-x-map (kbd "C-.") 'next-buffer)

;; binds (eos-window prefix map)
(define-key eos-window-map (kbd "1") 'maximize-window)
(define-key eos-window-map (kbd "q") 'minimize-window)
(define-key eos-window-map (kbd "w") 'balance-windows)

;; binds ctl-x-map (C-x w)
(define-key ctl-x-map (kbd "w") 'eos-window-map)

;; switch to buffer
(define-key ctl-x-map (kbd "C-b") 'switch-to-buffer)

;; kill buffer and window
(define-key ctl-x-map (kbd "C-k") 'kill-buffer-and-window)

;; (add-to-list 'display-buffer-alist
;;              '(("\\*Choices\\*"
;;                 (display-buffer-below-selected display-buffer-at-bottom)
;;                 (inhibit-same-window . t)
;;                 (window-height . fit-window-to-buffer))))

(when (require 'windmove nil t)
  (progn

;; window move default keybinds (shift-up/down etc..)
(eos-call-func 'windmove-default-keybindings)))

;; custom
;; non-nil inhibits the startup screen.
(customize-set-variable 'inhibit-startup-screen t)

;; non-nil inhibits the startup screen
(customize-set-variable 'inhibit-startup-message t)

;; non-nil inhibits the initial startup echo area message
(customize-set-variable 'inhibit-startup-echo-area-message t)

;; custom
;; non-nil means do not display continuation lines.
(customize-set-variable 'truncate-lines nil)

;; sentences should be separated by a single space,
;; so treat two sentences as two when filling
(customize-set-variable 'sentence-end-double-space nil)

;; default indent
;; distance between tab stops (for display of tab characters), in columns.
(customize-set-variable 'tab-width 4)

;; indentation can insert tabs if this is non-nil.
(customize-set-variable 'indent-tabs-mode nil)

;; kill process not confirmation required
;; list of functions called with no args to query before killing a buffer.
;; The buffer being killed will be current while the functions are running.
(customize-set-variable
 'kill-buffer-query-functions
 (remq 'process-kill-buffer-query-function kill-buffer-query-functions))

;; non-nil means load prefers the newest version of a file.
(customize-set-variable 'load-prefer-newer t)

;; (add-hook 'buffer-list-update-hook
;;           (lambda ()
;;             (when (boundp 'eos/big-file-p)
;;               (if (eos/big-file-p)
;;                   (or display-line-numbers
;;                       (setq display-line-numbers 0))))))

(when (require 'ibuffer nil t)
  (progn

(define-key ctl-x-map (kbd "b") 'ibuffer)))

(when (require 'hideshow nil t)
  (progn

(add-hook 'prog-mode-hook 'hs-minor-mode)

;; ctl-x-map
(define-key ctl-x-map (kbd "[") 'hs-toggle-hiding)))

(when (require 'minibuffer nil t)
  (progn

;; non-nil means to allow minibuffer commands while in the minibuffer
(customize-set-variable 'enable-recursive-minibuffers nil)

;; if non-nil, `read-answer' accepts single-character answers
(customize-set-variable 'read-answer-short t)

;; non-nil means completion ignores case when reading a buffer name
(customize-set-variable 'read-buffer-completion-ignore-case t)

;; non-nil means when reading a file name completion ignores case
(customize-set-variable 'read-file-name-completion-ignore-case t)

;; number of completion candidates below which cycling is used
(customize-set-variable 'completion-cycle-threshold nil)

;; treat the SPC or - inserted by `minibuffer-complete-word as delimiters
(customize-set-variable 'completion-pcm-complete-word-inserts-delimiters t)

;; a string of characters treated as word delimiters for completion
(customize-set-variable 'completion-pcm-word-delimiters "-_./:| ")

;; non-nil means show help message in *Completions* buffer
(customize-set-variable 'completion-show-help nil)

;; non-nil means automatically provide help for invalid completion input
(customize-set-variable 'completion-auto-help 'lazy)

;; list of completion styles to use: see `completion-styles-alist variable
(customize-set-variable 'completion-styles '(partial-completion substring initials))

;; list of category-specific user overrides for completion styles.
(customize-set-variable 'completion-category-overrides
                        '((file (styles initials basic))
                          (buffer (styles initials basic))
                          (info-menu (styles basic))))

;; define the appearance and sorting of completions
(customize-set-variable 'completions-format 'vertical)

;; non-nil means when reading a file name completion ignores case
(customize-set-variable 'read-file-name-completion-ignore-case t)

;; how to resize mini-windows (the minibuffer and the echo area)
;; a value of t means resize them to fit the text displayed in them
(customize-set-variable 'resize-mini-windows nil)

;; if non-nil, shorten "(default ...)" to "[...]" in minibuffer prompts
(customize-set-variable 'minibuffer-eldef-shorten-default t)

;; non-nil means to delete duplicates in history
(customize-set-variable 'history-delete-duplicates t)))

(defun eos/focus-minibuffer ()
  "Focus the active minibuffer.

Bind this to `completion-list-mode-map' to easily jump
between the list of candidates present in the \\*Completions\\*
buffer and the minibuffer."

  (interactive)
  (let ((mini (active-minibuffer-window)))
    (when mini
      (select-window mini))))

(defun eos/focus-minibuffer-or-completions ()
  "Focus the active minibuffer or the \\*Completions\\*.

      If both the minibuffer and the Completions are present, this
      command will first move per invocation to the former, then the
      latter, and then continue to switch between the two.

      The continuous switch is essentially the same as running
      `eos/focus-minibuffer' and `switch-to-completions' in
      succession."
  (interactive)
  (let* ((mini (active-minibuffer-window))
         (completions (get-buffer-window "*Completions*")))
    (cond ((and mini
                (not (minibufferp)))
           (select-window mini nil))
          ((and completions
                (not (eq (selected-window)
                         completions)))
           (select-window completions nil)))))

;; defer garbage collection
(add-hook 'minibuffer-setup-hook 'eos/defer-gc-collection)

;; reset threshold to inital value
(add-hook 'minibuffer-exit-hook 'eos/reset-gc-collection)

;; minibuffer-local-map
(define-key minibuffer-local-map (kbd "M-`") 'minibuffer-completion-help)
(define-key minibuffer-local-map (kbd "<tab>") 'minibuffer-complete)

;; research (maybe this is not necessary) (C-k: kill line)
;; (define-key minibuffer-local-map (kbd "M-w") 'eos/icomplete/kill-ring-save)

;; global-map
(global-set-key (kbd "ESC ESC") 'eos/focus-minibuffer-or-completions)

;; if `file-name-shadow-mode' is active, any part of the
;; minibuffer text that would be ignored because of this is given the
;; properties in `file-name-shadow-properties', which may
;; be used to make the ignored text invisible, dim, etc.
(file-name-shadow-mode -1)

;; when active, any recursive use of the minibuffer will show
;; the recursion depth in the minibuffer prompt, this is only
;; useful if `enable-recursive-minibuffers' is non-nil
(minibuffer-depth-indicate-mode -1)

;; when active, minibuffer prompts that show a default value only show
;; the default when it's applicable
(minibuffer-electric-default-mode 1)

(when (require 'completion nil t)
  (progn
    ;; custom
    ;; how far to search in the buffer when looking for completions,
    ;; if nil, search the whole buffer
    (customize-set-variable 'completion-search-distance 12000)

    ;; if non-nil, the next completion prompt does a cdabbrev search
    (customize-set-variable 'completion-cdabbrev-prompt-flag nil)

    ;; non-nil means show help message in *Completions* buffer
    (customize-set-variable 'completion-show-help nil)

    ;; non-nil means separator characters mark previous word as used
    (customize-set-variable 'completion-on-separator-characthfer t)

    ;; the filename to save completions to.
    (customize-set-variable
     'save-completions-file-name
     (expand-file-name "cache/completitions" user-emacs-directory))

    ;; non-nil means save most-used completions when exiting emacs
    (customize-set-variable 'save-completions-flag t)

    ;; discard a completion if unused for this many hours.
    ;; (1 day = 24, 1 week = 168)
    ;; if this is 0, non-permanent completions
    ;; will not be saved unless these are used
    (customize-set-variable 'save-completions-retention-time 168)

(defun eos/complete-or-indent ()
  "Complete or indent."
  (interactive)
  (if (looking-at "\\_>")
      (when (fboundp 'complete)
        (complete nil)))
  (indent-according-to-mode))

(defun eos/complete-at-point-or-indent ()
  "This smart tab is a `minibuffer' compliant.
It acts as usual in the `minibuffer'.
Else, if mark is active, indents region.
Else if point is at the end of a symbol, expands it.
Else indents the current line."
  (interactive)
  (if (minibufferp)
      (unless (minibuffer-complete)
        (complete-symbol nil))
    (if mark-active
        (indent-region (region-beginning)
                       (region-end))
      (if (looking-at "\\_>")
          (complete-symbol nil)
        (indent-according-to-mode)))))

(defun eos/complete-buffer-or-indent ()
  "Company (complete anything (in-buffer)) or indent."
  (interactive)
  (if (looking-at "\\_>")
      (progn
        (when (fboundp 'company-complete)
          (funcall 'company-complete)))
    (indent-according-to-mode)))

(eos-call-func 'dynamic-completion-mode 1)

;; completion-list-mode-map
(define-key completion-list-mode-map (kbd "h") 'eos/describe-symbol-at-point)
(define-key completion-list-mode-map (kbd "?") 'eos/describe-symbol-at-point)
(define-key completion-list-mode-map (kbd "q") 'delete-completion-window)
(define-key completion-list-mode-map (kbd "d") 'delete-completion-line)
(define-key completion-list-mode-map (kbd "TAB") 'next-completion)
(define-key completion-list-mode-map (kbd "SPC") 'previous-completion)
(define-key completion-list-mode-map (kbd "C-j") 'choose-completion)
(define-key completion-list-mode-map (kbd "RET") 'choose-completion)
(define-key completion-list-mode-map (kbd "C-k") 'eos/kill-line)
(define-key completion-list-mode-map (kbd "ESC ESC") 'eos/focus-minibuffer-or-completions)))

;; global-map
(global-set-key (kbd "<M-tab>") 'eos/complete-at-point-or-indent)
(global-set-key (kbd "TAB") 'eos/complete-buffer-or-indent)

(require 'icomplete nil t)

;; custom
;; pending-completions number over which to apply `icomplete-compute-delay
(customize-set-variable 'icomplete-delay-completions-threshold 0)

;; maximum number of initial chars to apply `icomplete-compute-delay
(customize-set-variable 'icomplete-max-delay-chars 0)

;; completions-computation stall, used only with large-number completions
(customize-set-variable 'icomplete-compute-delay 0)

;; when non-nil, show completions when first prompting for input
(customize-set-variable 'icomplete-show-matches-on-no-input t)

;; when non-nil, hide common prefix from completion candidates
(customize-set-variable 'icomplete-hide-common-prefix nil)

;; maximum number of lines to use in the minibuffer
(customize-set-variable 'icomplete-prospects-height 1)

;; string used by Icomplete to separate alternatives in the minibuffer
;; (customize-set-variable 'icomplete-separator "  •  ")

;; specialized completion tables with which `icomplete should operate,
;; if this is t, `icomplete operates on all tables
(customize-set-variable 'icomplete-with-completion-tables t)

;; if non-nil, also use icomplete when completing in non-mini buffers
;; TODO: research
(customize-set-variable 'icomplete-in-buffer nil)

(defun eos/icomplete/kill-ring-save (&optional arg)
  "Expand and save current icomplete match (ARG) to the kill ring.
With a prefix argument, insert the match to the point in the
current buffer"
  (interactive "*P")
  (when (and (minibufferp)
             (bound-and-true-p icomplete-mode))
    (kill-new (field-string-no-properties))
    (if current-prefix-arg
        (progn
          (select-window (get-mru-window))
          (insert (car kill-ring)
                  (abort-recursive-edit))))))

(defun eos/icomplete/kill-ring ()
  "Insert the selected `kill-ring' item directly at point."
  (interactive)
  (let (candidates)
    ;; set candidates
    (setq candidates
          (cl-loop with cands = (delete-dups kill-ring)
                   for kill in cands
                   unless (or (< (length kill) 4)
                              (string-match "\\`[\n[:blank:]]+\\'" kill))
                   collect kill))
    ;; if candidates
    (if candidates
        (insert
         (completing-read "Kill-ring: " candidates nil t))
      (message "Mark ring is empty"))))

(defun eos/icomplete-mark-ring-line-string-at-pos (pos)
  "Return line string at position POS."
  (save-excursion
    (goto-char pos)
    (forward-line 0)
    (let ((line (car (split-string (thing-at-point 'line) "[\n\r]"))))
      (remove-text-properties 0 (length line) '(read-only) line)
      (if (string= "" line)
          "<EMPTY LINE>"
        line))))

(defun eos/icomplete/mark-ring ()
  "Browse `mark-ring' interactively."
  (interactive)
  (let* (candidates)
    (setq candidates
          (cl-loop with marks = (if (mark t)
                                    (cons (mark-marker) mark-ring)
                                  mark-ring)
                   for marker in marks
                   with max-line-number = (line-number-at-pos (point-max))
                   with width = (length (number-to-string max-line-number))
                   for m = (format (concat "%" (number-to-string width) "d: %s")
                                   (line-number-at-pos marker)
                                   (eos/icomplete-mark-ring-line-string-at-pos marker))
                   unless (and recip (assoc m recip))
                   collect (cons m marker) into recip
                   finally return recip))
    (if candidates
        (progn
          (let (candidate)
            (setq candidate (completing-read "Mark-ring: " candidates nil t))
            (goto-char (cdr (assoc candidate candidates))))))
    (message "Mark ring is empty")))

(defun eos/icomplete/toggle-completion-styles (&optional arg)
  "Toggle between completion styles.
With pregix ARG use basic completion instead.
These styles are described in `completion-styles-alist'."
  (interactive "*P")
  (when (and (minibufferp)
             (bound-and-true-p icomplete-mode))
    (let* ((completion-styles-original completion-styles)
           (basic    '(basic emacs22))
           (initials '(initials substring partial-completion))
           (prefix   '(partial-completion substring initials)))

      ;; choose basic, initials or prefix
      (if current-prefix-arg
          (setq-local completion-styles basic)
        (progn
          (if (not (eq (car completion-styles) 'initials))
              (setq-local completion-styles initials)
            (setq-local completion-styles prefix))))

      ;; show which current completion style
      (message "Completion style: %s "
               (format "%s" (car completion-styles))))))



(when (boundp 'icomplete-minibuffer-map)
  (progn
    (define-key icomplete-minibuffer-map (kbd "C-j") 'icomplete-force-complete-and-exit)
    (define-key icomplete-minibuffer-map (kbd "C-f") 'icomplete-forward-completions)
    (define-key icomplete-minibuffer-map (kbd "C-b") 'icomplete-backward-completions)

    ;; toogle styles
    (define-key icomplete-minibuffer-map (kbd "C-,") 'eos/icomplete/toggle-completion-styles)

    ;; basic
    (define-key icomplete-minibuffer-map (kbd "C-.")
      (lambda ()
        (interactive)
        (let ((current-prefix-arg t))
          (funcall 'eos/icomplete/toggle-completion-styles))))))

;; eos-utils-map
(define-key eos-utils-map (kbd "m") 'eos/icomplete/mark-ring)

;; global-map
(global-set-key (kbd "M-y") 'eos/icomplete/kill-ring)

;; enable (global)
(icomplete-mode 1)

(when (require 'dabbrev nil t)
  (progn

;; non-nil means case sensitive search.
(customize-set-variable 'dabbrev-upcase-means-case-search t)

;; whether dabbrev treats expansions as the same if they differ in case
;; a value of nil means treat them as different.
(customize-set-variable 'dabbrev-case-distinction t)))

(require 'hippie-exp nil t)

(define-key eos-complete-map (kbd "/") 'hippie-expand)

;; coding system to use with system messages
(customize-set-variable 'locale-coding-system 'utf-8)

;; coding system to be used for encoding the buffer contents on saving
(customize-set-variable 'buffer-file-coding-system 'utf-8)

;; add coding-system at the front of the priority list for automatic detection
(prefer-coding-system 'utf-8)

;; set coding system (UFT8)
(set-language-environment "UTF-8")
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)

(when (require 'simple nil t)
  (progn

;; don't omit information when lists nest too deep.
(customize-set-variable 'eval-expression-print-level nil)

;; column number display in the mode line
(eos-call-func 'column-number-mode 1)

;; buffer size display in the mode line
(eos-call-func 'size-indication-mode 1)))

(require 'prog-mode nil t)

(when (require 'server nil t)
  (progn

;; enable emacs server after startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (eos-call-func 'server-start)))))

(when (require 'help nil t)
  (progn

;; always select the help window
(customize-set-variable 'help-window-select t)

;; maximum height of a window displaying a temporary buffer.
(customize-set-variable 'temp-buffer-max-height
                        (lambda
                          (buffer)
                          (if (and (display-graphic-p) (eq (selected-window) (frame-root-window)))
                              (/ (x-display-pixel-height) (frame-char-height) 4)
                            (/ (- (frame-height) 4) 4))))

;; reference
;; (customize-set-variable 'temp-buffer-max-height 12)

(temp-buffer-resize-mode 1)))

(when (require 'help-mode nil t)
  (progn

(when (boundp 'help-mode-map)
  (define-key help-mode-map (kbd "C-j") 'push-button))))

(when (require 'help-fns nil t)
  (progn

(defun eos/describe-symbol-at-point (&optional arg)
  "Get help (documentation) for the symbol at point as ARG.

With a prefix argument, switch to the *Help* window.  If that is
already focused, switch to the most recently used window
instead."
  (interactive "P")
  (let ((symbol (symbol-at-point)))
    (when symbol
      (describe-symbol symbol)))
  (when current-prefix-arg
    (let ((help (get-buffer-window "*Help*")))
      (when help
        (if (not (eq (selected-window) help))
            (select-window help)
          (select-window (get-mru-window)))))))))

(when (require 'info nil t)
  (progn

;; non-nil means don’t record intermediate Info nodes to the history
(customize-set-variable 'info-history-skip-intermediate-nodes nil)))

;; 0 -> means do not display breadcrumbs
;; (customize-set-variable 'info-breadcrumbs-depth 0)

(when (require 'fringe nil t)
  (progn

;; custom
;; 0 -> ("no-fringes" . 0), remove ugly icons to represet new lines
;; ascii is more than enough to represent this information
;; default appearance of fringes on all frame
(customize-set-variable 'fringe-mode 0)))

(when (require 'files nil t)
  (progn

;; control use of version numbers for backup files.
(customize-set-variable 'version-control t)

;; non-nil means always use copying to create backup files
(customize-set-variable 'backup-by-copying t)

;; number of newest versions to keep when a new numbered backup is made
(customize-set-variable 'kept-new-versions 6)

;; number of oldest versions to keep when a new numbered backup is made
(customize-set-variable 'kept-old-versions 2)

;; if t, delete excess backup versions silently
(customize-set-variable 'delete-old-versions t)

;; non-nil means make a backup of a file the first time it is saved
(customize-set-variable 'make-backup-files nil)

;; non-nil says by default do auto-saving of every file-visiting buffer
(customize-set-variable 'auto-save-default nil)

;; most *NIX tools work best when files are terminated
;; with a newline
(customize-set-variable 'require-final-newline t)

;; backup directory list
;; alist of filename patterns and backup directory names
(customize-set-variable 'backup-directory-alist '(("" . "~/.emacs.d/backup")))))

;; create cache directory
(eos-mkdir (concat user-emacs-directory "cache"))

(require 'isearch nil t)

(when (require 'ffap nil t)
  (progn

;; eos-find-map
(define-key eos-find-map (kbd "f") 'find-file-at-point)
(define-key eos-find-map (kbd "d") 'dired-at-point)
(define-key eos-find-map (kbd "C-d") 'ffap-list-directory)))

(when (require 'locate nil t)
  (progn

(define-key eos-find-map (kbd "l") 'locate)))

(when (require 'replace nil t)
  (progn

(defun eos/occur-at-point ()
  "Occur with symbol or region as its arguments."
  (interactive)
  (let* ((bounds (if (use-region-p)
                     (cons (region-beginning) (region-end))
                   (bounds-of-thing-at-point 'symbol))))
    (if bounds
        (occur (buffer-substring-no-properties
                (car bounds) (cdr bounds)))
      (message "Occur-at-point: No candidate."))))

(global-set-key (kbd "M-s M-o") 'eos/occur-at-point)))

(require 'recentf nil t)

;; file to save the recent list into.
(customize-set-variable
 'recentf-save-file (concat user-emacs-directory "cache/recentf"))

(defun eos/icomplete/recentf-open-file ()
  "Open `recent-list' item in a new buffer.
The user's $HOME directory is abbreviated as a tilde."
  (interactive)
  (let ((files (mapcar 'abbreviate-file-name recentf-list)))
    (find-file
     (completing-read "Recentf: " files nil t))))

;; eos-find-map
(define-key eos-find-map (kbd "C-r") 'recentf-open-files)
(define-key eos-find-map (kbd "r") 'eos/icomplete/recentf-open-file)

(when (require 'bookmark nil t)
  (progn

;; custom
;; file in which to save bookmarks by default.
(customize-set-variable
 'bookmark-default-file (concat user-emacs-directory "cache/bookmarks"))))

(when (require 'savehist nil t)
  (progn

;; file name where minibuffer history is saved to and loaded from.
(customize-set-variable
 'savehist-file (concat user-emacs-directory "cache/history"))

;; if non-nil, save all recorded minibuffer histories.
(customize-set-variable 'savehist-save-minibuffer-history t)

;; enable savehist mode
(eos-call-func 'savehist-mode 1)))

(require 'frame nil t)

;; with some window managers you may have to set this to non-nil
;; in order to set the size of a frame in pixels, to maximize
;; frames or to make them fullscreen.
(customize-set-variable 'frame-resize-pixelwise t)

;; normalize before maximize
(customize-set-variable 'x-frame-normalize-before-maximize t)

;; set frame title format
(customize-set-variable 'frame-title-format
                        '((:eval (if (buffer-file-name)
                                     (abbreviate-file-name (buffer-file-name))
                                   "%b"))))

;; alist of parameters for the initial X window frame
(add-to-list 'initial-frame-alist '(fullscreen . fullheight))

;; (vertical-scroll-bars)
;; (bottom-divider-width . 0)
;; (right-divider-width . 6)

;; set font by face attribute (reference)
;; (set-face-attribute 'default nil :height)

;; alist of default values for frame creation
(add-to-list 'default-frame-alist '(internal-border-width . 2))

(defun eos-set-frame-font (font)
  "Set the default font to FONT."
  (cond ((find-font (font-spec :name font))
         (set-frame-font font nil t))))

;; set transparency after a frame is created
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (interactive)
            (eos/set-frame-transparency 0.9)))

;; fix first frame
(add-hook 'emacs-startup-hook
          (lambda ()
            (interactive)
            (make-frame)
            (delete-other-frames)))

;; binds
(global-set-key (kbd "C-x C-o") 'other-frame)

;; set frame font
(eos-set-frame-font "Hermit Light:pixelsize=20")

;; enable window divider
(window-divider-mode)

;; disable blink cursor
(blink-cursor-mode 0)

(when (require 'page nil t)
  (progn

;; enable narrow functions
(put 'narrow-to-page 'disabled nil)
(put 'narrow-to-region 'disabled nil)))

(when (require 'kmacro nil t)
  (progn

;; (define-key ctl-x-map (kbd "m") 'kmacro-keymap)
))

(when (require 'paren nil t)
  (progn

;; visualization of matching parens
(eos-call-func 'show-paren-mode 1)))

(when (require 'time nil t)
  (progn

;; seconds between updates of time in the mode line.
(customize-set-variable 'display-time-interval 15)

;; non-nil indicates time should be displayed as hh:mm, 0 <= hh <= 23
(customize-set-variable 'display-time-24hr-format t)

;; set format time string
(customize-set-variable 'display-time-format "%H:%M")

;; load-average values below this value won’t be shown in the mode line.
(customize-set-variable 'display-time-load-average-threshold 1.0)

;; enable display time
(eos-call-func 'display-time-mode 1)))

(require 'tmm nil t)

(when (require 'tool-bar nil t)
  (progn

;; disable
(eos-call-func 'tool-bar-mode 0)))

(when (require 'tooltip nil t)
  (progn

(eos-call-func 'tooltip-mode 0)))

(when (require 'menu-bar nil t)
  (progn

(eos-call-func 'menu-bar-mode 0)))

(when (require 'scroll-bar nil t)
  (progn

;; disable scroll bar
(eos-call-func 'scroll-bar-mode 0)))

(when (require 'hl-line nil t)
  (progn

;; enable highlight line
(eos-call-func 'global-hl-line-mode 1)))

(when (require 'linum nil t)
  (progn

;; format used to display line numbers.
(customize-set-variable 'linum-format " %2d ")))

(when (require 'display-line-numbers nil t)
  (progn

(add-hook 'prog-mode-hook 'display-line-numbers-mode)))

;; (eos-call-func 'global-display-line-numbers-mode 1)))

(when (require 'whitespace nil t)
  (progn

;; clean whitespace and newlines before buffer save
(add-hook 'before-save-hook 'whitespace-cleanup)

;; binds
(define-key ctl-x-map (kbd ".") 'whitespace-mode)))

(when (require 'subword nil t)
  (progn

(eos-call-func 'global-subword-mode 1)))

(when (require 'face-remap nil t)
  (progn

;; ctl-x-map (C-x)
(define-key ctl-x-map (kbd "=") 'text-scale-adjust)))

(when (require 'custom nil t)
  (progn

;; file used for storing customization information.
;; The default is nil, which means to use your init file
;; as specified by ‘user-init-file’.  If the value is not nil,
;; it should be an absolute file name.
(customize-set-variable
 'custom-file (concat (expand-file-name user-emacs-directory) "custom.el"))))

;; load custom-file
(eos-load-file custom-file)

(require 'forms nil t)

(when (require 'conf-mode nil t)
  (progn

(add-to-list 'auto-mode-alist '("\\.compose\\'" . conf-mode))
(add-to-list 'auto-mode-alist '("\\.dockerfile\\'" . conf-mode))))

(require 'exwm nil t)
(require 'exwm-core nil t)
(require 'exwm-config nil t)
(require 'exwm-workspace nil t)

;; set exwm workspaces number
(customize-set-variable 'exwm-workspace-number 0)

;; show workspaces in all buffers
(customize-set-variable 'exwm-workspace-show-all-buffers t)

;; non-nil to allow switching to buffers on other workspaces
(customize-set-variable 'exwm-layout-show-all-buffers t)

;; non-nil to force managing all X windows in tiling layout.
(customize-set-variable 'exwm-manage-force-tiling t)

;; exwn global keybindings
(customize-set-variable 'exwm-input-global-keys
                        `(([?\s-r] . exwm-reset)
                          ([?\s-q] . exwm-input-toggle-keyboard)
                          ;; ([?\s-w] . exwm-workspace-switch)
                          ;; ([?\s-k] . exwm-workspace-delete)
                          ;; ([?\s-a] . exwm-workspace-swap)

                          ;; create and switch to workspaces
                          ,@(mapcar (lambda (i)
                                      `(,(kbd (format "s-%d" i)) .
                                        (lambda ()
                                          (interactive)
                                          (exwm-workspace-switch-create ,i))))
                                    (number-sequence 0))))

;; The following example demonstrates how to use simulation keys to mimic
;; the behavior of Emacs.  The value of `exwm-input-simulation-keys` is a
;; list of cons cells (SRC . DEST), where SRC is the key sequence you press
;; and DEST is what EXWM actually sends to application.  Note that both SRC
;; and DEST should be key sequences (vector or string).
(customize-set-variable 'exwm-input-simulation-keys
                        '(
                          ;; movement
                          ([?\C-b] . [left])
                          ([?\M-b] . [C-left])
                          ([?\C-f] . [right])
                          ([?\M-f] . [C-right])
                          ([?\C-p] . [up])
                          ([?\C-n] . [down])
                          ([?\C-a] . [home])
                          ([?\C-e] . [end])
                          ([?\M-v] . [prior])
                          ([?\C-v] . [next])
                          ([?\C-d] . [delete])
                          ([?\C-k] . [S-end delete])

                          ;; firefox temporary
                          ([?\C-o] . [C-prior]) ; change tab mapping
                          ([?\C-k] . [C-w]) ; close tab mapping
                          ([?\C-j] . [return]) ; close tab mapping

                          ;; cut/paste.
                          ([?\C-w] . [?\C-x])
                          ([?\M-w] . [?\C-c])
                          ([?\C-y] . [?\C-v])

                          ;; Escape (cancel)
                          ([?\C-g] . [escape])

                          ;; search
                          ([?\C-s] . [?\C-f])))

;; this little bit will make sure that XF86 keys work in exwm buffers as well
(if (boundp 'exwm-input-prefix-keys)
    (progn
      (dolist (key '(XF86AudioLowerVolume
                     XF86AudioRaiseVolume
                     XF86PowerOff
                     XF86AudioMute
                     XF86AudioPlay
                     XF86AudioStop
                     XF86AudioPrev
                     XF86AudioNext
                     XF86ScreenSaver
                     XF68Back
                     XF86Forward
                     Scroll_Lock
                     print))
        (cl-pushnew key exwm-input-prefix-keys))))

;; set frame opacy
(add-hook 'exwm-init-hook
          (lambda ()
            (interactive)
            (eos/set-frame-transparency 0.9)))

;; All buffers created in EXWM mode are named "*EXWM*". You may want to
;; change it in `exwm-update-class-hook' and `exwm-update-title-hook', which
;; are run when a new X window class name or title is available.  Here's
;; some advice on this topic:
;; + Always use `exwm-workspace-rename-buffer` to avoid naming conflict.
;; + For applications with multiple windows (e.g. GIMP), the class names of
;; all windows are probably the same.  Using window titles for them makes
;; more sense.

;; update the buffer name by X11 window title
(add-hook 'exwm-update-title-hook
          (lambda ()
            (exwm-workspace-rename-buffer
             (concat exwm-class-name "|" exwm-title))))

(eos-call-func 'exwm-enable)

(when (require 'exwm-randr nil t)
  (progn

;; monitors: check the xrandr(1) output and use the same name/order
;; TODO: create a func that retrieves these values from xrandr

;; (customize-set-variable
;;  'exwm-randr-workspace-monitor-plist '(0 "eDP-1"
;;                                        1 "HDMI-1"))

(customize-set-variable 'exwm-workspace-number
                        (if (boundp 'exwm-randr-workspace-monitor-plist)
                            (progn
                              (/ (safe-length exwm-randr-workspace-monitor-plist) 2))
                          1))))

;; (exwm-randr-enable)

(when (require 'nsm nil t)
  (progn

;; if a potential problem with the security of the network
;; connection is found, the user is asked to give input
;; into how the connection should be handled
;; `high': This warns about additional things that many
;; people would not find useful.
;; `paranoid': On this level, the user is queried for
;; most new connections
(customize-set-variable 'network-security-level 'paranoid)

;; the file the security manager settings will be stored in.
(customize-set-variable 'nsm-setting-file
                        (expand-file-name "cache/netword-security-data" user-emacs-directory))))

(when (require 'tls nil t)
  (progn

;; indicate if certificates should be checked against trusted root certs
;; if this is ‘ask’, the user can decide whether to accept an
;; untrusted certificate
(customize-set-variable 'tls-checktrust t)

;; list of strings containing commands to
;; start TLS stream to a host
;; (customize-set-variable
;;  'tls-program
;;  '("openssl s_client -connect %h:%p -CAfile %t"))
(customize-set-variable
 'tls-program
 '("gnutls-cli --x509cafile %t -p %p %h --insecure"))))

(when (require  'gnutls nil t)
  (progn

;; if non-nil, this should be a TLS priority string
(customize-set-variable 'gnutls-algorithm-priority nil)

;; if non-nil, this should be t or a list of checks
;; per hostname regex
(customize-set-variable 'gnutls-verify-error nil)))

(when (require 'epa nil t)
  (progn

;; if non-nil, cache passphrase for symmetric encryption
(customize-set-variable
 'epa-file-cache-passphrase-for-symmetric-encryption t)

;; if t, always asks user to select recipients
(customize-set-variable 'epa-file-select-keys nil)

;; the gpg executable.
(customize-set-variable 'epg-gpg-program "gpg")

;; the pinentry mode.
;; In epa commands, a particularly useful mode is ‘loopback’, which
;; redirects all Pinentry queries to the caller, so Emacs can query
;; passphrase through the minibuffer, instead of external Pinentry
;; program
(customize-set-variable 'epa-pinentry-mode 'loopback)))

(require 'auth-source nil t)

(defun eos-auth-search (host user)
  "Lookup (format HOST USER PORT) password on auth-source default file."
  (let ((auth (auth-source-search :host host :user user)))
    (if auth
        (let ((secretf (plist-get (car auth) :secret)))
          (if secretf
              (funcall secretf)
            (message "Auth entry for %s@%s has no secret!"
                     user host)))
      (message "No auth entry found for %s@%s" user host))))

;; Note: If the auth-sources variable contains ~/.auth.gpg before
;; ~/.auth, the auth-source library will try to read the GnuPG
;; encrypted .gpg file first, before the unencrypted file.

;; list of authentication sources
(customize-set-variable
 'auth-sources '("~/.auth/auth.gpg" "~/.auth/netrc"))

(require 'password-store nil t)

(when (require 'package nil t)
  (progn

(customize-set-variable
 'package-archives
 '(("gnu" . "https://elpa.gnu.org/packages/")
   ("melpa" . "https://melpa.org/packages/")))))

;; enable (manually only)
;; (package-initialize)

(require 'async nil t)
(require 'async-bytecomp nil t)

;; to run command without displaying the output in a window
(add-to-list 'display-buffer-alist
             '("\\*Async Shell Command\\*" display-buffer-no-window))

(when (require 'elec-pair nil t)
  (progn

;; alist of pairs that should be used regardless of major mode.
(customize-set-variable 'electric-pair-pairs
                        '((?\{ . ?\})
                          (?\( . ?\))
                          (?\[ . ?\])
                          (?\" . ?\")))

(eos-call-func 'electric-pair-mode 1)))

(when (require 'newcomment nil t)
  (progn

;; global-map
(global-set-key (kbd "M-c") 'comment-or-uncomment-region)))

(when (require 'delsel nil t)
  (progn

;; delete selection-mode
(eos-call-func 'delete-selection-mode 1)))

(when (require 'iedit nil t)
  (progn

;; if no-nil, the key is inserted into global-map,
;; isearch-mode-map, esc-map and help-map.
(customize-set-variable 'iedit-toggle-key-default nil)

;; bind (iedit-mode-keymap)
(when (boundp 'iedit-mode-keymap)
  (progn
    (define-key iedit-mode-keymap (kbd "<tab>") 'eos/complete-buffer-or-indent)
    (define-key iedit-mode-keymap (kbd "M-n") 'iedit-next-occurrence)))

;; bind (global)
(global-set-key (kbd "C-;") 'iedit-mode)))

(when (require 'undo-tree nil t)
  (progn

;; define alias for redo
(defalias 'redo 'undo-tree-redo)

(define-key ctl-x-map (kbd "u") 'undo-tree-visualize)

;; enable
(eos-call-func 'global-undo-tree-mode 1)))

(require 'editorconfig nil t)

(eos-call-func 'editorconfig-mode)

(when (require 'buffer-move nil t)
  (progn

(define-key ctl-x-map (kbd "<C-up>") 'buf-move-up)
(define-key ctl-x-map (kbd "<C-down>") 'buf-move-down)
(define-key ctl-x-map (kbd "<C-left>") 'buf-move-left)
(define-key ctl-x-map (kbd "<C-right>")'buf-move-right)))

(when (require 'artist nil t)
  (progn

;; whether or not to incrementally update display when flood-filling
(customize-set-variable 'artist-flood-fill-show-incrementally nil)

;; whether or not to remove white-space at end of lines
(customize-set-variable 'artist-trim-line-endings nil)))

(when (require 'elfeed nil t)
  (progn

;; directory where elfeed will store its database.
(customize-set-variable
 'elfeed-db-directory
 (concat (expand-file-name user-emacs-directory) "elfeed"))

;; default directory for saving enclosures. Hide
(customize-set-variable
 'elfeed-enclosure-default-dir
 (concat (expand-file-name user-emacs-directory) "cache/elfeed"))))

(when (require 'dired nil t)
  (progn

;; enable dired-find-alternate-file
(put 'dired-find-alternate-file 'disabled nil)))

(when (require 'dired-async nil t)
  (progn

(eos-call-func 'dired-async-mode 1)

(if (boundp 'dired-mode-map)
    (progn
      (define-key dired-mode-map (kbd "RET") 'dired-find-alternate-file)
      (define-key dired-mode-map (kbd "C-j") 'dired-find-alternate-file)))))

(when (require 'dired-subtree nil t)
  (progn

;; default depth expanded by `dired-subtree-cycle'
(customize-set-variable 'dired-subtree-cycle-depth 2)

;; a prefix put into each nested subtree
(customize-set-variable 'dired-subtree-line-prefix "  ")

;; specifies how the prefix is fontified, subtree
(customize-set-variable 'dired-subtree-line-prefix-face 'subtree)

;; when non-nil, add a background face to a subtree listing.
(customize-set-variable 'dired-subtree-use-backgrounds nil)

(when (boundp 'dired-mode-map)
  (progn
    (define-key dired-mode-map (kbd "TAB") 'dired-subtree-insert)
    (define-key dired-mode-map (kbd "<M-tab>") 'dired-subtree-remove)))))

(when (require 'moody nil t)
  (progn

;; remove underline
(customize-set-variable 'x-underline-at-descent-line t)

;; change line height
(customize-set-variable 'moody-mode-line-height 2)

;; mode-line format
(customize-set-variable 'mode-line-format
                        '("%e"
                          ;; "%*%& %l:%c | %I "
                          " "
                          mode-line-mule-info
                          mode-line-modified
                          ;; " %*%& "
                          ;; mode-line-misc-info
                          ;; mode-line-percent-position
                          " %l:%c "
                          ;; mode-line-misc-info
                          moody-mode-line-buffer-identification
                          ""
                          " %m "
                          (vc-mode moody-vc-mode)
                          " "
                          ))))

(require 'rcirc nil t)

;; non-nil means log IRC activity to disk
;; logfiles are kept in `rcirc-log-directory
(customize-set-variable 'rcirc-log-flag nil)

;; major-mode function to use in multiline edit buffers
(customize-set-variable 'rcirc-multiline-major-mode 'text-mode)

;; format string to use in nick completions
(customize-set-variable 'rcirc-completion-fomart "%s:")

;; list of authentication passwords (not your job)
(customize-set-variable 'rcirc-authinfo nil)

;; coding system used to decode incoming irc messages
(customize-set-variable 'rcirc-decode-coding-system 'utf-8)

;; responses which will be hidden when `rcirc-omit-mode is enable
(customize-set-variable 'rcirc-omit-responses
                        '("JOIN" "PART" "QUIT" "NICK"))



;; (rcirc-omit-mode 1)))

(when (require 'shell nil t)
  (progn

;; hook
(add-hook 'shell-mode-hook
          (lambda()
            ;; do not display continuation lines.
            (setq truncate-lines nil)))))

(require 'eshell nil t)

;; ctl-x-map (C-x)
(define-key ctl-x-map (kbd "&") 'eshell)

(when (require 'term nil t)
  (progn

;; if non-nil, is file name to use for explicitly
;; requested inferior shell
(customize-set-variable
 'explicit-shell-file-name (getenv "SHELL"))

;; if non-nil, add a ‘/’ to completed directories
(customize-set-variable 'term-completion-addsuffix t)

;; regexp to recognize prompts in the inferior process
;; (customize-set-variable 'term-prompt-regexp "^\\(>\\|\\(->\\)+\\) *")
;; (customize-set-variable 'term-prompt-regexp ".*:.*>.*? ")

;; if non-nil, automatically list possibilities on partial completion.
(customize-set-variable 'term-completion-autolist t)

;; if true, buffer name equals process name
(customize-set-variable 'term-ansi-buffer-base-name t)

;; functions
(defun eos/term-send-kill-line ()
  "Kill line in multi-term mode with the possibility to paste it like in a normal shell."
  (interactive)
  (when (fboundp 'term-send-raw-string)
    (progn
      (kill-line)
      (term-send-raw-string "\C-k"))))

;; bind term-raw-map/term-mode-map with hook
(add-hook 'term-mode-hook
          (lambda ()
            (when (and (boundp 'term-raw-map)
                       (boundp 'term-mode-map))
              (progn
                ;; term-raw-map
                (define-key term-raw-map (kbd "s-q") 'term-line-mode)

                ;; term-mode-map
                (define-key term-mode-map (kbd "s-q") 'term-char-mode)))))

;; do not display continuation lines.
(add-hook 'term-mode-hook
          (lambda()
            (setq truncate-lines nil)))))

(when (require 'multi-term nil t)
  (progn

;; if this is nil, setup to environment variable of `SHELL'"
(customize-set-variable 'multi-term-program nil)

;; focus terminal window after you open dedicated window
(customize-set-variable 'multi-term-dedicated-select-after-open-p t)

;; the buffer name of term buffer.
(customize-set-variable 'multi-term-buffer-name "Term")

;; clt-x-map (C-x) prefix
(define-key ctl-x-map (kbd "<C-return>") 'multi-term)
(define-key ctl-x-map (kbd "C-x") 'multi-term-dedicated-toggle)))

(when (require 'shr nil t)
  (progn

;; frame width to use for rendering
(customize-set-variable 'shr-width 120)

;; if non-nil, use proportional fonts for text
(customize-set-variable 'shr-use-fonts nil)

;; if non-nil, respect color specifications in the HTML
(customize-set-variable 'shr-use-colors nil)

;; if non-nil, inhibit loading images
(customize-set-variable 'shr-inhibit-images nil)

;; images that have URLs matching this regexp will be blocked (regexp)
(customize-set-variable 'shr-blocked-images nil)))

(when (require 'eww nil t)
  (progn

;; prefix uRL to search engine
(customize-set-variable 'eww-search-prefix "https://www.google.com/search?q=")
;; (customize-set-variable eww-search-prefix "https://duckduckgo.com/html/?q=")

;; directory where files will downloaded
(customize-set-variable 'eww-download-directory "~/down")

;; symbol used to represent a checkbox
(customize-set-variable 'eww-form-checkbox-symbol "[ ]")

;; symbol used to represent a selected checkbox.
(customize-set-variable 'eww-form-checkbox-selected-symbol "[X]")
;; (customize-set-variable eww-form-checkbox-symbol "☐") ; Unicode hex 2610
;; (customize-set-variable eww-form-checkbox-selected-symbol "☑") ; Unicode hex 2611

(add-hook 'eww-mode-hook
          (lambda ()
            ;; disable truncate lines
            (setq truncate-lines nil)))))

(when (boundp 'eww-mode-map)
  (progn
    (define-key eww-mode-map (kbd "C-j") 'eww-follow-link)))

(when (require 'browse-url nil t)
  (progn

;; the name of the browser program used by ‘browse-url-generic’.
(customize-set-variable 'browse-url-generic-program "eww")

;; function to display the current buffer in a WWW browser: eww
(customize-set-variable 'browse-url-browser-function 'eww-browse-url)))

(when (require 'ispell nil t)
  (progn

;; program invoked by M-x ispell-word and M-x ispell-region commands.
(customize-set-variable 'ispell-program-name "aspell")

;; add display-buffer-alist
;; (add-to-list 'display-buffer-alist
;;              '("\\*Choices\\*" display-buffer-below-selected))

;; silent compiler
(defvar ispell-current-dictionary nil nil)

(defun eos/ispell/switch-dictionary ()
  "Switch dictionaries."
  (interactive)
  (let* ((dic ispell-current-dictionary)
         (change (if (string= dic "english") "brasileiro" "english")))
    (ispell-change-dictionary change)
    (message "Dictionary switched from %s to %s" dic change)))

;; enable globally
(ispell-minor-mode 1)

;; eos-sc-map
(define-key eos-sc-map (kbd "i") 'ispell-word)
(define-key eos-sc-map (kbd "I") 'ispell-buffer)))

(when (require 'flyspell nil t)
  (progn

;; string that is the name of the default dictionary
(customize-set-variable 'flyspell-default-dictionary "english")

;; hooks
(add-hook 'text-mode-hook 'flyspell-mode)
(add-hook 'prog-mode-hook 'flyspell-prog-mode)))

(require 'flycheck nil t)

(defun eos/set-flycheck-checker (checker)
  "Set flycheck CHECKER variable."
  (make-local-variable 'flycheck-checker)
  (when (boundp 'flycheck-checker)
    (setq flycheck-checker checker)))

;; init flycheck mode after some programming mode
;; is activated (c-mode, elisp-mode, etc).
(add-hook 'prog-mode-hook
          (lambda ()
            (interactive)
            (flycheck-mode 1)))

;; (global-flycheck-mode 1)

;; binds
(define-key eos-sc-map (kbd "C-g") 'keyboard-quit)
(define-key eos-sc-map (kbd "e") 'flycheck-list-errors)
(define-key eos-sc-map (kbd "b") 'flycheck-buffer)
(define-key eos-sc-map (kbd "d") 'flycheck-disable-checker)
(define-key eos-sc-map (kbd "m") 'flycheck-mode)
(define-key eos-sc-map (kbd "s") 'flycheck-select-checker)
(define-key eos-sc-map (kbd "?") 'flycheck-describe-checker)

;; (define-key eos-sc-map (kbd "M") 'flycheck-manual)
;; (define-key eos-sc-map
;;   (kbd "v") 'flycheck-verify-setup)

(when (require 'dmenu nil t)
  (progn

;; string to display in the dmenu prompt
(customize-set-variable 'dmenu-prompt-string "Dmenu: ")

;; determines on how many recently executed commands
;; dmenu should keep a record
(customize-set-variable 'dmenu-history-size 8)

;; file in which the dmenu state is
;; saved between Emacs sessions
(customize-set-variable
 'dmenu-save-file
 (expand-file-name "cache/dmenu-items" user-emacs-directory))

;; clt-x-map (C-x) prefix
(define-key ctl-x-map (kbd "C-l") 'dmenu)))

(when (require 'comint nil t)
  (progn

;; if non-nil, assume that the subprocess echoes any input.
(customize-set-variable 'comint-process-echoes t)

;; if non-nil, use comint-prompt-regexp to recognize prompts.
(customize-set-variable 'comint-use-prompt-regexp t)

;; regexp to recognize prompts in the inferior process.
;; (customize-set-variable 'comint-prompt-regexp ".*:.*>.*? ")

;; value to use for TERM when the system uses terminfo.
(customize-set-variable 'comint-terminfo-terminal "eterm-color")))

(when (require 'ielm nil t)
  (progn

;; if non-nil, after entering the first line of
;; an incomplete sexp, a newline will be inserted after the prompt.
(customize-set-variable 'ielm-dynamic-multiline-inputs t)

;; if non-nil, IELM will beep on error
(customize-set-variable 'ielm-noisy nil)

;; prompt used in IELM
(customize-set-variable 'ielm-prompt "elisp > ")

;; if non-nil, the IELM prompt is read only
(customize-set-variable 'ielm-prompt-read-only nil)))

(when (require 'sql nil t)
  (progn

;; select the SQL database product used
(customize-set-variable 'sql-product "sqlite")))

(when (require 'diff nil t)
  (progn

;; a string or list of strings specifying switches to be passed to diff
(customize-set-variable 'diff-switches "-u")))

(when (require 'ediff nil t)
  (progn

;; options to pass to `ediff-custom-diff-program'.
(customize-set-variable 'ediff-custom-diff-options "-U3")

;; the function used to split the main window between buffer-A and buffer-B
(customize-set-variable 'ediff-split-window-function 'split-window-horizontally)

;; function called to set up windows
(customize-set-variable 'ediff-window-setup-function 'ediff-setup-windows-plain)

(add-hook 'ediff-startup-hook 'ediff-toggle-wide-display)
(add-hook 'ediff-cleanup-hook 'ediff-toggle-wide-display)
(add-hook 'ediff-suspend-hook 'ediff-toggle-wide-display)))

(defun eos/compton ()
  "Call compton compositor utility."
  (interactive)
  (eos-call-proc "compton" "-b"))

;; start compton after emacs initialize
(add-hook 'after-init-hook #'eos/compton)

(when (require 'verb nil t)
  (progn

(add-hook 'org-ctrl-c-ctrl-c-hook
          (lambda ()
            (when (boundp 'verb-mode)
              (if verb-mode
                  (eos-call-func 'verb-send-request-on-point 'this-window)))))))

(when (require 'tramp nil t)
  (progn

;; set tramp default method
(customize-set-variable 'tramp-default-method "ssh")

;; if non-nil, chunksize for sending input to local process.
;; (customize-set-variable 'tramp-chunksize 512)

;; a value of t would require an immediate reread during filename completion,
;; nil means to use always cached values for the directory contents.
(customize-set-variable 'tramp-completion-reread-directory-timeout nil)

;; set tramp verbose level
(customize-set-variable 'tramp-verbose 4)

;; file which keeps connection history for tramp connections.
(customize-set-variable
 'tramp-persistency-file-name
 (concat (expand-file-name user-emacs-directory) "cache/tramp"))

;; connection timeout in seconds
(customize-set-variable 'tramp-connection-timeout 60)))

(defun eos/slock ()
  "Call slock utility."
  (interactive)
  (eos-call-proc "slock" nil))

(define-key ctl-x-map (kbd "<end>") 'eos/slock)

(defun eos/scrot ()
  "Call scrot utility."
  (interactive)
  (message "Saved in %s directory" (pwd))
  (eos-call-proc "scrot" nil))

;; global-map
(global-set-key (kbd "<print>") 'eos/scrot)

(defun eos/raise-volume ()
  "Raise volume by a factor of 5."
  (interactive)
  (async-shell-command "amixer -D default set Master 5+ unmute"))

(defun eos/reduce-volume ()
  "Reduce volume by a factor of -5."
  (interactive)
  (async-shell-command "amixer -D default set Master 5- unmute"))

(defun eos/toggle-audio ()
  "Toggle audio mute/unmute."
  (interactive)
  (async-shell-command "amixer -D default set Master"))

;; global-map
(global-set-key (kbd "s-0") 'eos/toggle-audio)
(global-set-key (kbd "s--") 'eos/reduce-volume)
(global-set-key (kbd "s-=") 'eos/raise-volume)

(when (require 'dashboard nil t)
  (progn

;; association list of items to show in the startup buffer.
(customize-set-variable 'dashboard-items
                        '((recents . 4)
                          (projects . 4)
                          (agenda . 4)
                          (bookmarks . 4)))

;; banners directory
(customize-set-variable 'dashboard-banners-directory
                        (concat user-emacs-directory "banner/"))

;; specify the startup banner
(customize-set-variable 'dashboard-startup-banner 1)

;; separator to use between the different pages.
(customize-set-variable 'dashboard-page-separator "

")

;; footer icon
(customize-set-variable 'dashboard-footer-icon
                        #(" " 0 1 (face dashboard-footer)))

;; a footer with some short message
(customize-set-variable 'dashboard-footer
                        "Litany Against Fear

 I must not fear.
 Fear is the mind-killer.
 Fear is the little-death that brings total obliteration.
 I will face my fear.
 I will permit it to pass over me and through me.
 And when it has gone past I will turn the inner eye to see its path.
 Where the fear has gone there will be nothing.
 Only I will remain.
 ")

;; when non nil, a footer will be displayed at the bottom.
(customize-set-variable 'dashboard-set-footer t)

;; a list of messages, one of which dashboard chooses to display
(customize-set-variable 'dashboard-footer-messages nil)

;; when non nil, file lists will have icons
(customize-set-variable 'dashboard-set-file-icons t)

;; when non nil, heading sections will have icons
(customize-set-variable 'dashboard-set-heading-icons nil)

;; set initial buffer choice (emacsclient fix)
(customize-set-variable 'initial-buffer-choice
                        (lambda ()
                          (let ((initial-buffer (get-buffer "*dashboard*")))
                            (unless initial-buffer
                              (setq initial-buffer (get-buffer "*scratch*")))
                            initial-buffer)))

;; init dashboard after emacs initialize
(add-hook 'after-init-hook 'dashboard-setup-startup-hook)))

(when (and (require 'emms nil t)
           (require 'emms-setup nil t))
  (progn

;; list of players that emms can use (only mpv)
(customize-set-variable 'emms-player-list '(emms-player-mpv))

;; the default directory to look for media files.
(customize-set-variable
 'emms-source-file-default-directory (expand-file-name "~/media"))

;; disable emms mode line
(add-hook 'emms-playlist-mode-hook
          (lambda ()
            (when (and (boundp 'emms-mode-line-active-p)
                       (fboundp 'emms-mode-line-disable))
              (progn
                (if emms-mode-line-active-p
                    (emms-mode-line-disable))))))))

;; if emms is available, enable it
(when (and (fboundp 'emms-all)
           (fboundp 'emms-default-players))
  (progn
    (funcall 'emms-all)
    (funcall 'emms-default-players)))

(when (require 'all-the-icons nil t)
  (progn

;; whether or not to include a foreground colour when formatting the icon
(customize-set-variable 'all-the-icons-color-icons nil)

;; the default adjustment to be made to the `raise' display property of an icon
(customize-set-variable 'all-the-icons-default-adjust -0.0)

;; the base Scale Factor for the `height' face property of an icon
(customize-set-variable 'all-the-icons-scale-factor 1.0)))

(require 'org nil t)

;; custom
;; when non-nil, fontify code in code blocks
(customize-set-variable 'org-src-fontify-natively t)

;; if non-nil, the effect of TAB in a code block is as if it were
;; issued in the language major mode buffer
(customize-set-variable 'org-src-tab-acts-natively t)

;; indentation for the content of a source code block.
(customize-set-variable 'org-edit-src-content-indentation 0)

;; confirm before evaluation
(customize-set-variable 'org-confirm-babel-evaluate nil)

;; how the source code edit buffer should be displayed
(customize-set-variable 'org-src-window-setup 'current-window)

;; non-nil means C-a and C-e behave specially in headlines and items
(customize-set-variable 'org-special-ctrl-a/e t)

;; languages which can be evaluated in Org buffers.
(customize-set-variable 'org-babel-load-languages
                        '((emacs-lisp . t)
                          (python . t)))

(defun eos/build ()
  "If the current buffer is 'init.org' the code-blocks are tangled.
The tangled file will be compiled."
  (interactive)

  ;; avoid running hooks when tangling.
  (let ((prog-mode-hook nil)
        (buffer (current-buffer)))

    ;; switch or open init.org file
    (find-file (expand-file-name "init.org" user-emacs-directory))

    ;; tangle and compile
    (org-babel-tangle)
    (byte-compile-file (concat user-emacs-directory "init.el"))

    ;; switch to the previous buffer
    (switch-to-buffer buffer)))

(add-hook 'org-mode-hook
          (lambda ()
            ;; do not truncate lines
            (setq truncate-lines nil)

            ;; set company backends
            (eos-set-company-backends
             '((company-ispell
                company-yasnippet
                company-dabbrev
                company-dabbrev-code)
               (company-files)))))

;; silent compiler
(defvar org-mode-map nil nil)

(define-key org-mode-map (kbd "C-M-i") 'eos/complete-buffer-or-indent)

(require 'tex-mode nil t)

(when (require 'text-mode nil t)
  (progn

(define-key text-mode-map (kbd "C-c C-g") 'keyboard-quit)
(define-key text-mode-map (kbd "TAB") 'eos/complete-buffer-or-indent)

(define-key text-mode-map (kbd "C-c C-k") 'with-editor-cancel)
(define-key text-mode-map (kbd "C-c C-c") 'with-editor-finish)

(add-hook 'text-mode-hook
          (lambda ()
            ;; turn on auto fill mode
            (turn-on-auto-fill)

            ;; set company backends
            (eos-set-company-backends
             '((company-ispell
                company-dabbrev)
               (company-files)))))))

(when (require 'markdown-mode nil t)
  (progn

(customize-set-variable 'markdown-command "multimarkdown")))

(when (boundp 'markdown-mode-map)
  (progn
    (define-key markdown-mode-map (kbd "TAB") 'eos/complete-buffer-or-indent)))

(when (require 'doc-view nil t)
  (progn

;; the base directory, where the PNG images will be saved
(customize-set-variable
 'doc-view-cache-directory
 (concat (expand-file-name user-emacs-directory) "cache/docview"))

;; in continuous mode reaching the page edge advances to next/previous page
(customize-set-variable 'doc-view-continuous t)))

(when (require 'dictionary nil t)
  (progn

;; create some clickable buttons on top of the window if non-nil
(customize-set-variable 'dictionary-create-buttons nil)

;; should the dictionary command reuse previous dictionary buffers?
(customize-set-variable 'dictionary-use-single-buffer t)

;; binds
(define-key eos-docs-map (kbd "d") 'dictionary-search)))

(when (and (require 'google-translate nil t)
           (require 'google-translate-smooth-ui nil t))
  (progn

;; alist of translation directions
;; each of direction could be selected directly in
;; the minibuffer during translation.
(customize-set-variable
 'google-translate-translation-directions-alist
 '(("pt" . "en") ("en" . "pt")))

;; default target language
(customize-set-variable
 'google-translate-default-target-language "pt")

;; default source language
;; "auto" if you want Google Translate to always detect the source language
(customize-set-variable 'google-translate-default-source-language
                        "auto")

;; determines where translation output will be displayed, if
;; `nil' the translation output will be displayed in the pop up
;; buffer (default).
(customize-set-variable 'google-translate-output-destination nil)))

(require 'notifications nil t)

(require 'eldoc nil t)

(when (require 'man nil t)
  (progn

(add-hook 'Man-mode-hook
          (lambda ()
            ;; don't truncate lines
            (setq truncate-lines nil)))

(when (boundp 'Man-mode-map)
  (progn
    (define-key Man-mode-map (kbd "C-j") 'push-button)))

;; eos-docs-map docs actions prefix map
(define-key eos-docs-map (kbd "m") 'man)))

(require 'dash-docs nil t)

;; default path for docsets
(customize-set-variable
 'dash-docs-docsets-path
 (concat (expand-file-name user-emacs-directory) "docsets"))

;; minimum length to start searching in docsets
(customize-set-variable 'dash-docs-min-length 2)

(defun eos/icomplete/dash-docs-search ()
  "Provide dash-docs candidates to `icomplete."
  (interactive)
  (dash-docs-create-common-connections)
  (dash-docs-create-buffer-connections)

  ;; get candidates
  (let* ((candidates (cl-loop for docset in (dash-docs-maybe-narrow-docsets "")
                              appending (dash-docs-search-docset docset "")))
         (candidate (completing-read "Docs for: " candidates nil nil)))
    ;; parse candidate
    (let* ((i 0)
           (n (catch 'nth-elt
                (dolist (value candidates)
                  (when (equal candidate (car value))
                    (throw 'nth-elt i))
                  (setq i (+ 1 i)))))
           (search-result (nth n candidates)))
      (pop search-result)

      ;; action: open documentation file
      (dash-docs-browse-url search-result))))

(defun eos-set-dash-docset (docset)
  "Activate a DOCSET, if available."
  (when (fboundp 'dash-docs-activate-docset)
    (funcall 'dash-docs-activate-docset docset)))

;; eos-docs-map
(define-key eos-docs-map (kbd "u") 'dash-docs-update-docset)
;; (define-key eos-docs-map (kbd "i") 'dash-docs-async-install-docset)
(define-key eos-docs-map (kbd "i") 'dash-docs-install-docset)
(define-key eos-docs-map (kbd "l") 'eos/icomplete/dash-docs-search)
(define-key eos-docs-map (kbd "a") 'dash-docs-activate-docset)
(define-key eos-docs-map (kbd "d") 'dash-docs-deactivate-docset)

(when (require 'rfc-mode nil t)
  (progn

;; the directory where RFC documents are stored
(customize-set-variable
 'rfc-mode-directory
 (concat (expand-file-name user-emacs-directory) "rfc/"))))

(require 'company nil t)

;; set echo delay
(customize-set-variable 'company-echo-delay 0)

;; idle delay in seconds until completion starts automatically
(customize-set-variable 'company-idle-delay nil)

;; maximum number of candidates in the tooltip
(customize-set-variable 'company-tooltip-limit 8)

;; set minimum prefix length
(customize-set-variable 'company-minimum-length 2)

;; if enabled, selecting item before first or after last wraps around
(customize-set-variable 'company-selection-wrap-around t)

;; sort by frequency
(customize-set-variable 'company-transformers
                        '(company-sort-by-occurrence))

;; whether to downcase the returned candidates.
(customize-set-variable 'company-dabbrev-downcase nil)

;; if enabled, disallow non-matching input
(customize-set-variable 'company-require-match nil)

;; When non-nil, align annotations to the right tooltip border
(customize-set-variable 'company-tooltip-align-annotations nil)

;; show candidates number
;; to select completions use: M-1, M-2, etc..
(customize-set-variable 'company-show-numbers t)

(defun eos/icomplete/company ()
  "Insert the selected company candidate directly at point."
  (interactive)
  (if (and
       (boundp 'company-common)
       (boundp 'company-candidates)
       (fboundp 'company-complete))
      (progn
        (unless company-candidates
          (company-complete))
        (unless (= (length company-candidates) 0)
          (let ((candidate (completing-read "ic-company: " company-candidates nil nil)))
            (delete-char (- (length company-common)))
            (insert candidate))))
    nil))

(defun eos-set-company-backends (backends)
  "Set company back ends with BACKENDS."
  (make-local-variable 'company-backends)
  (when (boundp 'company-backends)
    (setq company-backends backends)))

;; company-active-map
(when (boundp 'company-active-map)
  (progn
    (define-key company-active-map (kbd "TAB") 'company-complete-common)
    (define-key company-active-map (kbd "C-j") 'company-complete-selection)
    (define-key company-active-map (kbd "C-n") 'company-select-next)
    (define-key company-active-map (kbd "C-p") 'company-select-previous)))

;;eos-complete map
(define-key eos-complete-map (kbd "TAB") 'company-ispell)
(define-key eos-complete-map (kbd "f") 'company-files)
(define-key eos-complete-map (kbd "g") 'company-gtags)

;; enable globally
(eos-call-func 'global-company-mode 1)

(when (require 'company-statistics nil t)
  (progn

;; set company-statistics cache location
(customize-set-variable
 'company-statistics-file
 (concat user-emacs-directory "cache/company-statistics-cache.el"))

(add-hook 'company-mode-hook 'company-statistics-mode)))

(when (require 'yasnippet nil t)
  (progn

(define-key eos-complete-map (kbd "e") 'yas-expand)
(define-key eos-complete-map (kbd "i") 'yas-insert-snippet)
(define-key eos-complete-map (kbd "v") 'yas-visit-snippet-file)))

(when (boundp 'yas-keymap)
  (progn
    (define-key yas-keymap (kbd "<tab>") nil)
    (define-key yas-keymap (kbd "M-`") 'yas-next-field)))

(eos-call-func 'yas-global-mode 1)

(when (require 'imenu nil t)
  (progn

;; use a popup menu rather than a minibuffer prompt (no)
(customize-set-variable 'imenu-use-popup-menu nil)

(define-key eos-tags-map (kbd "i") 'imenu)))

(require 'gud nil t)

(when (require 'rmsbolt nil t)
  (progn

;; which output assembly format to use.
(customize-set-variable 'rmsbolt-asm-format "att")

;;    whether we should disassemble an output binary
(customize-set-variable 'rmsbolt-disassemble t)

;; rmsbolt mode lighter
(customize-set-variable 'rmsbolt-mode-lighter "RMS")))

(when (require 'cmake-ide nil t)
  (progn

(add-hook 'c-mode-hook 'cmake-ide-setup)
(add-hook 'c++-mode-hook 'cmake-ide-setup)))

(require 'compile nil t)

(defun eos-compile (dir command)
  "Compile COMMAND at specific DIR.
     Just a `compile` function wrapper."
  (interactive)
  (if (file-exists-p dir)
      (let ((default-directory dir))
        (compile command))))

;; don't truncate lines
(add-hook 'compilation-mode-hook
          (lambda ()
            (setq truncate-lines nil)))

;; fix compilation buffer colors
(add-hook 'compilation-filter-hook
          (lambda ()
            (when (eq major-mode 'compilation-mode)
              (ansi-color-apply-on-region
               compilation-filter-start (point-max)))))

(when (require 'magit nil t)
  (progn

(define-key ctl-x-map (kbd "j") 'magit-status)))

(require 'ede nil t)

(when (require 'projectile nil t)
  (progn

;; enable cache and choose indexing method
(customize-set-variable 'projectile-enable-caching t)
(customize-set-variable 'projectile-indexing-method 'hybrid)
(customize-set-variable 'projectile-completion-system 'default)

;; set bookmarks file localtion (cache)
(customize-set-variable 'projectile-known-projects-file
                        (concat user-emacs-directory "cache/projectile-bookmarks.eld"))

(customize-set-variable 'projectile-cache-file
                        (concat user-emacs-directory "cache/projectile.cache"))

(define-key eos-pm-map (kbd "g") 'projectile-grep)
(define-key eos-pm-map (kbd "t") 'projectile-find-tag)
(define-key eos-pm-map (kbd "f") 'projectile-find-file)
(define-key eos-pm-map (kbd "<f5>") 'projectile-compile-project)
(define-key eos-pm-map (kbd "&") 'projectile-run-eshell)
(define-key eos-pm-map (kbd "o") 'projectile-switch-project)
(define-key eos-pm-map (kbd "r") 'projectile-replace-regexp)
(define-key eos-pm-map (kbd "R") 'projectile-replace)
(define-key eos-pm-map (kbd "s") 'projectile-save-project-buffers)
(define-key eos-pm-map (kbd "d") 'projectile-discover-projects-in-directory)
(define-key eos-pm-map (kbd "c") 'projectile-cleanup-known-projects)
(define-key eos-pm-map (kbd "C") 'projectile-invalidate-cache)
(define-key eos-pm-map (kbd "U") 'projectile-purge-dir-from-cache)
(define-key eos-pm-map (kbd "u") 'projectile-purge-file-from-cache)
(define-key eos-pm-map (kbd ".") 'projectile-edit-dir-locals)
(define-key eos-pm-map (kbd "k") 'projectile-kill-buffers)
(define-key eos-pm-map (kbd "D") 'projectile-remove-known-project)))

(eos-call-func 'projectile-mode)

(defun eos/cc/load-rtags ()
  "Load rtags manually."
  (eos-load-file (concat user-emacs-directory "rtags/src/rtags.el"))

  ;; set rtags binary path
  (customize-set-variable
   'rtags-path
   (concat user-emacs-directory "rtags/build/bin/"))

  ;; method to use to display RTags results, like references
  (customize-set-variable 'rtags-display-result-backend 'default)

  ;; behavior for completing-read
  (customize-set-variable 'rtags-completing-read-behavior 'insert-default-marked))

;; eos-rtags-map
(define-key eos-rtags-map (kbd "l") 'rtags-taglist)
(define-key eos-rtags-map (kbd "I") 'rtags-install)
(define-key eos-rtags-map (kbd "y") 'rtags-symbol-type)
(define-key eos-rtags-map (kbd "l") 'rtags-symbol-info)
(define-key eos-rtags-map (kbd "n") 'rtags-rename-symbol)
(define-key eos-rtags-map (kbd "m") 'rtags-asm-file)
(define-key eos-rtags-map (kbd "h") 'rtags-find-file-history)
(define-key eos-rtags-map (kbd "x") 'rtags-fixit)
(define-key eos-rtags-map (kbd "d") 'rtags-diagnostics)
(define-key eos-rtags-map (kbd "c") 'rtags-compile-file)
(define-key eos-rtags-map (kbd "-") 'rtags-compilation-flags)
(define-key eos-rtags-map (kbd ".") 'rtags-find-functions-called-by-this-function)

(require 'cc-mode nil t)

;; c/c++ company backends
(defun eos/cc/set-company-backends ()
  "Set C/C++ common company backends."
  (eos-set-company-backends
   '((company-c-headers)
     (company-irony
      company-yasnippet
      company-dabbrev-code)
     (company-files))))

(add-hook 'c-mode-hook
          (lambda ()
            ;; set cc common company backends
            (eos/cc/set-company-backends)

            ;; set dash docset
            (eos-set-dash-docset '"C")

            ;; set flycheck checker
            (eos/set-flycheck-checker 'c/c++-clang)

            ;; load rtags
            (eos/cc/load-rtags)))

(add-hook 'c++-mode-hook
          (lambda ()
            ;; set cc common backends (company and flycheck)
            (eos/cc/set-company-backends)

            ;; set flycheck checker
            (eos/set-flycheck-checker 'c++-cppcheck)

            ;; set dash docset
            (eos-set-dash-docset '"C++")

            ;; load rtags
            (eos/cc/load-rtags)))

;; c-mode-map
(when (boundp 'c-mode-map)
  (progn
    ;; set rtags prefix map in c-mode map (C-c r)
    (define-key c-mode-map (kbd "C-c r") 'eos-rtags-map)

    ;; complete or indent
    (define-key c-mode-map (kbd "TAB") 'eos/complete-buffer-or-indent)))

;; c++-mode-map
(when (boundp 'c++-mode-map)
  (progn
    ;; set rtags prefix map in c-mode map (C-c r)
    (define-key c++-mode-map (kbd "C-c r") 'eos-rtags-map)

    ;; complete or indent
    (define-key c++-mode-map (kbd "TAB") 'eos/complete-buffer-or-indent)))

(when (require 'irony nil t)
  (progn

;; irony-mode hooks
(add-hook 'irony-mode-hook 'electric-pair-mode)

;; cc-mode hooks
(add-hook 'c-mode-hook 'irony-mode)
(add-hook 'c++-mode-hook 'irony-mode)
(add-hook 'objc-mode-hook 'irony-mode)))

(when (require 'irony-cdb nil t)
  (progn

;; hooks
(add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)))

(when (require 'company-irony nil t)
  (progn

(add-hook 'irony-mode-hook 'company-irony-setup-begin-commands)))

(require 'company-c-headers nil t)

(when (require 'lisp-mode nil t)
  (progn

;; number of columns to indent the second line of a (def...) form
(customize-set-variable 'lisp-body-indent 2)))

(when (require 'elisp-mode nil t)
  (progn

;; enable minor modes
(add-hook 'emacs-lisp-mode-hook
          (lambda()
            (eos-call-func 'eldoc-mode 1)))

(add-hook 'lisp-interaction-mode-hook
          (lambda()
            (eos-call-func 'eldoc-mode 1)))

;; set backends (company, flychecker, dash-docs)
(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            ;; set company backends
            (eos-set-company-backends
             '((company-elisp
                company-yasnippet
                company-dabbrev-code)
               (company-files)))

            ;; set flycheck checker
            (eos/set-flycheck-checker 'emacs-lisp)

            ;; activate dash docset (emacs)
            (eos-set-dash-docset "Emacs Lisp")))

;; emacs-lisp-mode-map
(when (boundp 'emacs-lisp-mode-map)
  (progn
    ;; eval
    (define-key emacs-lisp-mode-map (kbd "C-c C-f") 'eval-defun)
    (define-key emacs-lisp-mode-map (kbd "C-c C-r") 'eval-region)
    (define-key emacs-lisp-mode-map (kbd "C-c C-c") 'eval-buffer)

    ;; complete
    (define-key emacs-lisp-mode-map (kbd "<tab>") 'eos/complete-buffer-or-indent)

    ;; quality of life (unbind)
    (define-key emacs-lisp-mode-map (kbd "DEL") 'nil)
    (define-key emacs-lisp-mode-map (kbd "ESC") 'nil)
    (define-key emacs-lisp-mode-map (kbd "C-x") 'nil)
    (define-key emacs-lisp-mode-map (kbd "C-M-x") 'nil)
    (define-key emacs-lisp-mode-map (kbd "C-M-q") 'nil)))))

(require 'company-elisp nil t)

(when (require 'sh-script nil t)
  (progn

(add-hook 'sh-mode-hook
          (lambda ()
            ;; set company backends
            (eos-set-company-backends
             '((company-shell
                company-shell-env
                company-yasnippet
                company-dabbrev-code)
               (company-files)))

            ;; set flycheck backends
            (eos/set-flycheck-checker 'sh-shellcheck)))))

(when (require 'fish-mode nil t)
  (progn

(add-hook 'fish-mode-hook
          (lambda ()
            ;; set company backends
            (eos-set-company-backends
             '((company-fish-shell
                company-yasnippet
                company-shell
                company-shell-env
                company-dabbrev-code)
               (company-files)))))))

(require 'company-shell nil t)

(when (require 'lua-mode nil t)
  (progn

;; non-nil means display lua-process-buffer after sending a command.
(customize-set-variable 'lua-process-buffer t)

;; default application to run in Lua process
(customize-set-variable 'lua-default-application "lua")

;; command switches for lua-default-application
(customize-set-variable 'lua-default-command-switches "-i")

;; amount by which Lua subexpressions are indented
(customize-set-variable 'lua-indent-level 4)

;; if non-nil, contents of multiline string will be indented
(customize-set-variable 'lua-indent-string-contents t)

;; jump to innermost traceback location in *lua* buffer
;; when this variable is non-nil and a traceback occurs
;; when running Lua code in a process, jump immediately
;; to the source code of the innermost traceback location
(customize-set-variable 'lua-jump-on-traceback t)

(add-hook 'lua-mode-hook
          (lambda ()
            ;; set company backends
            (eos-set-company-backends
             '((company-yasnippet
                company-keywords
                company-gtags
                company-dabbrev
                company-dabbrev-code
                company-keywords)
               (company-files)))

            ;; set flycheck checker
            (eos/set-flycheck-checker 'lua)

            ;; activate dash docset
            (eos-set-dash-docset "Lua")))

;; add auto-mode
(add-to-list 'auto-mode-alist '("\\.lua$" . lua-mode))
(add-to-list 'interpreter-mode-alist '("lua" . lua-mode))))

(require 'tcl nil t)

(require 'cperl-mode nil t)

(when (require 'python nil t)
  (progn

;; default Python interpreter for shell
(customize-set-variable 'python-shell-interpreter "python")

;; non-nil means template skeletons will be automagically inserted
(customize-set-variable 'python-skeleton-autoinsert t)

;; enable modes
(add-hook 'python-mode-hook
          (lambda()
            ;; enable eldoc mode
            (eos-call-func 'eldoc-mode 1)))

;; set backends
(add-hook 'python-mode-hook
          (lambda ()
            ;; set company backends
            (eos-set-company-backends
             '((company-yasnippet
                company-keywords
                company-dabbrev-code)
               (company-files)))

            ;; set flycheck checker
            (eos/set-flycheck-checker 'python-pycompile)

            ;; set dash docsets
            (eos-set-dash-docset '"Python 3")))))

(when (require 'go-mode nil t)
  (progn

(add-hook 'go-mode-hook
          (lambda ()
            ;; set company backends
            (eos-set-company-backends
             '((company-yasnippet
                company-keywords
                company-dabbrev-code)
               (company-files)))

            ;; set flycheck checker (go lint)
            (eos/set-flycheck-checker 'go-golint)

            ;; set dash docsets
            (eos-set-dash-docset '"Go")))

;; add (*.go . go-mode) to auto-mode-alist
;; init go-mode when a file with the extersion .go is opened
(add-to-list 'auto-mode-alist '("\\.go\\'" . go-mode))))

(require 'ess-r-mode nil t)

(require 'julia-mode nil t)

(require 'ess-julia nil t)

(require 'csharp-mode nil t)

(when (require 'elixir-mode nil t)
  (progn

;; additional arguments to `mix format`'
;; (customize-set-variable 'elixir-format-arguments nil)

(add-hook 'elixir-mode-hook
          (lambda ()
            ;; set company backends
            (eos-set-company-backends
             '((company-yasnippet
                company-keywords
                company-dabbrev-code)
               (company-files)))

            ;; set syntax checker
            ;; eos/flycheck/set-cheker '<elixir-checker>)

            ;; set dash docsets
            (eos-set-dash-docset '"Elixir")))))

(require 'vhdl-mode nil t)

(require 'verilog nil t)

(require 'cmake-mode nil t)

(when (require 'mql-mode nil t)
  (progn

(add-hook 'mql-mode-hook
          (lambda ()
            ;; set company backends
            (eos-set-company-backends
             '((company-gtags
                company-yasnippet
                company-dabbrev
                company-dabbrev-code)
               (company-files)))

            ;; select flycheck checker (use gcc)
            (eos/set-flycheck-checker 'c/c++-gcc)

            ;; activate mql5 docset
            (eos-set-dash-docset '"mql5")))))

(when (require 'web-mode nil t)
  (progn

;; add files extensions to web-mode
(add-to-list 'auto-mode-alist '("\\.php\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.erb\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.phtml\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.djhtml\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.as[cp]x\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.[agj]sp\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.mustache\\'" . web-mode))))

(when (boundp 'web-mode-engines-alist)
  (progn
    (add-to-list 'web-mode-engines-alist '(("php" . "\\.phtml\\'")))))

(eos-load-file (expand-file-name "adapt.el" user-emacs-directory))
