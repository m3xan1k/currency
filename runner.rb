require './saver'
require './db'

def run
  stock_url = 'http://www.cbr.ru/scripts/XML_daily_eng.asp'
  xml_string = get_content(stock_url)

  raise 'Stock response is not 200' if xml_string.nil?

  parsed_data = parse_content(xml_string)
  normalized_data = normalize_and_prepare_for_save(parsed_data)
  daily_update_db(normalized_data)
end
