(menu-bar-mode -1)

(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))  ;; 必要なら

(package-initialize)
(unless package-archive-contents (package-refresh-contents))
(unless (package-installed-p 'evil)
  (package-install 'evil))
(require 'evil)
(evil-mode 1)

(custom-set-variables
 '(package-selected-packages
   '(buffer-terminator cape corfu-terminal ddskk evil-surround magit
                       treemacs treesit-auto undo-tree vim-tab-bar)))
(custom-set-faces)

(use-package corfu
  :ensure t
  :commands (corfu-mode global-corfu-mode)
  :hook ((prog-mode . corfu-mode)
         (shell-mode . corfu-mode)
         (eshell-mode . corfu-mode))
  :custom
  (read-extended-command-predicate #'command-completion-default-include-p)
  (text-mode-ispell-word-completion nil)
  (tab-always-indent 'complete)
  (corfu-auto t)
  :config
  (global-corfu-mode))

(use-package cape
  :ensure t
  :commands (cape-dabbrev cape-file cape-elisp-block)
  :bind ("C-c p" . cape-prefix-map)
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block))

(use-package corfu-terminal
  :ensure t
  :after corfu
  :commands (corfu-terminal-mode)
  :bind ("C-c t" . corfu-terminal-mode)
  :init
  (unless (display-graphic-p)
    (corfu-terminal-mode +1)))

(mapc #'disable-theme custom-enabled-themes)
(load-theme 'modus-vivendi t)

(use-package vim-tab-bar
  :ensure t
  :commands vim-tab-bar-mode
  :hook (after-init . vim-tab-bar-mode))

(use-package evil-surround
  :after evil
  :ensure t
  :commands global-evil-surround-mode
  :custom
  (evil-surround-pairs-alist
   '((?\( . ("(" . ")"))
     (?\[ . ("[" . "]"))
     (?\{ . ("{" . "}"))
     (?\) . ("(" . ")"))
     (?\] . ("[" . "]"))
     (?\} . ("{" . "}"))
     (?< . ("<" . ">"))
     (?> . ("<" . ">"))))
  :hook (after-init . global-evil-surround-mode))

(use-package magit
  :ensure t
  :commands (magit-status)
  :config ("C-x g" . magit-status))

(use-package undo-tree
  :ensure t
  :commands (magit-status)
  :config (global-undo-tree-mode))

(use-package treesit-auto
  :ensure t
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

(use-package eglot
  :ensure t
  :commands (eglot-ensure eglot-rename eglot-format-buffer))

(add-hook 'python-mode-hook #'eglot-ensure)
(add-hook 'python-ts-mode-hook #'eglot-ensure)
(setq-default eglot-workspace-configuration
              `(:pylsp (:plugins
                        (:isort (:enabled t)
                         :autopep8 (:enabled t)
                         :pylint (:enabled t)
                         :pycodestyle (:enabled t)
                         :flake8 (:enabled t)
                         :pyflakes (:enabled t)
                         :pydocstyle (:enabled t)
                         :mccabe (:enabled t)
                         :yapf (:enabled :json-false)
                         :rope_autoimport (:enabled :json-false)))))

(setq inferior-lisp-program "sbcl")
(setq slime-contribs '(slime-fancy))
(load (expand-file-name "~/quicklisp/slime-helper.el"))

(use-package markdown-mode
  :commands (gfm-mode gfm-view-mode markdown-mode markdown-view-mode)
  :mode (("\\.markdown\\'" . markdown-mode)
         ("\\.md\\'" . markdown-mode)
         ("README\\.md\\'" . gfm-mode))
  :bind
  (:map markdown-mode-map
        ("C-c C-e" . markdown-do)))

(with-eval-after-load "evil"
  (evil-define-operator my-evil-comment-or-uncomment (beg end)
    "Toggle comment for the region between BEG and END."
    (interactive "<r>")
    (comment-or-uncomment-region beg end))
  (evil-define-key 'normal 'global (kbd "gc") 'my-evil-comment-or-uncomment))

(use-package buffer-terminator
  :ensure t
  :custom
  (buffer-terminator-verbose nil)
  (buffer-terminator-inactivity-timeout (* 30 60))
  (buffer-terminator-interval (* 10 60))
  :config
  (buffer-terminator-mode 1))

(use-package treemacs
  :ensure t
  :commands (treemacs treemacs-select-window treemacs-delete-other-windows
                      treemacs-select-directory treemacs-bookmark
                      treemacs-find-file treemacs-find-tag)
  :bind
  (:map global-map
        ("M-0"       . treemacs-select-window)
        ("C-x t 1"   . treemacs-delete-other-windows)
        ("C-x t t"   . treemacs)
        ("C-x t d"   . treemacs-select-directory)
        ("C-x t B"   . treemacs-bookmark)
        ("C-x t C-t" . treemacs-find-file)
        ("C-x t M-t" . treemacs-find-tag))
  :init
  (with-eval-after-load 'winum
    (define-key winum-keymap (kbd "M-0") #'treemacs-select-window))
  :config
  (setq treemacs-collapse-dirs                   (if treemacs-python-executable 3 0)
        treemacs-display-in-side-window          t
        treemacs-follow-after-init               t
        treemacs-expand-after-init               t
        treemacs-hide-dot-git-directory          t
        treemacs-indentation                     2
        treemacs-show-hidden-files               t
        treemacs-width                           35
        treemacs-workspace-switch-cleanup        nil)
  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-fringe-indicator-mode 'always)
  (pcase (cons (not (null (executable-find "git")))
               (not (null treemacs-python-executable)))
    (`(t . t) (treemacs-git-mode 'deferred))
    (`(t . _) (treemacs-git-mode 'simple)))
  (treemacs-hide-gitignored-files-mode nil))

(use-package ddskk
  :init
  (setq skk-user-directory "~/.emacs.d/skk/")
  (setq skk-jisyo "~/.emacs.d/skk/SKK-JISYO.L")
  :bind
  (("C-x j" . skk-mode))) ; トグル起動キー

;; バックアップファイルを作成しない
(setq make-backup-files nil)      ;; ~で終わるバックアップを作らない
(setq auto-save-default nil)      ;; #で囲まれた自動保存ファイルを作らない
(setq create-lockfiles nil)       ;; .#ロックファイルを作らない