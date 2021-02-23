require './base.rb'
require 'sinatra'


db = init_db


get '/' do
  format_response(fetch_todays_values(db))
end


get '/codes' do
  format_response(fetch_codes_and_names(db), fields = [:code, :name])
end


get '/codes/:code' do
  code = params[:code].upcase
  format_response(fetch_todays_value_by_code(db, code))
end


get '/dates/:date' do
  date = params[:date]
  format_response(fetch_values_by_date(db, date), fields = [:code, :name, :value, :date])
end
