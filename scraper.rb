#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'csv'
require 'nokogiri'
require 'open-uri'
require 'pry'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

def dob(text)
  return if text.to_s.empty?
  Date.parse(text).to_s
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('.carousel-feature a/@href').map(&:text).each do |link|
    mp_url = URI.join url, link
    mp = noko_for(mp_url)

    box = mp.css('#content_left')

    faction = box.xpath('.//td[contains(.,"Fractie")]/following-sibling::td').text.tidy
    party, party_id = faction.match(/(.*) \((.*)\)/).captures unless faction.to_s.empty?

    data = {
      id:         mp_url.to_s[/(\d+).html$/, 1],
      name:       box.css('h1').text.tidy.sub(/\s*\([^\)]+\)/, ''),
      other_name: box.xpath('.//td[contains(.,"Naam")]/following-sibling::td').text.tidy,
      party:      party,
      party_id:   party_id,
      email:      box.xpath('.//td[contains(.,"Email")]/following-sibling::td/a/@href').map(&:text).join(';').gsub('mailto:', ''),
      phone:      box.xpath('.//td[contains(.,"Telefoon")]/following-sibling::td').text.tidy,
      fax:        box.xpath('.//td[contains(.,"Fax")]/following-sibling::td').text.tidy,
      facebook:   box.xpath('.//td[contains(.,"Facebook")]/following-sibling::td/a/@href').map(&:text).join(';'),
      twitter:    box.xpath('.//td[contains(.,"Twitter")]/following-sibling::td/a/@href').map(&:text).join(';'),
      linkedin:   box.xpath('.//td[contains(.,"Linkedin")]/following-sibling::td/a/@href').text,
      birth_date: dob(box.xpath('.//td[contains(.,"Geboortedatum")]/following-sibling::td').text),
      image:      box.xpath('.//h1/following-sibling::img[1]/@src').text,
      term:       '7',
      source:     mp_url.to_s,
    }
    data[:image] = URI.join(mp_url, data[:image]).to_s unless data[:image].to_s.empty?
    ScraperWiki.save_sqlite(%i(id term), data)
  end
end

scrape_list('http://www.parlamento.aw/internet/leden_226/')
