-- DBを作成
CREATE DATABASE ruby_tutorial;

-- テーブルを作成
USE ruby_tutorial;
CREATE TABLE zip_codes (
  id INT NOT NULL AUTO_INCREMENT COMMENT '郵便番号ID',
  zip_code INT UNIQUE NOT NULL COMMENT '郵便番号',
  prefecture VARCHAR(255) NOT NULL COMMENT '都道府県名',
  city VARCHAR(255) NOT NULL COMMENT '市区町村名',
  town_area VARCHAR(255) NOT NULL COMMENT '町域名',
  created_at DATETIME NOT NULL COMMENT '作成日時',
  updated_at DATETIME NOT NULL COMMENT '更新日時',
  PRIMARY KEY (id)
)
COMMENT '郵便番号';

-- テーブルを削除
-- DROP TABLE zip_codes;
