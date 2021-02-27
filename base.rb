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

def init_db
  # create db and tables if not exist
  db = Sequel.sqlite('test.db')

  unless db.table_exists?(:currencies)
    db.create_table :currencies do
      primary_key :id

      column :code, String
      column :name, String
    end
  end

  unless db.table_exists?(:values)
    db.create_table :values do
      primary_key :id

      column :value, BigDecimal
      Date :date, default: Date.today, index: true

      foreign_key :currency_id, :currencies
    end
  end

  return db
end

def save_to_db(db, data: nil)
  currencies_table = db[:currencies]
  values_table = db[:values]

  # pre-fill currencies table if empty
  if currencies_table.empty?
    currencies_table.multi_insert(data.map { |row| row.slice(:code, :name) })
  end

  # Match values with currency ids and bulk save to db
  values = []
  currencies_table.all.each do |currency|
    value = data.filter { |row| row[:code] == currency[:code] }.first.slice(:value, :date)
    value[:currency_id] = currency[:id]
    values.push(value)
  end
  values_table.multi_insert(values)

  currencies_table.select(:code, :name, :value, :date).join(:values, id: :id)
end

def fetch_todays_values(db)
  # get all currencies with values, calcultate diffs
  today = Date.today
  table = db[:currencies]
  today_currencies = table.join(:values, currency_id: :id).where(date: today).all
  diffs = calculate_daily_rate_diff(db)

  # return dataset without diffs if diffs empty
  return today_currencies if diffs.empty?

  # match and bundle diffs with currencies by currency_id
  today_currencies_with_diff = []
  diffs.each do |diff|
    today_currencies.each do |curr|
      if curr[:id] == diff[:currency_id]
        curr[:diff] = diff[:diff]
        today_currencies_with_diff.push(curr)
      end
    end
  end
  today_currencies_with_diff
end

def fetch_codes_and_names(db)
  db[:currencies].all
end

def fetch_todays_value_by_code(db, code: nil)
  # fetch by code from db, calculate diff
  # returns array to have single interface for formatting output
  table = db[:currencies]
  date = Date.today.to_s
  where = { date: date, code: code }
  today_currencies = table.select(:code, :name, :value).join(:values, currency_id: :id).where(where).all
  p today_currencies
  diff = calculate_daily_rate_diff(db, code: code)
  today_currencies.first[:diff] = diff unless diff.nil?
  today_currencies
end

def fetch_values_by_date(db, date: Date.today.to_s)
  table = db[:currencies]
  date = Date.parse(date)
  table.select(:code, :name, :value, :date).join(:values, currency_id: :id).where(date: date)
end

def calculate_daily_rate_diff(db, code: '')
  # TODO: refactor
  table = db[:currencies]
  yesterday = Date.today - 1.day

  calc_diff = lambda do |curr_values|
    (curr_values[1][:value] - curr_values[0][:value]) / (curr_values[0][:value] / 100)
  end

  # every currency diff calculation
  if code.empty?
    values = table.select(:value, :currency_id).join(:values, currency_id: :id).where(date: yesterday..Date.today).order(:date).all
    curr_ids = table.all.map { |curr| curr[:id] }
    diffs = []

    curr_ids.each do |id|
      curr_values = values.filter { |val| val[:currency_id] == id }.sort_by {|val| val[:date]}

      # check if there's no yesterday's values
      next if curr_values.size < 2

      # substract yesterday's value from today's.
      # count how many percents plus or minus from yesterday
      diff = calc_diff(curr_values)
      diffs.push({ currency_id: id, diff: "#{diff.round(2)} %" })
    end

    return diffs
  # specific currecy diff calculation
  else
    curr_values = table.select(:value).join(:values, currency_id: :id).where(date: yesterday..Date.today, code: code).order(:date).all

    # check if there's no yesterday's values
    return nil if curr_values.size < 2

    # substract yesterday's value from today's.
    # count how many percents plus or minus from yesterday
    diff = calc_diff(curr_values)
    "#{diff.round(2)} %"
  end
end

def format_response(data, fields: [])
  # extract values corresponding to fields
  rows = data.map do |row|
    row[:date] = row[:date].to_s if fields.include?(:date)
    row[:value] = row[:value].to_s.sub(',', '.').to_f.round(2) if fields.include?(:value)

    # if row data not unified with fields
    begin
      row.fetch_values(*fields)
    rescue KeyError
      fields = [:code, :name, :value]
      row.fetch_values(*fields)
    end
  end

  # set headings and draw table
  headings = fields
  table = Terminal::Table.new headings: headings, rows: rows
  table.style = { all_separators: true }

  "#{LOGO}#{NEW_LINE}#{table}#{NEW_LINE}#{Time.now}#{NEW_LINE}"
end
