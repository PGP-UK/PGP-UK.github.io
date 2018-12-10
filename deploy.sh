#!/bin/bash
set -ex # exit immediately with nonzero exit code if anything fails

# Install dependencies
bundle install

# generate the json files
bundle exec ruby scripts/generate_json_files.rb
bundle exec ruby scripts/generate_ftp_links.rb
bundle exec ruby scripts/generate_api_files.rb

# Copy the original files
cp data/table.json www/data/json/table.json
cp data/phenotype.csv www/data/phenotype.csv
cp data/data_file_links.csv www/data/data_file_links.csv
