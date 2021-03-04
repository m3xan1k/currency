require './formatter'
require './db'
require 'sinatra'

get '/' do
  format_response(fetch_todays_rates_with_diff, fields: [:code, :name, :rate, :diff])
end

get '/codes' do
  # format_response(fetch_codes_and_names(db), fields: [:code, :name])
end

get '/codes/:code' do
  # code = params[:code].upcase
  # format_response(fetch_todays_rate_by_code(db, code: code), fields: [:code, :name, :rate, :diff])
end

get '/dates/:date' do
  # date = params[:date]
  # format_response(fetch_rates_by_date(db, date: date), fields: [:code, :name, :rate, :date])
end
