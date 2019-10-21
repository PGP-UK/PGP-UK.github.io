# Live Website

[![Netlify Status](https://api.netlify.com/api/v1/badges/4a760548-07c0-42b0-b613-cd993b8c8777/deploy-status)](https://app.netlify.com/sites/pgp-uk-dev/deploys)

Static website running: https://www.personalgenomes.org.uk

This is the live branch that is built and hosted on Netlify.

## TO Run Locally

1. Install a dependencies

```bash
brew install hugo
```

2. Next, generate the latest version of the JSON files (pulls the latest from EBI and PGP-UK Website).

```bash
bash deploy.sh
```

3. Start the Local Webserver

```bash
hugo server --source www
```

### Other Branches

* Live: live branch
* Master: Legacy website hosted by github (pgp-uk.github.io). This only contains old email assets.
* Cron: trigger a rebuild of the live branch on netlify.