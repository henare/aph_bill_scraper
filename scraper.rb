require 'mechanize'
require 'scraperwiki-morph'

@agent = Mechanize.new
@base_url = 'http://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/Bills_Search_Results/Result?bId='

def get_bill(id)
  url = @base_url + id
  page = @agent.get url
  bill_details = page.at('dl.specs').search(:dd).map { |e| e.inner_text.strip }

  bill = {
    id: id,
    url: url,
    title: page.at('#content').at(:h1).inner_text,
    type: bill_details[0],
    portfolio: bill_details[1],
    originating_house: bill_details[2],
    status: bill_details[3],
    parliament_number: bill_details[4],
    summary: bill_details[5],
  }

  ScraperWikiMorph.save_sqlite([:id], bill)
end

get_bill("R3001")
