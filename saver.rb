require 'net/http'
require 'nokogiri'
require 'date'

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
    # normalize value
    curr[:value] = curr[:value].sub(',', '.').to_f
    curr[:value] = curr[:value] / curr[:nominal].to_i unless curr[:nominal].to_i == 1
    curr.delete(:nominal)
    curr[:date] = Date.today.to_s
  end
  parsed_data
end
