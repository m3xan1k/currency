require 'active_record'
require 'active_support/time'
require 'pry'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'test.db'
)

unless ActiveRecord::Base.connection.table_exists? 'currencies'
  ActiveRecord::Schema.define do
    create_table :currencies do |t|
      t.string :code, null: false
      t.string :name, null: false
    end

    add_index :currencies, :code

    create_table :rates do |t|
      t.integer :currency_id, null: false
      t.float :rate, null: false
      t.date :created_at, null: false
    end

    add_index :rates, :currency_id
    add_index :rates, :created_at
  end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Currency < ApplicationRecord
  validates :code, :name, presence: true
  has_many :rates
end

class Rate < ApplicationRecord
  validates :rate, :created_at, presence: true
  belongs_to :currency
end

def daily_update_db(data)
  # insert currencies if table is empty
  unless Currency.any?
    sliced_codes_and_names = data.map { |row| row.slice(:code, :name) }
    Currency.insert_all(sliced_codes_and_names)
  end
  # match rates with currencies and bulk save
  currencies = Currency.all
  rates_to_create = []

  data.each do |row|
    matched_currency = currencies.filter { |curr| curr.id if curr.code == row[:code] }
                                 .first
    rate_data = {
      currency_id: matched_currency.id,
      rate: row[:rate],
      created_at: row[:date]
    }
    rates_to_create.push(rate_data)
  end

  rate.insert_all(rates_to_create)
end

def calculate_daily_rate_diff
  lambda do |code, currencies|
    todays_currency_with_diff = {}
    # filter currencies by code first is yesterday
    matched_currencies = currencies.filter { |curr| curr['code'] == code }
                                   .sort_by { |curr| curr['date'] }
    binding.pry
    # check if today's and yesterday's rates exist, subtract and write diff
    if matched_currencies.size == 2
      diff = matched_currencies.last['rate'] - matched_currencies.first['rate']
      todays_currency_with_diff['diff'] = diff
    end
    # slice essential fields and merge with diff
    fields_to_slice = %w[code name rate]
    todays_currency_with_diff.merge(matched_currencies.last.slice(*fields_to_slice))
  end
end

def fetch_todays_rates_with_diff
  today = Date.today
  yesterday = today - 1.day
  # query joined currencies and rates for today and yesterday to count diff
  currency_objects = Currency.select(:name, :code, :rate, 'created_at as date')
                             .joins(:rates)
                             .where(rates: { created_at: yesterday..today })
                             .all
  # turn objects to hashes
  currencies = currency_objects.map(&:attributes)
  # codes to filter pairs of currencies later
  codes = currencies.map { |curr| curr['code'] }.uniq

  # calculate diffs
  currencies_with_diff = []
  codes.each do |code|
    todays_currency_with_diff = calculate_daily_rate_diff.call(code, currencies)
    currencies_with_diff.push(todays_currency_with_diff)
  end
  currencies_with_diff
end
