require 'active_record'

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

    create_table :values do |t|
      t.integer :currency_id, null: false
      t.float :value, null: false
      t.date :created_at, null: false
    end

    add_index :values, :currency_id
    add_index :values, :created_at
  end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Currency < ApplicationRecord
  validates :code, :name, presence: true
  has_many :values
end

class Value < ApplicationRecord
  validates :value, :created_at, presence: true
  belongs_to :currency
end

def daily_update_db(data)
  # insert currencies if table is empty
  unless Currency.any?
    sliced_codes_and_names = data.map { |row| row.slice(:code, :name) }
    Currency.insert_all(sliced_codes_and_names)
  end
  # match values with currencies and bulk save
  currencies = Currency.all
  values_to_create = []

  data.each do |row|
    matched_currency = currencies.filter { |curr| curr.id if curr.code == row[:code] }
                                 .first
    value_data = {
      currency_id: matched_currency.id,
      value: row[:value],
      created_at: row[:date]
    }
    values_to_create.push(value_data)
  end

  Value.insert_all(values_to_create)
end
