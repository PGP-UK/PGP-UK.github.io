#!/bin/bash
set -e # exit with nonzero exit code if anything fails

gem install typhoeus

# generate the json files
ruby generate_json_files.rb www/data/json
ruby csv_parser.rb www/data/json
mv phenotype.csv www/data/phenotype.csv
