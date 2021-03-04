require 'sequel'
require 'terminal-table'
require 'time'
require 'active_support/time'
require 'pry'

LOGO = "
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░██░█░█░██░█░█░███░██░░█░███░██░███░░░░
░░█░░█░█░█░░█░█░█░█░███░█░█░░░█░░█░█░░░░
░░██░░█░░█░░███░███░█░███░█░░░██░███░░░░
░░█░░█░█░█░░█░█░█░█░█░░██░█░█░█░░██░░░░░
░░██░█░█░██░█░█░█░█░█░░██░███░██░█░█░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
".freeze

NEW_LINE = '
'.freeze

# def fetch_codes_and_names(db)
#   db[:currencies].all
# end

# def fetch_todays_rate_by_code(db, code: nil)
#   # fetch by code from db, calculate diff
#   # returns array to have single interface for formatting output
#   table = db[:currencies]
#   date = Date.today.to_s
#   where = { date: date, code: code }
#   today_currency = table
#                    .select(:code, :name, :rate)
#                    .join(:rates, currency_id: :id)
#                    .where(where).first
#   diff = calculate_daily_rate_diff(db, code: code)
#   today_currency[:diff] = diff unless diff.nil?
#   [today_currency]
# end

# def fetch_rates_by_date(db, date: Date.today.to_s)
#   table = db[:currencies]
#   date = Date.parse(date)
#   table.select(:code, :name, :rate, :date).join(:rates, currency_id: :id).where(date: date)
# end

def format_response(data, fields: [])
  # extract rates corresponding to fields
  rows = data.map do |row|
    row['date'] = row['date'].to_s if fields.include?('date')
    row['rate'] = row['rate'].to_f.round(2) if fields.include?('rate')

    # if row data not unified with fields
    begin
      row.fetch_rates(*fields)
    rescue KeyError
      fields = %w[code name rate]
      row.fetch_rates(*fields)
    end
  end

  # set headings and draw table
  headings = fields
  table = Terminal::Table.new headings: headings, rows: rows
  table.style = { all_separators: true }

  "#{LOGO}#{NEW_LINE}#{table}#{NEW_LINE}#{Time.now}#{NEW_LINE}"
end
