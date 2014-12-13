#!/usr/bin/env ruby
require 'mechanize'
require 'scraperwiki-morph'

@agent = Mechanize.new
@base_url = 'http://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/Bills_Search_Results/Result?bId='

def get_bill(id)
  if (!ScraperWikiMorph.select("id from data where id='#{id}'").empty? rescue false)
    puts "Skipping already saved bill #{id}"
    return
  end

  url = @base_url + id
  page = @agent.get url
  title = page.at('#content').at(:h1).inner_text.strip

  if title == 'Bill not found'
    puts "Bill not found for #{id}"
    return
  end

  bill_details = page.at('dl.specs').search(:dd).map { |e| e.inner_text.strip }

  bill = {
    id: id,
    url: url,
    title: title,
    type: bill_details[0],
    portfolio: bill_details[1],
    originating_house: bill_details[2],
    status: bill_details[3],
    parliament_number: bill_details[4],
    summary: bill_details[5],
  }

  puts "Saving bill #{id}"
  ScraperWikiMorph.save_sqlite([:id], bill)
end

get_bill("R3001")
