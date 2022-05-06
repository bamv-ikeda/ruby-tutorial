# 概要

ruby学習用リポジトリ

# ruby version

2.6.5

# 環境構築

rubyのインストール手順は省略

```sh
bundle install
```

## MySQLインストール

```sh
brew install mysql
```

# 起動

- MySQL起動

```sh
mysql.server start
```

最初はDBがないので、ユーザー：root、パスワード：(空)でアクセスし、ddl.sqlのSQLを実行し、DB・テーブルを作成する。
※学習用であり、ローカル実行しかしないためrootユーザーのままでOK

- sinatra起動

```sh
bundle exec ruby app.rb
```

`http://localhost:4567/` へアクセス
