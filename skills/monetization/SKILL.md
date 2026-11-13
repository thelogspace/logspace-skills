---
name: monetization
description: Adds ads (AdMob, Unity Ads / LevelPlay), in-app purchases (Flutter in_app_purchase, Unity IAP) and the consent flow (Google UMP for GDPR, iOS ATT) to a LogSpace project. Covers test/real ad ID separation, ad placement rules, purchase validation and tests. Use for "reklam", "admob", "unity ads", "rewarded", "satın alma", "IAP", "abonelik", "consent", "ATT".
---

# LogSpace Monetization

## Order of operations at app start (mandatory)

1. **UMP consent** (Google User Messaging Platform): the form is shown in the EEA/UK/Switzerland.
2. **ATT** (iOS only): the permission prompt comes **after** UMP, and only if UMP allows ads.
3. **Ads SDK init**: only after `canRequestAds == true`.
4. Firebase consent mode is updated from the UMP result (`logspace:firebase`).

The UMP form can be reopened from **About → Privacy settings** (`logspace:about`).

## Ads

| Stack | Package |
|---|---|
| Flutter | `google_mobile_ads` (UMP built in) |
| Unity | Google Mobile Ads Unity plugin, or Unity LevelPlay (Unity Ads + mediation), per project |
| Web-game | ads are shown by the Flutter shell; the game requests them through the bridge (`{type:"showRewarded", placement}`) and waits for the result |

**Ad unit IDs:**
- Debug/dev builds always use **Google's official test IDs**. Clicking real ads in debug can get the AdMob account suspended.
- Real IDs are in the prod flavor config (`--dart-define` / build-time config); never in code.
- Test devices are added with `RequestConfiguration.testDeviceIds`.
- `store-compliance` blocks the release if a prod build has test IDs, or a debug build has real IDs.

**Placement rules (policy + UX):**
- Rewarded: only by the user's choice; the reward is given in the `onUserEarnedReward` callback.
- Interstitial: only at natural breaks (level end); a frequency cap (e.g. at least 60 s between two); never at app open or on the first level.
- Banner: never overlapping game controls; safe area.
- Ads are preloaded; a failure is never shown to the user as an error, the game continues.
- App-ads.txt: published at `https://logspace.xyz/app-ads.txt` (one file for all apps). Each new AdMob app's publisher line is added there.

## In-app purchases

| Stack | Package |
|---|---|
| Flutter | `in_app_purchase` (consumable / non-consumable / subscription) |
| Unity | Unity IAP (`com.unity.purchasing`) |

- Product IDs: `<packageId>.<product>` → `xyz.logspace.colorstrix.remove_ads`. One list in one config file.
- **Restore Purchases** button is mandatory (App Store rejects without it).
- Non-consumables (e.g. remove_ads) are recorded locally as well, but the source of truth is the store.
- If the purchase grants a server-side benefit, receipt verification is done **on the server**; client-side verification can be bypassed.
- `completePurchase` / `ConfirmPendingPurchase` is always called; pending purchases are refunded otherwise.
- Prices are always shown from the store (localized); never hardcoded.
- Sandbox / license testers are used for testing.

## Architecture (KISS)

`AdsService` and `PurchaseService`: one interface each, at the edge; the rest of the game/app uses only them. That way they can be faked in tests and nobody touches the SDK directly. (This is a "real need": the real SDK in production, a fake in tests.)

## Tests

- Consent order: no ad request is made before UMP and ATT finish.
- Interstitial frequency cap and "not on the first level" rule.
- Reward is given only in the reward callback; not on close.
- Purchase success / cancel / pending / error flows; restore restores the right products.
- Debug build uses test IDs.

## Store

- Data Safety / Privacy Manifest: ads SDKs collect the advertising ID → declare it.
- If the target audience includes children: Families policy, certified ad SDKs and non-personalized ads only. Ask the user before starting.
