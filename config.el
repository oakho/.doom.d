;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; Include the required packages
(require 'treesit)
(require 'sgml-mode)

;; Start Setup
(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)

;; Turn on pixel scrolling
(pixel-scroll-precision-mode t)

;; Turn on abbrev mode
(setq-default abbrev-mode t)

(set-frame-parameter (selected-frame) 'alpha '(97 97))
(add-to-list 'default-frame-alist '(alpha 97 97))

(setq doom-modeline-height 30)

(use-package nerd-icons-ibuffer
  :ensure t
  :hook (ibuffer-mode . nerd-icons-ibuffer-mode))

(use-package! nerd-icons
  :custom

  ;; (nerd-icons-font-family  "Iosevka Nerd Font Mono")
  ;; (nerd-icons-scale-factor 2)
  ;; (nerd-icons-default-adjust -.075)
  (doom-modeline-major-mode-icon t))

(use-package! olivetti
  :config
  (setq-default olivetti-body-width 180)
  (add-hook 'mixed-pitch-mode-hook  (lambda () (setq-local olivetti-body-width 80))))

(use-package! auto-olivetti
  :custom
  (auto-olivetti-enabled-modes '(text-mode prog-mode helpful-mode ibuffer-mode image-mode))
  :config
  (auto-olivetti-mode))

(use-package! diff-hl
  :config
  (custom-set-faces!
    `((diff-hl-change)
      :foreground ,(doom-blend (doom-color 'bg) (doom-color 'blue) 0.5))
    `((diff-hl-insert)
      :foreground ,(doom-blend (doom-color 'bg) (doom-color 'green) 0.5))))

(setq corfu-auto-delay 0.5)

(use-package! orderless
  :config
  (add-to-list 'orderless-matching-styles 'char-fold-to-regexp))

(use-package! corfu
  :config
  (defun corfu-enable-in-minibuffer ()
    "Enable Corfu in the minibuffer if `completion-at-point' is bound."
    (when (where-is-internal #'completion-at-point (list (current-local-map)))
      ;; (setq-local corfu-auto nil) ;; Enable/disable auto completion
      (setq-local corfu-echo-delay nil ;; Disable automatic echo and popup
		  corfu-popupinfo-delay nil)
      (corfu-mode 1)))

  (after! corfu
    (map! :map corfu-map "TAB" #'corfu-insert))

  (add-hook 'minibuffer-setup-hook #'corfu-enable-in-minibuffer))

(after! org-roam
  ;; Define advise
  (defun hp/org-roam-capf-add-kind-property (orig-fun &rest args)
    "Advice around `org-roam-complete-link-at-point' to add :company-kind property."
    (let ((result (apply orig-fun args)))
      (append result '(:company-kind (lambda (_) 'org-roam)))))
  ;; Wraps around the relevant functions
  (advice-add 'org-roam-complete-link-at-point :around #'hp/org-roam-capf-add-kind-property)
  (advice-add 'org-roam-complete-everywhere :around #'hp/org-roam-capf-add-kind-property))

(after! citar
  ;; Define advise
  (defun hp/citar-capf-add-kind-property (orig-fun &rest args)
    "Advice around `org-roam-complete-link-at-point' to add :company-kind property."
    (let ((result (apply orig-fun args)))
      (append result '(:company-kind (lambda (_) 'reference)))))
  ;; Wraps around the relevant functions
  (advice-add 'citar-capf :around #'hp/citar-capf-add-kind-property))

(after! (org-roam kind-icon)
  (add-to-list
   'kind-icon-mapping
   `(org-roam ,(nerd-icons-codicon "nf-cod-symbol_interface") :face font-lock-type-face)))

(after! (org-roam nerd-icons-corfu)
  (add-to-list
   'nerd-icons-corfu-mapping
   '(org-roam :style "cod" :icon "symbol_interface" :face font-lock-type-face)))

(use-package! lsp-ui
  :config
  (setq lsp-ui-doc-delay 2
	lsp-ui-doc-max-width 80)
  (setq lsp-signature-function 'lsp-signature-posframe))

(use-package! yasnippet
  :config
  ;; It will test whether it can expand, if yes, change cursor color
  (defun hp/change-cursor-color-if-yasnippet-can-fire (&optional field)
    (interactive)
    (setq yas--condition-cache-timestamp (current-time))
    (let (templates-and-pos)
      (unless (and yas-expand-only-for-last-commands
		   (not (member last-command yas-expand-only-for-last-commands)))
	(setq templates-and-pos (if field
				    (save-restriction
				      (narrow-to-region (yas--field-start field)
							(yas--field-end field))
				      (yas--templates-for-key-at-point))
				  (yas--templates-for-key-at-point))))
      (set-cursor-color (if (and templates-and-pos (first templates-and-pos)
				 (eq evil-state 'insert))
			    (doom-color 'red)
			  (face-attribute 'default :foreground)))))
  :hook (post-command . hp/change-cursor-color-if-yasnippet-can-fire))

(use-package! svg-tag-mode
  :config
  (defconst date-re "[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}")
  (defconst time-re "[0-9]\\{2\\}:[0-9]\\{2\\}")
  (defconst day-re "[A-Za-z]\\{3\\}")
  (defconst day-time-re (format "\\(%s\\)? ?\\(%s\\)?" day-re time-re))

  (defun svg-progress-percent (value)
    (svg-image (svg-lib-concat
		(svg-lib-progress-bar
		 (/ (string-to-number value) 100.0) nil
		 :height 0.8 :foreground (doom-color 'fg) :background (doom-color 'bg)
		 :margin 0 :stroke 2 :radius 3 :padding 2 :width 11)
		(svg-lib-tag (concat value "%") nil
			     :height 0.8 :foreground (doom-color 'fg) :background (doom-color 'bg)
			     :stroke 0 :margin 0)) :ascent 'center))

  (defun svg-progress-count (value)
    (let* ((seq (mapcar #'string-to-number (split-string value "/")))
	   (count (float (car seq)))
	   (total (float (cadr seq))))
      (svg-image (svg-lib-concat
		  (svg-lib-progress-bar (/ count total) nil
					:foreground (doom-color 'fg)
					:background (doom-color 'bg) :height 0.8
					:margin 0 :stroke 2 :radius 3 :padding 2 :width 11)
		  (svg-lib-tag value nil
			       :foreground (doom-color 'fg)
			       :background (doom-color 'bg)
			       :stroke 0 :margin 0 :height 0.8)) :ascent 'center)))

  (set-face-attribute 'svg-tag-default-face nil :family "Alegreya Sans")
  (setq svg-tag-tags
	`(;; Progress e.g. [63%] or [10/15]
	  ("\\(\\[[0-9]\\{1,3\\}%\\]\\)" . ((lambda (tag)
					      (svg-progress-percent (substring tag 1 -2)))))
	  ("\\(\\[[0-9]+/[0-9]+\\]\\)" . ((lambda (tag)
					    (svg-progress-count (substring tag 1 -1)))))
	  ;; Task priority e.g. [#A], [#B], or [#C]
	  ("\\[#A\\]" . ((lambda (tag) (svg-tag-make tag :face 'error :inverse t :height .85
						     :beg 2 :end -1 :margin 0 :radius 10))))
	  ("\\[#B\\]" . ((lambda (tag) (svg-tag-make tag :face 'warning :inverse t :height .85
						     :beg 2 :end -1 :margin 0 :radius 10))))
	  ("\\[#C\\]" . ((lambda (tag) (svg-tag-make tag :face 'org-todo :inverse t :height .85
						     :beg 2 :end -1 :margin 0 :radius 10))))
	  ;; Keywords
	  ("TODO" . ((lambda (tag) (svg-tag-make tag :inverse t :height .85 :face 'org-todo))))
	  ("HOLD" . ((lambda (tag) (svg-tag-make tag :height .85 :face 'org-todo))))
	  ("DONE\\|STOP" . ((lambda (tag) (svg-tag-make tag :inverse t :height .85 :face 'org-done))))
	  ("NEXT\\|WAIT" . ((lambda (tag) (svg-tag-make tag :inverse t :height .85 :face '+org-todo-active))))
	  ("REPEAT\\|EVENT\\|PROJ\\|IDEA" .
	   ((lambda (tag) (svg-tag-make tag :inverse t :height .85 :face '+org-todo-project))))
	  ("REVIEW" . ((lambda (tag) (svg-tag-make tag :inverse t :height .85 :face '+org-todo-onhold))))))

  :hook (org-mode . svg-tag-mode)
  )

;; End Setup

(defvar html-ts-handlebars-font-lock-rules
  '(;; HTML font locking
    :language html
    :feature delimiter
    ([ "<!" "<" ">" "/>" "</"] @font-lock-bracket-face)

    :language html
    :feature comment
    ((comment) @font-lock-comment-face)

    :language html
    :feature attribute
    ((attribute (attribute_name)
		@font-lock-constant-face
		"=" @font-lock-bracket-face
		(quoted_attribute_value) @font-lock-string-face))

    :language html
    :feature tag
    ((script_element
      [(start_tag (tag_name) @font-lock-doc-face)
       (end_tag (tag_name) @font-lock-doc-face)]))

    :language html
    :feature tag
    ([(start_tag (tag_name) @font-lock-function-call-face)
      (self_closing_tag (tag_name) @font-lock-function-call-face)
      (end_tag (tag_name)  @font-lock-function-call-face)])
    :language html
    :override t
    :feature tag
    ((doctype) @font-lock-keyword-face)

    ;; Handlebars font locking
    :language handlebars
    :feature delimiter
    (["{{" "}}" "{{!" "}}" "{{!--" "--}}"] @font-lock-bracket-face)

    :language handlebars
    :feature comment
    ((comment) @font-lock-comment-face)

    :language handlebars
    :feature variable
    ((variable) @font-lock-variable-name-face)

    :language handlebars
    :feature helper
    ((helper) @font-lock-function-name-face)))

(defun html-ts-handlebars-imenu-node-p (node)
  "Return t if NODE is a valid imenu node."
  (and (string-match-p "^h[0-6]$" (treesit-node-text node))
       (equal (treesit-node-type (treesit-node-parent node))
	      "start_tag")))

(defun html-ts-handlebars-imenu-name-function (node)
  "Return the name of the imenu entry for NODE."
  (let ((name (treesit-node-text node)))
    (if (html-ts-handlebars-imenu-node-p node)
	(concat name " / "
		(thread-first (treesit-node-parent node)
			      (treesit-node-next-sibling)
			      (treesit-node-text)))
      name)))

(defun html-ts-handlebars-setup ()
  "Setup for `html-ts-handlebars-mode'."
  (interactive)
  (setq-local treesit-font-lock-settings
	      (apply #'treesit-font-lock-rules
		     html-ts-handlebars-font-lock-rules))
  (setq-local font-lock-defaults nil)
  (setq-local treesit-font-lock-feature-list
	      '((comment)
		(constant tag attribute variable helper)
		(declaration)
		(delimiter)))
  (setq-local treesit-simple-imenu-settings
	      `(("Heading" html-ts-handlebars-imenu-node-p nil html-ts-handlebars-imenu-name-function)))

  (setq-local treesit-font-lock-level 5)
  (setq-local treesit-simple-indent-rules
	      `((html
		 ;; Note: in older grammars, `document' was known as
		 ;; `fragment'.
		 ((parent-is "document") parent-bol 0)
		 ((node-is ,(regexp-opt '("element" "self_closing_tag"))) parent 2)
		 ((node-is "end_tag") parent 0)
		 ((node-is "/") parent 0)
		 ((parent-is "element") parent 2)
		 ((node-is "text") parent 0)
		 ((node-is "attribute") prev-sibling 0)
		 ((node-is ">") parent 0)
		 ((parent-is "start_tag") prev-sibling 0)
		 (no-node parent 0))))
  (treesit-major-mode-setup))

;;;###autoload
(define-derived-mode html-ts-handlebars-mode sgml-mode "HTML[ts]"
  "Major mode for editing HTML."
  :syntax-table sgml-mode-syntax-table
  (when (treesit-ready-p 'html)
    (treesit-parser-create 'html)
    (html-ts-handlebars-setup)))

(provide 'html-ts-handlebars-mode)


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Antoine Lagadec"
      user-mail-address "hello@oakho.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-vibrant)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; Custom Functions
(defun oakho/toggle-quotes ()
  "Toggle single quoted string to double or vice versa, and
  flip the internal quotes as well.  Best to run on the first
  character of the string."
  (interactive)
  (save-excursion
    (re-search-backward "[\"']")
    (let* ((start (point))
	   (old-c (char-after start))
	   new-c)
      (setq new-c
	    (case old-c
		  (?\" "'")
		  (?\' "\"")))
      (setq old-c (char-to-string old-c))
      (delete-char 1)
      (insert new-c)
      (re-search-forward old-c)
      (backward-char 1)
      (let ((end (point)))
	(delete-char 1)
	(insert new-c)
	(replace-string new-c old-c nil (1+ start) end)))))


(defun oakho/switch-to-previous-buffer ()
  "Switch to the previous visited buffer"
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) 1)))

(defun oakho/goto-line-with-feedback (&optional line)
  "Show line numbers temporarily, while prompting for the line number input."
  (interactive "P")
  (if line
      (goto-line line)
    (if (spacemacs/toggle-line-numbers-status)
	(progn (define-key minibuffer-local-map (kbd "s-l") nil)
	       (spacemacs/toggle-line-numbers-off))
      (unwind-protect
	  (progn
	    (spacemacs/toggle-line-numbers-on)
	    (define-key minibuffer-local-map (kbd "s-l") 'top-level)
	    (goto-line (read-number "Goto line: " (line-number-at-pos))))
	(oakho/goto-line-with-feedback)))))

(defun oakho/unindent-region ()
  (interactive)
  (indent-region (region-beginning) (region-end) -1))

(defun oakho/switch-to-erc (&optional n)
  (interactive)
  (unless n
    (setq n 1))
  (let ((buffers (and (fboundp 'erc-buffer-list)
		      (erc-buffer-list))))
    (switch-to-buffer
     (if (< n 0)
	 (nth (+ (length buffers) n)
	      buffers)
       (bury-buffer)
       (nth n buffers)))))

(defun oakho/erc-start-or-switch ()
  "Connect to ERC, or switch to last active buffer."
  (interactive)
  (if (get-buffer "irc.freenode.net:6667") ;; ERC already active?

      (erc-track-switch-buffer 1) ;; yes: switch to last active
    (when (y-or-n-p "Start ERC? ") ;; no: maybe start ERC
      (erc :server "irc.freenode.net" :port 6667 :nick "oakho" :full-name "bar"))))

(defun oakho/smart-beginning-of-line ()
  "Move point to first non-whitespace character or beginning-of-line.
   Move point to the first non-whitespace character on this line.
   If point was already at that position, move point to beginning of line."
  (interactive)
  (let ((oldpos (point)))
    (back-to-indentation)
    (and (= oldpos (point))
	 (beginning-of-line))))

(defun oakho/back-to-other-window (&optional kill-current-buffer)
  "Switch to other window and go back to a single frame layout."
  (interactive)
  (if kill-current-buffer (kill-this-buffer))
  (other-window -1)
  (delete-other-windows))

(defun oakho/kill-other-buffers ()
  "Kill all other buffers."
  (interactive)
  (mapc 'kill-buffer
	(delq (current-buffer)
	      (remove-if-not 'buffer-file-name (buffer-list)))))


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(after! centaur-tabs
  (setq centaur-tabs-set-bar 'right))

(after! helm
  (setq helm-recentf-fuzzy-match t)
  (setq helm-buffers-fuzzy-matching t)
  (setq helm-recentf-fuzzy-match t)
  (setq helm-M-x-fuzzy-match t)
  (setq helm-semantic-fuzzy-match t)
  (setq helm-imenu-fuzzy-match t)
  (setq helm-apropos-fuzzy-match t)
  (setq helm-lisp-fuzzy-completion t)
  (setq helm-move-to-line-cycle-in-source nil)

  (setq helm-autoresize-max-height 40)
  (setq helm-autoresize-min-height 5)
  (helm-autoresize-mode t))

(map! "s-," #'oakho/switch-to-previous-buffer
      "s-k" #'kill-this-buffer
      "C-c k" #'oakho/kill-other-buffers

      ;; Window Management
      "M-ç" #'previous-multiframe-window
      "M-à" #'next-multiframe-window
      "M-&" #'delete-other-windows
      "M-é" #'split-window-below
      "M-\"" #'split-window-right

      ;; Begin/End Buffer
      "C-c C-p" #'beginning-of-buffer
      "C-c C-n" #'end-of-buffer

      ;; Quotes
      "C-'" #'oakho/toggle-quotes
      "C-\"" #'oakho/toggle-quotes

      ;; French Keyboards
      "M-L" "|"
      "M-n" "~"
      "M-/" "\\"
      "M-(" "{"
      "M-5" "["
      "M-)" "}"
      "M-°" "]"

      ;; Indentation
      "C-c C-a C-r" #'align-regexp
      "C-c C-a C-a" (lambda () (interactive)
		      (align-regexp (region-beginning) (region-end) "\\(\\s-*\\)=" 1 1 nil))
      "s-l" #'goto-line
      "<C-s-268632076>" #'spacemacs/toggle-line-numbers
      "<backtab>" #'oakho/unindent-region
      "C-a" #'oakho/smart-beginning-of-line
      "M-;" #'comment-or-uncomment-region

      "s-=" #'doom/increase-font-size
      "s--" #'doom/decrease-font-size
      "s-0" #'doom/reset-font-size
      "s-q" #'save-buffers-kill-terminal
      "s-v" #'yank
      "s-x" #'kill-region
      "s-c" #'kill-ring-save
      "s-a" #'mark-whole-buffer
      "s-w" #'delete-window
      "s-W" #'delete-frame
      "s-n" #'make-frame
      "s-s" (lambda () (interactive)
	      (call-interactively (key-binding "\C-x\C-s")))
      "s-Z" #'undo-fu-only-redo
      "C-@" #'er/expand-region
      "C-#" #'er/contract-region
      "s-d" #'mc/mark-next-like-this
      "s-D" #'mc/mark-previous-like-this
      "M-D" #'mc/mark-all-like-this)

(map! "C-x C-f" #'helm-find-files
      "C-x g" #'helm-mini
      "C-x C-b" #'helm-buffers-list
      "s-F" #'helm-do-ag-project-root
      "C-s-F" #'helm-do-ag
      "s-p" #'helm-browse-project)

(map! "C-à" #'centaur-tabs-forward
      "C-ç" #'centaur-tabs-backward)

(map! "C-c b c" #'string-inflection-all-cycle
      "C-c b n" #'string-inflection-camelcase
      "C-c b l" #'string-inflection-lower-camelcase
      "C-c b j" #'string-inflection-java-style-cycle)

;; (add-hook 'rjsx-mode-hook
;;           (lambda () (add-hook 'before-save-hook #'tide-organize-imports nil 'local)))

(setq lsp-enable-suggest-server-download nil)
;; (setq company-frontends '(company-pseudo-tooltip-frontend
;;                           company-echo-metadata-frontend))
;; seems to fix lsp company bug in hbs buffers

(with-eval-after-load 'lsp-mode
  (add-to-list 'lsp-language-id-configuration '("\\.hbs" . "html"))
  ;; (add-to-list 'lsp-language-id-configuration '("\\.hbs" . "els"))
  ;; (lsp-register-client (make-lsp-client :new-connection (lsp-stdio-connection (list "node" "--inspect-brk=9229" "/home/madnificent/code/javascript/ember-language-server/lib/start-server.js" "--stdio"))
  ;;                            :major-modes '(web-mode js2-mode)
  ;;                            :priority 5
  ;;                            :ignore-messages (list "Initializing Ember Language Server at .*$")
  ;;                            :add-on? t
  ;;                            :server-id 'els))

  (lsp-register-client
   (make-lsp-client :new-connection (lsp-stdio-connection (list "ember-language-server" "--stdio"))
		    :add-on? t
		    ;; :activation-fn (lsp-activate-on "html")
		    :server-id 'els)))

(setq web-mode-auto-close-style 2)

;; (set-email-account! "Oakho"
;;                     '((mu4e-sent-folder       . "/Perso/Sent Mail")
;;                       (mu4e-drafts-folder     . "/Perso/Drafts")
;;                       (mu4e-trash-folder      . "/Perso/Trash")
;;                       (mu4e-refile-folder     . "/Perso/All Mail")
;;                       (smtpmail-smtp-user     . "hello@antoinelagadec.com")
;;                       (user-mail-address      . "hello@antoinelagadec.com")    ;; only needed for mu < 1.4
;;                       (mu4e-compose-signature . "Antoine Lagadec"))
;;                     t)

;; (set-email-account! "IDOL"
;;                     '((mu4e-sent-folder       . "/IDOL/Sent Mail")
;;                       (mu4e-drafts-folder     . "/IDOL/Drafts")
;;                       (mu4e-trash-folder      . "/IDOL/Trash")
;;                       (mu4e-refile-folder     . "/IDOL/All Mail")
;;                       (smtpmail-smtp-user     . "antoine.lagadec@idol.io")
;;                       (user-mail-address      . "antoine.lagadec@idol.io")    ;; only needed for mu < 1.4
;;                       (mu4e-compose-signature . "Antoine Lagadec"))
;;                     t)

;; (setq +mu4e-gmail-accounts '(("hello@antoinelagadec.com" . "/Perso")
;;                              ("antoine.lagadec@idol.io" . "/IDOL")))

;; (after! mu4e
;;   (add-to-list 'mu4e-bookmarks
;;                '(:name "Inbox - Oakho"
;;                  :query "maildir:/Perso/INBOX"
;;                  :key ?o))

;;   (add-to-list 'mu4e-bookmarks
;;                '(:name "Inbox - IDOL"
;;                  :query "maildir:/IDOL/INBOX"
;;                  :key ?i))

;;   (add-to-list 'mu4e-header-info-custom
;;                '(:empty . (:name "Empty"
;;                            :shortname ""
;;                            :function (lambda (msg) "  "))))
;;   (setq mu4e-headers-fields '((:empty         .    2)
;;                               (:human-date    .   12)
;;                               (:flags         .    6)
;;                               (:mailing-list  .   10)
;;                               (:from          .   22)
;;                               (:subject       .   nil)))

;;   (setq mu4e-index-cleanup nil
;;         ;; because gmail uses labels as folders we can use lazy check since
;;         ;; messages don't really "move"
;;         mu4e-index-lazy-check t
;;         mu4e-update-interval 120
;;         mu4e-split-view 'horizontal
;;         sendmail-program (executable-find "msmtp")
;;         send-mail-function #'smtpmail-send-it
;;         message-sendmail-f-is-evil t
;;         message-sendmail-extra-arguments '("--read-envelope-from")
;;         message-send-mail-function #'message-send-mail-with-sendmail))
;; (setq mu4e-contexts
;;         `( ,(make-mu4e-context
;;              :name "Perso"
;;              :match-func (lambda (msg) (when msg (mu4e-message-contact-field-matches msg :to "hello@antoinelagadec.com")))
;;              :vars '((mu4e-maildir           . "~/.mail/Perso")
;;                      ;; (mu4e-trash-folder      . "/[Gmail].Bin")
;;                      ))
;;            ,(make-mu4e-context
;;              :name "IDOL"
;;              :match-func (lambda (msg) (when msg (mu4e-message-contact-field-matches msg :to "antoine.lagadec@idol.io")))
;;              :vars '((mu4e-maildir           . "~/.mail/IDOL")
;;                      ;; (mu4e-trash-folder      . "/[Gmail].Bin")
;;                      ))))

;; (setq mu4e-contexts
;;     `( ,(make-mu4e-context
;;           :name "Perso"
;;           :enter-func (lambda () (mu4e-message "Entering Private context"))
;;           :leave-func (lambda () (mu4e-message "Leaving Private context"))
;;           ;; we match based on the contact-fields of the message
;;           :match-func (lambda (msg)
;;                         (when msg
;;                           (string-match-p "^/Perso" (mu4e-message-field msg :maildir))))
;;           :vars '( ( user-mail-address	    . "hello@antoinelagadec.com"  )
;;                    ( user-full-name	    . "Antoine Lagadec" )
;;                    ( message-user-organization . "Homebase" )
;;                    ( mu4e-compose-signature .
;;                      (concat
;;                        "Antoine Lagadec")))
;;           )
;;        ,(make-mu4e-context
;;           :name "IDOL"
;;           :enter-func (lambda () (mu4e-message "Switch to the Work context"))
;;           ;; no leave-func
;;           ;; we match based on the maildir of the message
;;           ;; this matches maildir /Arkham and its sub-directories
;;           :match-func (lambda (msg)
;;                         (when msg
;;                           (string-match-p "^/IDOL" (mu4e-message-field msg :maildir))))
;;           :vars '( ( user-mail-address	     . "aderleth@miskatonic.example.com" )
;;                    ( user-full-name	     . "Antoine Lagadec" )
;;                    ( message-user-organization . "IDOL" )
;;                    ( mu4e-compose-signature  .
;;                      (concat
;;                        "Antoine Lagadec"))))))

;; (mu4e-alert-set-default-style 'notifier)

(use-package! indent-guide
  :hook ((prog-mode text-mode conf-mode) . indent-guide-mode))

;; (indent-guide-global-mode)

;; (use-package! copilot
;;   :hook (prog-mode . copilot-mode)
;;   :bind (:map copilot-completion-map
;;               ("<tab>" . 'copilot-accept-completion)
;;               ("TAB" . 'copilot-accept-completion)
;;               ("C-TAB" . 'copilot-accept-completion-by-word)
;;               ("C-<tab>" . 'copilot-accept-completion-by-word)))

;; (use-package! mu4e-folding
;;   :after mu4e
;;   :hook (mu4e-headers-found . mu4e-folding-mode))

;; (use-package! mu4e-column-faces
;;   :after mu4e
;;   :config (mu4e-column-faces-mode))

(setq lsp-html-format-indent-handlebars t)
(setq +format-with-lsp nil)
(setq standard-indent 2)

(use-package! company-lsp
  :config (push 'company-lsp company-backends))

(use-package lsp-tailwindcss
  :init
  (setq lsp-tailwindcss-add-on-mode t)
  ;; (add-hook 'before-save-hook 'lsp-tailwindcss-rustywind-before-save)
  )

;; (setq lsp-log-io t)
(setq lsp-server-trace "verbose")
(setq smerge-command-prefix "\C-cr")
(setq lsp-enable-symbol-highlighting nil)
(setq lsp-use-plists t)
(setq company-lsp-cache-candidates 'auto)
;; (setq company-lsp-enable-snippet t)
;; (setq company-lsp-enable-recompletion t)
;; (setq lsp-disabled-clients '(tailwindcss))

(add-hook 'dirvish-mode-hook
          (lambda ()
	    (centaur-tabs-local-mode)))

;; (setq-hook! 'web-mode-hook +format-with-lsp nil)
;; (setq-hook! 'web-mode-hook +format-with 'prettier)

;; see: https://github.com/doomemacs/doomemacs/issues/2068#issuecomment-713302955

(use-package! flycheck
  :config
  (setq-hook! 'web-mode-hook flycheck-checker 'ember-template)
  (flycheck-add-mode 'html-tidy 'web-mode))

(use-package! magit-todos
  :after magit
  :config
  (magit-todos-mode 1))

(use-package! apheleia
  :config
  (push '(prettier-ember-template-tag npx "prettier" "--stdin-filepath" filepath "--parser=ember-template-tag"
	  (apheleia-formatters-js-indent "--use-tabs" "--tab-width"))
	apheleia-formatters)
  (push '(ruby-syntax-tree . ("stree" "format" filepath
			      (apheleia-formatters-args-from-file ".streerc"))) apheleia-formatters)

  (defun apheleia-formatters-args-from-file (file-name)
    "Extract arguments from a text file.
Look for a file up recursively from the current directory until FILE-NAME is
found. If found, read the file and return an Alist of lines in the file."
    (when-let ((file (locate-dominating-file default-directory file-name)))
      (with-temp-buffer
	(insert-file-contents (concat (expand-file-name file) file-name))
	(cl-loop for line in (split-string (buffer-string) "\n" t)
		 collect line))))

  (add-hook 'ruby-mode-hook
	    (lambda ()
	      (setq apheleia-formatter 'ruby-syntax-tree)))

  (add-hook 'typescript-ts-mode-hook
	    (lambda ()
	      (when (and (stringp buffer-file-name)
			 (string-match "\\.gts\\'" buffer-file-name))
		(setq apheleia-formatter 'prettier-ember-template-tag))))

  (setq apheleia-log-only-errors nil))

(add-to-list 'apheleia-formatters
             '(prettier-ember-template-tag npx "prettier" "--stdin-filepath" filepath "--parser=ember-template-tag"
	       (apheleia-formatters-js-indent "--use-tabs" "--tab-width")))

;; Enable web-mode inside <template> tags in TypeScript files
(use-package! mmm-mode
  :config
  (setq mmm-global-mode 'maybe)
  (mmm-add-classes
   '((typescript-web-template
      :submode web-mode
      :front "<template>"
      :back "</template>"
      :include-front t
      :include-back t
      :inherit-submode t)))
  (mmm-add-mode-ext-class 'typescript-mode nil 'typescript-web-template)
  ;; (mmm-add-classes '((html-ts-handlebars :submode html-ts-mode :front "<template>" :back "</template>")))
  ;; (mmm-add-mode-ext-class 'typescript-ts-mode "\\.gts\\'" 'html-ts-handlebars)
  )

(add-to-list 'auto-mode-alist '("\\.gts\\'" . typescript-mode))
(add-to-list 'auto-mode-alist '("\\.gjs\\'" . rjsx-mode))

(setq treesit-language-source-alist
      '((bash "https://github.com/tree-sitter/tree-sitter-bash")
	(cmake "https://github.com/uyha/tree-sitter-cmake")
	(css "https://github.com/tree-sitter/tree-sitter-css")
	(elisp "https://github.com/Wilfred/tree-sitter-elisp")
	(go "https://github.com/tree-sitter/tree-sitter-go")
	(html "https://github.com/tree-sitter/tree-sitter-html")
	(javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
	(json "https://github.com/tree-sitter/tree-sitter-json")
	(make "https://github.com/alemuller/tree-sitter-make")
	(markdown "https://github.com/ikatyang/tree-sitter-markdown")
	(python "https://github.com/tree-sitter/tree-sitter-python")
	(toml "https://github.com/tree-sitter/tree-sitter-toml")
	(tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
	(typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
	(yaml "https://github.com/ikatyang/tree-sitter-yaml")))

;; (mapc #'treesit-install-language-grammar (mapcar #'car treesit-language-source-alist))

;; (setq lsp-html-format-enable nil)
;; (setq lsp-typescript-format-enable nil)
;; (setq lsp-eslint-format nil)
;; (setq lsp-log-io t)

(require 'json)
(require 'url)

(defun fetch-openrouter-models ()
  (with-current-buffer
      (url-retrieve-synchronously "https://openrouter.ai/api/v1/models")
    (goto-char url-http-end-of-headers)
    (let* ((json-object-type 'alist)
           (json-data (json-read))
           (models (alist-get 'data json-data)))
      (mapcar (lambda (model)
                (cons (alist-get 'name model)
                      (alist-get 'id model)))
              models))))

(use-package! gptel
  :config
  (add-hook 'gptel-post-stream-hook 'gptel-auto-scroll)
  (add-hook 'gptel-post-response-functions 'gptel-end-of-response)

  (setq gptel-model  'gpt-4o
        gptel-backend (gptel-make-openai "Copilot" ;Any name you want
                        :host "models.inference.ai.azure.com"
                        :endpoint "/chat/completions?api-version=2024-05-01-preview"
                        :stream t
                        :key (gptel-api-key-from-auth-source "models.inference.ai.azure.com" "oakho^copilot")
                        :models '(gpt-4o)))

  (gptel-make-openai "OpenRouter"               ;Any name you want
    :host "openrouter.ai"
    :endpoint "/api/v1/chat/completions"
    :stream t
    :key (gptel-api-key-from-auth-source "openrouter.ai" "oakho")                   ;can be a function that returns the key
    ;; :models '(deepseek/deepseek-r1:free
    ;;           deepseek/deepseek-r1
    ;;           deepseek/deepseek-chat:free
    ;;           google/gemini-2.0-flash-001
    ;;           anthropic/claude-3.5-sonnet
    ;;           mistralai/mistral-7b-instruct-v0.1
    ;;           openai/gpt-4o-mini))
    :models (mapcar (lambda (model)
                      (cdr model))
                    (fetch-openrouter-models))))

(use-package! gptel-quick)

(use-package! smerge-mode
  :ensure nil
  :hook
  (prog-mode . smerge-mode))

(use-package! aider
  :config
  (setq aider-args '())
  (setq aider-popular-models
        (append aider-popular-models
                (mapcar (lambda (model)
                          (concat "openrouter/" (cdr model)))
                        (fetch-openrouter-models)))))

(defun gptel-cycle-backends ()
  "Cycle through available `gptel--known-backends`, updating `gptel-backend` to the backend object."
  (interactive)
  (when (and (boundp 'gptel--known-backends)
             (listp gptel--known-backends))
    (let* ((current-backend (or gptel-backend (cdar gptel--known-backends))) ; Get the current backend or the first one.
           (index (or (cl-position current-backend
                                   (mapcar #'cdr gptel--known-backends)) ; Get the position of the current backend.
                      -1))
           (next-index (mod (1+ index) (length gptel--known-backends)))
           (next-backend-item (nth next-index gptel--known-backends)))
      (setq gptel-backend (cdr next-backend-item)) ; Update `gptel-backend` to the next backend.
      (message "Switched to backend: %s" (car next-backend-item))))) ; Display the name of the backend.

(global-set-key (kbd "C-c g b") #'gptel-cycle-backends)
