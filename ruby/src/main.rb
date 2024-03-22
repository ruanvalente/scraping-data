require_relative 'lib/scraper'

base_url = 'https://www.nuuvem.com/br-pt'

print 'Por favor, insira o nome do produtor(a): '
producer = gets.chomp.downcase.tr(' ', '-')

puts "URL base da página da web: #{base_url}"
puts "Produtor: #{producer}"

producer_url = "#{base_url}/promo/#{producer.downcase}"

puts "producer_url: #{producer_url}"

ScrapperData.scrape(producer_url, producer, 'json')
ScrapperData.scrape(producer_url, producer, 'txt')
ScrapperData.scrape(producer_url, producer, 'xlsx')
