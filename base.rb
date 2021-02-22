require 'sequel'
require 'terminal-table'


def init_db
	# create db and table if not exist and bulk insert data
	db = Sequel.sqlite('test.db')

	unless db.table_exists?(:currencies)
		db.create_table :currencies do
			primary_key :id

			column :code, String
			column :name, String
			column :nominal, Integer
			column :value, Float
			column :date, String
		end
	end

	return db
end


def save_to_db(db, data={})
	table = db[:currencies]
	table.multi_insert(data)
	table
end


def fetch_todays_course(db)
	today = Date.today.to_s
  table = db[:currencies]
  today_currencies = table.where(date: today).all
end


def format_response(data)
	headings = [:code, :name, :value, :date]
	rows = data.map { |row| row.fetch_values(:code, :name, :value, :date) }
	table = Terminal::Table.new :headings => headings, :rows => rows
	table.style = {:all_separators => true}
	table
end
