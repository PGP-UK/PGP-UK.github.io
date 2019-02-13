#!/bin/bash
set -ex # exit immediately with nonzero exit code if anything fails

# Install dependencies
bundle install

LATEST_API_VERSION="v1.1"

# generate the json files
bundle exec ruby scripts/generate_json_files.rb
bundle exec ruby scripts/generate_ftp_links.rb
bundle exec ruby scripts/generate_api_files.rb www/api/${LATEST_API_VERSION}

# make /api == the latest version of the API documentation
cp www/api/index.html www/api/${LATEST_API_VERSION}
cp www/api/openapi.json www/api/${LATEST_API_VERSION}
cp www/api/openapi.yaml www/api/${LATEST_API_VERSION}

# make old API link work
cp -r www/api/v1.0  www/api/v1

# Copy the original files
cp data/table.json www/data/json/table.json
cp data/phenotype.csv www/data/phenotype.csv
cp data/data_file_links.csv www/data/data_file_links.csv
