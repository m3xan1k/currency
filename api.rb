require './base.rb'
require 'sinatra'


db = init_db


get '/' do
  format_response(fetch_todays_course(db)).to_s + '\n'
end
