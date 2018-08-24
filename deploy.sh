#!/bin/bash
set -e # exit immediately with nonzero exit code if anything fails

# Install dependencies
bundle install

# generate the json files
bundle exec ruby generate_json_files.rb
bundle exec ruby generate_ftp_links.rb

cp phenotype.csv www/data/phenotype.csv
