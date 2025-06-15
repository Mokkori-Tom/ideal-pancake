(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

(setq warning-suppress-types '((obsolete)))

;; ddskk(input)
(use-package ddskk
  :ensure t)

(global-set-key (kbd "C-x j") 'skk-auto-fill-mode)

;; SLIME（Common Lisp）
(use-package slime
  :init
  (setq inferior-lisp-program "sbcl")
  :config
  (slime-setup '(slime-fancy)))

;; jupyter.el（org-babel用）
(use-package jupyter
  :defer t)

;; Org-mode
(use-package org
  :mode ("\\.org\\'" . org-mode)
  :hook ((org-mode . visual-line-mode)
         (org-mode . variable-pitch-mode))
  :custom
  (org-hide-emphasis-markers t)
  (org-startup-indented t)
  (org-startup-folded 'content)
  (org-ellipsis " ▾")
  :config
  ;; Org-Babel 言語設定
  (org-babel-do-load-languages

   'org-babel-load-languages
   '((emacs-lisp . t)
     (julia      . t)
     (python     . t)
     (jupyter    . t))))

;; which-key：キーバインド補助
(use-package which-key
  :config
  (which-key-mode)
  :custom
  (which-key-idle-delay 0.3))

;; magit：Git フロントエンド
(use-package magit
  :commands magit-status)

;; company：補完機能
(use-package company
  :hook (after-init . global-company-mode)
  :custom
  (company-idle-delay 0.2)
  (company-minimum-prefix-length 1))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               `((python-mode) . ("~/myenv/Scripts/pylsp.exe"))))

;; projectile：プロジェクト管理
(use-package projectile
  :init
  (projectile-mode +1)
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :custom
  (projectile-completion-system 'default))

;; Ivy/Counsel：補完UI
(use-package ivy
  :init (ivy-mode 1)
  :custom
  (ivy-use-virtual-buffers t)
  (enable-recursive-minibuffers t))

(use-package counsel
  :after ivy
  :config (counsel-mode 1))

;; Consult：高機能UI
(use-package consult
  :bind
  (("C-s" . consult-line)
   ("C-x b" . consult-buffer)))

;; LSPクライアント（軽量な eglot）
(use-package eglot
  :hook ((python-mode . eglot-ensure)
         (julia-mode . eglot-ensure)
         (c-mode . eglot-ensure)
         (c++-mode . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs
               '(julia-mode . ("julia" "--startup-file=no" "--history-file=no"
                               "-e" "using LanguageServer; runserver()"))))

(use-package emacs
  :init
  (context-menu-mode 1)
  (global-tab-line-mode 1)
  (setq display-line-numbers-type 'relative)      ;; ★ ここだけは setq で変数へ
  (global-display-line-numbers-mode)
  (display-battery-mode 1)
  (display-time-mode 1)
  (when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
  (when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
  (when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
  :custom
  (current-language-environment "UTF-8"))

;; UI と表示設定
;; (use-package emacs
;;   :init
;;   (context-menu-mode 1)
;;   (global-tab-line-mode 1)
;;   :custom
;;   (current-language-environment "UTF-8")
;;   (display-battery-mode t)
;;   (display-time-mode t)
;;   (display-line-numbers-type 'relative)
;;   (scroll-bar-mode nil))

(when (fboundp 'menu-bar-mode) (menu-bar-mode -1))

;; フォント設定（custom-set-faces のままでもOK）
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "HackGen Console NF" :foundry "outline" :slant normal :weight regular :height 120 :width normal)))))

;; auto-save（手動インストールした外部パッケージ）
(add-to-list 'load-path "~/.emacs.d/site-lisp/auto-save") ;; 適宜パス変更
(require 'auto-save)
(auto-save-enable)

(setq auto-save-silent t)   ;; 静かに保存
(setq auto-save-delete-trailing-whitespace t) ;; 保存時に行末の空白削除

;; 特定条件で auto-save を無効化（例：GPGファイル）
(setq auto-save-disable-predicates
      '((lambda ()
          (string-suffix-p
           "gpg"
           (file-name-extension (buffer-name)) t))))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))

(add-to-list 'load-path "~/.emacs.d/lisp/")
;;(require 'psc)
