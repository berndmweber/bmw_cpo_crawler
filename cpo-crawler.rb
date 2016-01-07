#!/usr/bin/ruby
# Copyright (c) 2015, Bernd Weber
# All rights reserved.

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'uri'
require 'yaml'
require 'colorize'

vin_struct = Struct::new( "VINStruct", :price, :link)
replaceLatestCheck = FALSE
foundSearch = FALSE
type = nil

ARGV.each do |arg|
	if /^-/.match(arg)
		case arg
		when "-N"
			replaceLatestCheck = TRUE
		else
			puts "This parameter \"" + arg + "\" is currently not supported."
		end
	else
		foundSearch = TRUE
		case arg
		when '550i'
			type = '550i'
			PAGE_URL = "http://cpo.bmwusa.com/used-inventory/index.htm?year=2013-2013&odometer=1-40000&highwayMpg=&normalPackages=Driver+Assistance&superModel=5+Series&gvModel=550i&compositeType=used&geoZip=95051&geoRadius=0&showSelections=true&showFacetCounts=true&showSubmit=true&searchLinkText=SEARCH&facetbrowse=true&showRadius=true"
		when 'M5'
			type = 'M5'
			PAGE_URL = "http://cpo.bmwusa.com/used-inventory/index.htm?superModel=M+Series&gvModel=M5&compositeType=certified&geoZip=95051&geoRadius=0&sortBy=internetPrice+asc&internetPrice=1-9999999"
		when 'M6'
			type = 'M6'
			PAGE_URL = "http://cpo.bmwusa.com/used-inventory/index.htm?superModel=M+Series&gvModel=M6&compositeType=certified&geoZip=95051&geoRadius=0&sortBy=internetPrice+asc&internetPrice=1-9999999"
		when '550ixDrive'
			type = '550ixDrive'
			PAGE_URL = "http://cpo.bmwusa.com/used-inventory/index.htm?year=2013-2013&odometer=1-40000&highwayMpg=&normalPackages=Driver+Assistance&superModel=5+Series&gvModel=550i+xDrive&compositeType=used&geoZip=95051&geoRadius=0&showSelections=true&showFacetCounts=true&showSubmit=true&searchLinkText=SEARCH&facetbrowse=true&showRadius=true"
		else
			puts "This search \"" + arg + "\" is currently not supported. Exiting."
			exit 0
		end
	end
end

if (ARGV.size == 0) or (foundSearch == FALSE)
	puts "At least one search needs to be specified. Exiting."
	exit 0
end


nowDate = DateTime.now.strftime("%m-%d-%Y")
latest_file = Dir[File.join("./", "*.#{type}.yaml")].max_by(&File.method(:ctime))

if !latest_file.nil?
	if latest_file.include? nowDate
		if replaceLatestCheck == TRUE
			File.delete(latest_file)
			latest_file = Dir[File.join("./", "*.#{type}.yaml")].max_by(&File.method(:ctime))
		else
			puts "Already checked today. Exiting."
			exit 0
		end
	end
	oldVinHash = YAML::load_file(latest_file)
else
	oldVinHash = {}
end

fileName = './cpo-' + nowDate + '.' + type + '.yaml'
f = File.open(fileName, 'w') 

page = Nokogiri::HTML(open(PAGE_URL))

pages = page.css('div[class=paging]')
pages = pages.css('strong')[0].text
pages = pages.scan(/\d+/).last.to_i

car_vins = page.css('div[data-vin]')

newVinHash = Hash.new

car_vins.each do |vin|
	newVinHash[vin.attribute('data-vin').to_s] = vin_struct.new(vin.css('span[class=value]').text, 'http://' + URI(PAGE_URL).host + vin.css('a[class=url]').attribute('href'))
end

if pages > 1
	p = 1
	while p < pages
		start = 16*p
		page = Nokogiri::HTML(open(PAGE_URL + '&start=' + start.to_s))
		car_vins = page.css('div[data-vin]')
		car_vins.each do |vin|
			newVinHash[vin.attribute('data-vin').to_s] = vin_struct.new(vin.css('span[class=value]').text, 'http://' + URI(PAGE_URL).host + vin.css('a[class=url]').attribute('href'))
		end
		p += 1
	end
end


f.write newVinHash.to_yaml
f.close

if oldVinHash.empty?
	exit 0
end

newVinHash.each do |key, value|
	if oldVinHash[key].nil?
		puts 'New entry:'.green
		puts ' VIN: '.green + key.green
		puts ' Price: '.green + value.price.green
		puts ' Link: '.green + value.link.green
		puts ' ---------- '
	else 
		if oldVinHash[key].price != value.price
			puts 'Changed entry:'
			puts ' VIN: ' + key
			if oldVinHash[key].price < value.price
				puts ' Price: ' + oldVinHash[key].price + ' -> ' + value.price.red
			else
				puts ' Price: ' + oldVinHash[key].price + ' -> ' + value.price.green
			end
			puts ' Link: ' + value.link
			puts ' ---------- '
		end
	end
end

oldVinHash.each do |key, value|
	if newVinHash[key].nil?
		puts 'Removed entry:'.red
		puts ' VIN: '.red + key.red
		puts ' Price: '.red + value.price.red
		puts ' Link: '.red + value.link.red
		puts ' ---------- '
	end
end
