require './formatter'
require './db'
require 'sinatra'

get '/' do
  @currencies = fetch_todays_rates_with_diff
  if request.env['HTTP_USER_AGENT'].start_with?('curl')
    format_response(@currencies, fields: %w[code name rate diff])
  else
    erb(:index, { layout: :base, currencies: @currencies })
  end
end

get '/codes/?' do
  @currencies = fetch_codes_and_names
  if request.env['HTTP_USER_AGENT'].start_with?('curl')
    format_response(@currencies, fields: %w[code name])
  else
    erb(:index, { layout: :base, currencies: @currencies })
  end
end

get '/codes/:code/?' do
  code = params[:code].upcase
  @currencies = fetch_todays_rate_by_code(code: code)
  if request.env['HTTP_USER_AGENT'].start_with?('curl')
    @currencies.nil? ? format_404 : format_response([@currencies], fields: %w[code name rate diff])
  else
    if @currencies.nil?
      erb(:not_found, { layout: :base })
    else
      @currencies = [@currencies]
      erb(:index, { layout: :base, currencies: @currencies })
    end
  end
end

get '/dates/:date/?' do
  date = params[:date]
  @currencies = fetch_rates_by_date(date: date)
  if @currencies.nil?
    return erb(:not_found, { layout: :base })
  end

  format_response(@currencies, fields: [:code, :name, :rate, :date])
end

not_found do
  status 404
  erb(:not_found, { layout: :base })
end
