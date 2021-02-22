require 'net/http'
require 'nokogiri'
require 'date'
require 'sequel'


def get_content(url)
    # make request, check status and return body if ok

    response = Net::HTTP.get_response(URI(url))
    response.code == '200' ? response.body : nil
end

def parse_content(xml_string)
    # create array of hashes from parsed xml list

    parsed_data = []
    xml = Nokogiri::XML(xml_string)
    currencies = xml.css('Valute')
    currencies.each do |curr|
        parsed_node = {
            code: curr.at_css('CharCode').text,
            nominal: curr.at_css('Nominal').text,
            name: curr.at_css('Name').text,
            value: curr.at_css('Value').text
        }
        parsed_data.push(parsed_node)
    end
    parsed_data
end


def normalize_and_prepare_for_save(parsed_data)
    # unify nominal, add date
    parsed_data.map do |curr|
        unless curr[:nominal].to_i == 1
            curr[:value] = curr[:value].to_f / curr[:nominal].to_i
        end
        curr[:nominal] = 1
        curr[:date] = Date.today.to_s
    end
    parsed_data
end


def save_to_db(data)
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

    table = db[:currencies]
    table.multi_insert(data)
    table
end


def run
    stock_url = 'http://www.cbr.ru/scripts/XML_daily_eng.asp'
    xml_string = get_content(stock_url)
    raise 'Stock response is not 200' if xml_string.nil?
    parsed_data = parse_content(xml_string)
    normalized_data = normalize_and_prepare_for_save(parsed_data)
    db_data = save_to_db(normalized_data)
    puts db_data.all
end

run
