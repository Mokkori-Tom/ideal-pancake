; write-csv.lisp
; ライブラリごとコピーする
; 例えば
; ./  
; ├── quicklisp/  
; └── write-csv.lisp

; 実行方法
; 開発中は --load 対話環境を起動
; sbcl --load write-csv.lisp
; 配布後は --script 実行して即終了
; sbcl --script write-csv.lisp

; 外部更新を禁止の場合（オフライン前提）
; (setf ql:*update-dist* nil)         
; ローカル quicklisp を使用
(load "./quicklisp/setup.lisp")     
; 必要ライブラリをロード
(ql:quickload :cl-csv)              
; 以降にスクリプトを書く 
 