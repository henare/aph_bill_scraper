#!/usr/bin/env ruby
require 'mechanize'
require 'scraperwiki'

@agent = Mechanize.new
@base_url = 'http://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/Bills_Search_Results/Result?bId='
@bill_not_found_count = 0

def get_bill(house, id)
  aph_id = house[0].upcase + id.to_s
  if (!ScraperWiki.select("aph_id from data where aph_id='#{aph_id}'").empty? rescue false)
    puts "Skipping already saved bill #{aph_id}"
    return
  end

  url = @base_url + aph_id
  page = @agent.get url
  title = page.at('#container').at(:h1).inner_text.strip

  if title == 'Bill not found'
    puts "Bill not found for #{aph_id}"
    @bill_not_found_count += 1
    return
  end

  bill_details = page.at('dl.specs').search(:dd).map { |e| e.inner_text.strip }

  bill = {
    id: id,
    house: house,
    aph_id: aph_id,
    url: url,
    title: title,
    type: bill_details[0],
    portfolio: bill_details[1],
    originating_house: bill_details[2],
    status: bill_details[3],
    parliament_number: bill_details[4],
    summary: bill_details[5],
  }

  puts "Saving bill #{aph_id}"
  ScraperWiki.save_sqlite([:aph_id], bill)
  @bill_not_found_count = 0
end


["representatives", "senate"].each do |house|
  bill_id = (ScraperWiki.select("max(id) from data where house='#{house}'").first['max(id)'] || 1 rescue 1)
  puts "*** Getting #{house} bills, starting at #{bill_id}"

  # Stop after 250 pages with no bill found. This might sound excessive
  # but from what I've found some really big gaps
  while @bill_not_found_count <= 250
    get_bill(house, bill_id)
    bill_id += 1
  end
  puts "*** Finished getting #{house} bills"
  @bill_not_found_count = 0
end
