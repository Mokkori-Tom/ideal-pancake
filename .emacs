(require 'package)

;; HTTP 系のリポジトリの設定
(setq package-archives
      '(("marmalade" . "http://marmalade-repo.org/packages/")
        ("melpa" . "https://melpa.org/packages/")
        ("melpa-stable" . "http://stable.melpa.org/packages/")))

(package-initialize)

;; use-packageのインストール
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)  ;; use-packageで指定したパッケージは自動的にインストール

;; 必要なパッケージを自動でインストールする関数
(defun ensure-packages (packages)
  "Ensure that the specified PACKAGES are installed."
  (dolist (package packages)
    (unless (package-installed-p package)
      (package-refresh-contents)
      (package-install package))))

;; 必要なパッケージのリスト
(ensure-packages
 '(use-package
   evil
   org
   org-download
   company
   flycheck
   eglot
   zenburn-theme
   ;; 他に必要なパッケージをここに追加
   ))

;; 文字サイズの設定
(set-face-attribute 'default nil :family "Menlo" :height 150)

;; フレームの透明度設定
(set-frame-parameter nil 'alpha '(90 . 90))
(add-to-list 'default-frame-alist '(alpha . (90 . 90)))

;; テーマの設定
(load-theme 'zenburn t)

;; evilモードの設定
(use-package evil
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil)
  :config
  (evil-mode 1)
  (evil-define-key 'normal 'global (kbd "C-p") 'previous-line)
  (evil-define-key 'normal 'global (kbd "C-n") 'next-line)
  
  ;; 行を挿入する際に入力モードに入らないようにする関数
  (defun my/evil-open-below-no-insert ()
    "Insert a new line below without entering insert mode."
    (interactive)
    (evil-open-below 1)
    (evil-normal-state))
  
  (define-key evil-normal-state-map (kbd "o") 'my/evil-open-below-no-insert)

  (defun my/evil-open-above-no-insert ()
    "Insert a new line above without entering insert mode."
    (interactive)
    (evil-open-above 1)
    (evil-normal-state))
  
  (define-key evil-normal-state-map (kbd "O") 'my/evil-open-above-no-insert))

;; eglotの設定
(use-package eglot
  :config
  (add-hook 'go-mode-hook 'eglot-ensure)  ;; Goモードでeglotを有効にする

  ;; 他の言語モードでもeglotを有効にする場合は、以下のように追加
  ;; (add-hook 'python-mode-hook 'eglot-ensure)
  ;; (add-hook 'javascript-mode-hook 'eglot-ensure)
)

;; eshell設定
(use-package eshell
  :config
  (setq eshell-history-size 1000
        eshell-buffer-maximum-lines 1000
        eshell-hist-ignoredups t)

  ;; シンタックスハイライト
  (add-hook 'eshell-mode-hook
            (lambda ()
              (eshell-syntax-highlighting-mode 1)
              (goto-address-mode 1)
              (setq eshell-completion-ignore-case t
                    eshell-completion-show-help t
                    eshell-completion-replace-by-expanded-insert nil)))

  ;; Eshellのプロンプトをカスタマイズ
  (setq eshell-prompt-function
        (lambda ()
          (concat
           (propertize (user-login-name) 'face '(:foreground "green")) "@"
           (propertize (system-name) 'face '(:foreground "green")) ": "
           (propertize (eshell/pwd) 'face '(:foreground "cyan")) " $ ")))
  (setq eshell-highlight-prompt nil)

  ;; エイリアスの設定
  (setq eshell-command-aliases-list '(("ll" "ls -l") ("gs" "git status") ("e" "find-file \\$1"))))

;; Eshellのカスタム関数
(defun eshell/go-to-project ()
  (interactive)
  (eshell/cd "/path/to/your/project"))  ;; プロジェクトディレクトリに移動

;; 環境変数の設定
(when (file-exists-p "~/shellenv.el")
  (load-file (expand-file-name "~/shellenv.el"))
  (dolist (path (reverse (split-string (getenv "PATH") ":")))
    (add-to-list 'exec-path path)))

;; org-mode設定
(use-package org
  :config
  (define-key global-map "\C-cl" 'org-store-link)
  (define-key global-map "\C-ca" 'org-agenda)
  (setq org-log-done t
        org-startup-with-inline-images t))

(use-package org-download
  :config
  (setq org-download-screenshot-method "xclip -selection clipboard -t image/png -o > %s"))

(add-hook 'org-mode-hook
          (lambda ()
            (add-hook 'after-save-hook
                      (lambda ()
                        (when (eq major-mode 'org-mode)
                          (org-html-export-to-html))))))
