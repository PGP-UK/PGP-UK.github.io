#!/bin/bash
set -ex # exit immediately with nonzero exit code if anything fails

# Install dependencies
bundle install

LATEST_API_VERSION="v1.1"

# generate the json files
bundle exec ruby scripts/generate_json_files.rb
bundle exec ruby scripts/generate_ftp_links.rb
bundle exec ruby scripts/generate_api_files.rb www/static/api/${LATEST_API_VERSION}

# Copy the original files
cp data/table.json www/static/data/json/table.json
cp data/phenotype.csv www/static/data/phenotype.csv
cp data/data_file_links.csv www/static/data/data_file_links.csv

# make /api == the latest version of the API documentation
cp www/static/api/openapi.json www/static/api/${LATEST_API_VERSION}
cp www/static/api/openapi.yaml www/static/api/${LATEST_API_VERSION}

hugo -s www --minify

# make old API link work
cp -r www/public/api/v1.0  www/public/api/v1

cp www/public/api/index.html www/public/api/v1
cp www/public/api/index.html www/public/api/v1.0
cp www/public/api/index.html www/public/api/${LATEST_API_VERSION}

rsync -a --ignore-existing www/content/uploads/* www/public/images && rm www/public/images/_index.md
