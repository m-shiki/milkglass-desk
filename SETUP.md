# Setup

## 1. Create the GitHub repository

1. Create a repository such as `milkglass-desk`.
2. Upload **the contents of this folder**, including hidden folders/files.
3. Keep `index.html` at the repository root.
4. In **Settings → Pages → Build and deployment → Source**, choose **GitHub Actions**.
5. Push to `main`. The included workflow deploys the site.

## 2. Create the private cloud save

1. Create a Supabase project.
2. Open **SQL Editor**.
3. Paste and run all of `supabase/schema.sql`.
4. Open **Authentication → URL Configuration**.
5. Set **Site URL** to your final GitHub Pages URL, for example:
   `https://YOUR_NAME.github.io/milkglass-desk/`
6. Add the same URL to **Redirect URLs**.
7. Open the project's **Connect** dialog or **Settings → API Keys**.
8. Copy the project URL and the **Publishable key**.
9. Edit `config.js`:

```js
window.MILKGLASS_CONFIG = {
  supabaseUrl: "https://YOUR_PROJECT.supabase.co",
  supabasePublishableKey: "sb_publishable_..."
};
```

Only use the publishable key. Never put a secret key or service-role key in the repository.

## 3. First login

1. Open the published app.
2. Press **SIGN IN** or **SYNC**.
3. Enter your email and open the magic link.
4. Return to the app and press **SYNC**.
5. After the first account is created, you may disable new-user signups in Supabase Auth settings if this is strictly a one-person app.

## 4. Daily use

- Every click saves immediately to this device.
- Press **SYNC** before changing devices and again after opening the other device.
- If both devices changed, a conflict window shows both saves and asks which one to keep.
- After 06:00 JST, **NEW DAY** appears. Press it to bank yesterday's Pending rewards and reset the sheet.

## 5. GitHub settings worth enabling

- Protect `main` from deletion and force pushes.
- Limit the `github-pages` environment to the `main` branch.
- Do not upload exported `milkglass-desk-*.json` files.

## Updating the app

Replace `index.html` with the new version and commit to `main`. GitHub Actions redeploys it automatically. Cloud save data remains in Supabase and is not stored in the repository.
