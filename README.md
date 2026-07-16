# Milkglass Desk

A milky habit, EXP, coin, and reward-ticket tracker for GitHub Pages.

## Included

- `index.html` — the complete app
- `config.js` — Supabase public configuration
- `.github/workflows/pages.yml` — automatic GitHub Pages deployment
- `supabase/schema.sql` — private save table, RLS policies, and revision-safe sync function
- `SETUP.md` — setup instructions

## Important save rules

- Task rewards are **Pending** during the current operational day.
- The day changes at **06:00 JST**.
- The first SYNC after 06:00 banks the old Pending EXP/coins and opens a new sheet.
- Ticket purchases use **Banked Coins only**.
- The first fresh save starts with a **30-coin welcome bonus**.
- Every cloud write checks a revision number. If two devices changed, the app asks which save to keep instead of silently overwriting one.

Open `SETUP.md` before publishing.
