require 'nokogiri'
require 'open-uri'
require 'json'
require 'fileutils'
require 'write_xlsx'

class ScrapperData
  def self.scrape(url, producer, output_format)
    puts '-' * 100
    puts 'Seja bem vindo....'
    puts 'Por favor, aguarde enquanto os dados estão sendo processados...'
    puts 'Todos os valores pesquisados neste exemplo, estão sendo acessados pela página nuuvem.com.br'
    puts '-' * 100

    html = URI.open(url)

    doc = Nokogiri::HTML(html)

    pagination_element = doc.css('.pagination--item').last
    total_pages = pagination_element.text.strip.to_i

    file_name = "games_nuuvem_#{producer.downcase}.#{output_format}"

    directory_path = File.join('src', 'data', producer.downcase)

    FileUtils.mkdir_p(directory_path) unless File.directory?(directory_path)

    file_path = File.join(directory_path, file_name)

    games_nuuvem = []

    (1..total_pages).each do |page_number|
      page_url = "#{url}/page/#{page_number}"

      page_html = URI.open(page_url)

      page_doc = Nokogiri::HTML(page_html)

      games_titles = page_doc.css('.product-title.single-line-name')
      games_steam_platforms = page_doc.css('ul.product-drm-info > li > div > span')
      games_prices = page_doc.css('.product-button__label')
      games_images = page_doc.css('.product-img img')
      game_discount = page_doc.css('.product-discount')

      games_titles.each_with_index do |game, index|
        title = game.text.strip
        platform = games_steam_platforms[index].text.strip
        price = games_prices[index].text.strip
        price_discount = game_discount[index].text.strip
        image = games_images[index]['src'] if games_images[index]

        games_nuuvem << {
          'title' => title,
          'producer' => producer,
          'image' => image,
          'platform' => platform,
          'price' => price,
          'price_discount' => price_discount,
          'date_promotion' => Time.now.strftime('%Y-%m-%d %H:%M:%S')
        }
      end
    end

    case output_format
    when 'json'
      File.open(file_path, 'w') do |file|
        json_data = {
          'data' => games_nuuvem,
          'total_items' => games_nuuvem.size,
          'total_page' => total_pages
        }
        file.puts JSON.pretty_generate(json_data)
      end
    when 'txt'
      File.open(file_path, 'w') do |file|
        games_nuuvem.each do |game|
          file.puts "title: #{game['title']}"
          file.puts "producer: #{game['producer']}"
          file.puts "image: #{game['image']}"
          file.puts "platform: #{game['platform']}"
          file.puts "price: #{game['price']}"
          file.puts "price_discount: #{game['price_discount']}"
          file.puts "date_promotion: #{game['date_promotion']}"
          file.puts '---------------------'
        end
      end
    when 'xlsx'
      workbook = WriteXLSX.new(file_path)

      worksheet = workbook.add_worksheet
      headers = ['Title',
                 'Producer',
                 'Image',
                 'Platform',
                 'Price',
                 'Price Discount',
                 'Date Promotion']
      headers.each_with_index { |header, index| worksheet.write(0, index, header) }

      row = 1
      games_nuuvem.each do |game|
        worksheet.write(row, 0, game['title'])
        worksheet.write(row, 1, game['producer'])
        worksheet.write(row, 2, game['image'])
        worksheet.write(row, 3, game['platform'])
        worksheet.write(row, 4, game['price'])
        worksheet.write(row, 5, game['price_discount'])
        worksheet.write(row, 6, game['date_promotion'])
        row += 1
      end
      workbook.close
    else
      puts 'Formato de saída inválido. Por favor, use "json", xlsx ou "txt".'
      return
    end

    puts "Dados processados com sucesso! Arquivo salvo em #{file_path}"
  end
end
