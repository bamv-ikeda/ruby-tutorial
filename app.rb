# frozen_string_literal: true

require 'bundler/setup'
require 'sinatra'
require 'json'
require 'mysql2'
require 'net/http'
require 'uri'

MYSQL_HOST = 'localhost'
MYSQL_PASS = ''
MYSQL_USER = 'root'
MYSQL_DATABASE = 'ruby_tutorial'
MYSQL_ENCODING = 'utf8'

# 郵便番号検索API(外部APIのURL)
ZIP_CLOUD_URL = 'https://zipcloud.ibsnet.co.jp/api/search'

before do
  @client = Mysql2::Client.new(
    host: MYSQL_HOST,
    password: MYSQL_PASS,
    username: MYSQL_USER,
    database: MYSQL_DATABASE,
    encoding: MYSQL_ENCODING
  )
  @results = []
end

# 画面表示(http://localhost:4567)
get '/' do
  @zip_codes = select_zip_codes
  erb :index
end

# 検索
post '/' do
  zip_code = params['zip_code']
  json = request_api(zip_code)
  response = JSON.parse(json, symbolize_names: true)

  @results = response[:results] || []
  puts @results
  if @results.empty?
    # 郵便番号検索APIエラー時
    @message = response[:message] || '指定した郵便番号は存在しません'
  else
    @results.each do |result|
      puts result
      zip_code = select_by_zip_code(result[:zipcode])
      if zip_code.nil?
        insert_zip_code(result[:zipcode], result[:address1], result[:address2], result[:address3])
      else
        update_zip_code(zip_code[:id], result[:zipcode], result[:address1], result[:address2], result[:address3])
      end
    end
  end

  @zip_codes = select_zip_codes
  erb :index
end

# 取得API(全件取得)
get '/zip_codes' do
  select_zip_codes.to_json
end

# 取得API(id指定)
get '/zip_codes/:id' do
  select_by_id.to_json
end

# 登録API
post '/zip_codes' do
  body = request.body.read

  if body == ''
    status 400
    return error_code('no body')
  end

  hash = JSON.parse(body, symbolize_names: true)
  zip_code = hash[:zip_code]
  prefecture = hash[:prefecture]
  city = hash[:city]
  town_area = hash[:town_area]

  if zip_code.nil? || prefecture.nil? || city.nil? || town_area.nil?
    status 400
    return error_code('invalid paramater')
  end

  begin
    insert_zip_code(zip_code, prefecture, city, town_area)
  rescue Mysql2::Error
    status 400
    return error_code('mysql error')
  end

  status 201
end

# 更新API
put '/zip_codes/:id' do
  body = request.body.read
  id = params[:id].to_i

  # パスパラメータ不正
  if id.zero?
    status 400
    return error_code('invalid path parameter')
  end

  # bodyなし
  if body == ''
    status 400
    return error_code('no body')
  end

  # bodyのパース
  hash = JSON.parse(body, symbolize_names: true)
  zip_code = hash[:zip_code]
  prefecture = hash[:prefecture]
  city = hash[:city]
  town_area = hash[:town_area]

  # パラメータ不正
  if zip_code.nil? || prefecture.nil? || city.nil? || town_area.nil?
    status 400
    return error_code('invalid paramater')
  end

  begin
    update_zip_code(id, zip_code, prefecture, city, town_area)
  rescue Mysql2::Error
    status 400
    return error_code('mysql error')
  end

  status 200
end

# 削除API
delete '/zip_codes/:id' do
  id = params[:id].to_i
  if id.zero?
    status 400
    return error_code('invalid path parameter')
  end

  begin
    delete_zip_code(id)
  rescue Mysql2::Error
    status 400
    return error_code('mysql error')
  end

  status 200
end

def query(sql)
  puts sql
  @client.query(sql, symbolize_keys: true)
end

def error_code(message)
  { 'error': message }.to_json
end

def select_zip_codes
  query('SELECT * FROM zip_codes')
end

def select_by_id(id)
  query("SELECT * FROM zip_codes WHERE id = #{id}").first
end

def select_by_zip_code(zip_code)
  query("SELECT * FROM zip_codes WHERE zip_code = #{zip_code}").first
end

def insert_zip_code(zip_code, prefecture, city, town_area)
  now = Time.now.strftime('%F %T')
  sql = <<~SQL
    INSERT INTO zip_codes (zip_code, prefecture, city, town_area, created_at, updated_at)
    VALUES (#{zip_code}, '#{prefecture}', '#{city}', '#{town_area}', '#{now}', '#{now}')
  SQL
  query(sql)
end

def update_zip_code(id, zip_code, prefecture, city, town_area)
  now = Time.now.strftime('%F %T')
  query <<~SQL
    UPDATE zip_codes
    SET zip_code = #{zip_code}
      , prefecture = '#{prefecture}'
      , city = '#{city}'
      , town_area = '#{town_area}'
      , updated_at = '#{now}'
    WHERE id = #{id}
  SQL
end

def delete_zip_code(id)
  query("DELETE FROM zip_codes WHERE id = #{id}")
end

def request_api(zip_code)
  uri = URI.parse("#{ZIP_CLOUD_URL}?zipcode=#{zip_code}")
  response = Net::HTTP.get_response(uri)
  response.body
end
