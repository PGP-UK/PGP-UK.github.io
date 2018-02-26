# Live Website

Static website running: https://www.personalgenomes.org.uk

This is the live branch that is built and hosted on Netlify.

## TO Run Locally 

1. Install a dependencies 

```bash
gem install serve
gem install thin
```

2. Next, generate the latest version of the JSON files (pulls the latest from EBI and PGP-UK Website).

```bash 
bash deploy.sh
```

3. Start the Local Webserver 

```bash
serve www 
```

### Other Branches

* Live: live branch
* Master: Legacy website hosted by github (pgp-uk.github.io). This only contains old email assets.
* Cron: trigger a rebuild of the live branch on netlify.