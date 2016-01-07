# bmw_cpo_crawler
Crawls BMW CPO pages to see if there were any changes from day to day.

Requires:
- Nokogiri
- Open-uri
- uri
- yaml
- colorize
 
Tested on Ubuntu 14.04

Data is stored in yaml files in the same directory and then compared against each other. Only one yaml file per day is allowed.

Usage:
./cpo-crawler \<param\> \<type\>

\<param\> could be:
- -N - overwrite current daily file with new search

\<type\> could be:
- 550i
- M5
- M6
- 550ixDrive
