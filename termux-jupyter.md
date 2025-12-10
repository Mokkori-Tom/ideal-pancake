---

1. 必要パッケージのインストール

まずは Termux 側でビルド環境をそろえます。
```
pkg update
pkg upgrade

pkg install python build-essential libffi libzmq clang make cmake binutils pkg-config rust
```

---

2. Jupyter（旧バージョン）のインストール

rpds-py 問題を避けるため、「一世代前の安定版」に固定します。
```
pip install --upgrade pip setuptools wheel

pip install \
  "jsonschema<4.18" \
  "jupyterlab<4" \
  "notebook<7"
```
インストール済みの状態は、今だとだいたいこんな感じになっています。

jsonschema==4.17.3

jupyterlab==3.6.7

notebook==6.5.7


この組み合わせは Termux でも比較的安定です。


---

3. 起動方法（毎回使うコマンド）

基本はこのどちらかです。

Notebook
```
jupyter notebook --ip=0.0.0.0 --no-browser
```
JupyterLab
```
jupyter-lab --ip=0.0.0.0 --no-browser
```
出てきた URL をブラウザにコピペして使います。


---

4. トークンを自分で決める設定

4-1. 設定ファイルを作成

一度だけ、設定ファイルを生成します。
```
jupyter notebook --generate-config
```
~/.jupyter/jupyter_notebook_config.py ができます。

4-2. トークンを固定する

エディタで開きます。
```
vim ~/.jupyter/jupyter_notebook_config.py
```
中に次の行を追加（またはコメントアウトを外して書き換え）します。
```
c.NotebookApp.token = 'my-secret-token-123'
```
お好きな文字列に変えてくださいね。

保存したら、あとはいつも通り：
```
jupyter notebook --ip=0.0.0.0 --no-browser
```
または
```
jupyter-lab --ip=0.0.0.0 --no-browser
```
ブラウザからは
```
http://127.0.0.1:8888/?token=my-secret-token-123
```
のようにアクセスできます。

おまけ。
起動時トークン指定
```
jupyter notebook --ip=0.0.0.0 --no-browser --NotebookApp.token='my-token'
```

```
jupyter lab --ip=0.0.0.0 --no-browser --ServerApp.token='my-token'
```
---

5. 将来のためのメモ（お好みで）

今の環境を再現しやすくするなら、一度だけ：
```
pip freeze > requirements.txt
```
としておくと、環境を作り直したいときに
```
pip install -r requirements.txt
```
でほぼ同じ状態まで戻せます。