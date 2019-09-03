# Live Website

[![Netlify Status](https://api.netlify.com/api/v1/badges/b7d6e478-386b-4843-9ee5-d4aa9302925e/deploy-status)](https://app.netlify.com/sites/pgp/deploys)

Static website running: [https://www.personalgenomes.org.uk](https://www.personalgenomes.org.uk)

This is the live branch that is built and hosted on Netlify.

## TO Run Locally

1. Install all dependencies

```bash
npm install netlify-cli
```

2. Link Netlify Account

```bash
netlify init

# Or if you have the site hosted under your own Netlify account
netlify link
```

3. Start Dev environment

```bash
netlify dev --live
```

### Other Branches

* Live: live branch
* Master: Legacy website hosted by github (pgp-uk.github.io). This only contains old email assets.
* Cron: trigger a rebuild of the live branch on netlify.
