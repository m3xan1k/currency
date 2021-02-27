require './saver.rb'
require './base.rb'

def run
  stock_url = 'http://www.cbr.ru/scripts/XML_daily_eng.asp'
  xml_string = get_content(stock_url)

  raise 'Stock response is not 200' if xml_string.nil?

  parsed_data = parse_content(xml_string)
  normalized_data = normalize_and_prepare_for_save(parsed_data)
  db = init_db
  db_data = save_to_db(db, data: normalized_data)
  puts db_data.all
end

run
