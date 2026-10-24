# MediaFlow web deployment

The app is built as a Flutter Web static site. Nginx serves it on port 13000 and routes the domain to that site on port 80. The deployment workflow builds on pushes to `main`.

## One-time setup

1. In the repository, open **Settings → Secrets and variables → Actions** and add the repository secret `DEPLOY_SSH_KEY`. Paste the full PEM private key from the EC2 key file. Keep it in GitHub Secrets; never commit it.
2. In DNS, create an `A` record for `media.learner-teach.online` pointing to `13.212.32.202`. Remove any stale `AAAA` record unless the server has a matching public IPv6 address.
3. In the EC2 security group, allow inbound TCP 80 and 443 for the domain. Allow TCP 13000 only if direct access to `http://13.212.32.202:13000` is needed; the domain itself uses 80/443.
4. After DNS resolves to the server and TCP 80 is reachable, run `sudo certbot --nginx -d media.learner-teach.online` on the server to enable HTTPS.

The workflow can build before the SSH secret exists; in that case it uploads a short-lived build artifact and marks deployment as skipped. After adding the secret, run **Actions → Build and deploy web app → Run workflow** to deploy the latest commit.

## Server layout

- App release directories: `/var/www/mediaflow/releases/<commit-sha>`
- Active release symlink: `/var/www/mediaflow/current`
- Nginx serves the app on port `13000` and proxies the domain from port `80`.

Each deployment installs `deploy/nginx/mediaflow.conf`, switches the active release, checks the Nginx configuration, then reloads Nginx.
