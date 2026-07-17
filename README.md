# \# Hissa — Mobile App

# 

# Fractional real-estate investing for Pakistan. Buy shares in vetted property from PKR 5,000, earn monthly rental income, and exit through a secondary marketplace. Every property sits in its own SPV; the platform is Shariah-compliant (no riba).

# 

# This repo is the \*\*Flutter mobile app\*\*. It talks to a NestJS API and a Next.js admin panel, which live in separate repos.

# 

# > \*\*Status: working prototype.\*\* Everything below runs end to end against a real database — but on a local machine, with simulated payments. It is not deployed and takes no real money. See \[What's not done](#whats-not-done).

# 

# \---

# 

# \## The three pieces

# 

# | Repo | What it is | Port |

# |---|---|---|

# | `hissa\_mobile` (this) | Flutter app — the investor-facing product | — |

# | `hissa-backend` | NestJS + TypeORM + PostgreSQL API | 3000 |

# | `hissa-admin` | Next.js admin — property CRUD, KYC approvals, payouts | 3001 |

# 

# The app and the admin share one API and one JWT scheme. Admin access is gated on `role: "admin"` in the token.

# 

# \---

# 

# \## Running it

# 

# You need all three pieces up, in this order.

# 

# \### 1. Database (Docker)

# 

# ```bash

# docker start hissa-pg          # Postgres on port 5433

# ```

# 

# Docker Desktop must be running first. If the container doesn't exist yet, the backend repo has the setup.

# 

# \### 2. Backend

# 

# ```bash

# cd hissa-backend

# npm run start:dev

# ```

# 

# Wait for `Nest application successfully started`. \*\*Keep this terminal visible\*\* — OTP codes print here in development.

# 

# \### 3. The app

# 

# ```bash

# cd hissa\_mobile

# flutter pub get

# flutter run

# ```

# 

# \*\*Set the API URL first.\*\* `lib/config.dart` must match how you're running:

# 

# | Target | `apiBaseUrl` |

# |---|---|

# | Chrome (web) | `http://localhost:3000` |

# | Android emulator | `http://10.0.2.2:3000` |

# | Real Android phone | `http://<your-PC-LAN-IP>:3000` |

# 

# Find your IP with `ipconfig` (Windows) — use the \*\*Wi-Fi adapter's\*\* IPv4, not a Docker/WSL virtual adapter. Phone and PC must share a network.

# 

# \*\*Android also needs:\*\*

# \- Your IP listed in `android/app/src/main/res/xml/network\_security\_config.xml` — Android 9+ blocks plain HTTP without it

# \- Windows Firewall allowing port 3000 inbound

# 

# Quickest way to tell whether it's a network problem or an app problem: open `http://<ip>:3000/properties` in the \*\*phone's\*\* browser. JSON means the network is fine.

# 

# \### Logging in

# 

# Phone/OTP only. Enter a Pakistani-format number (`03001234567`), then read the 6-digit code from the \*\*backend terminal\*\*. Google/Apple/email are UI-only — the backend has no such endpoints.

# 

# A phone number \*is\* the account. New number → new user → profile setup. Existing number → straight in.

# 

# \---

# 

# \## How it's put together

# 

# ```

# lib/

# ├── main.dart                 entry point, theme, dark-mode plumbing (parked)

# ├── app.dart                  routing: splash → login → KYC → main

# ├── config.dart               API base URL + useMock flag

# ├── theme.dart                colour palette, typography

# ├── store.dart                legacy in-memory store (mock mode only)

# ├── models/

# │   └── property.dart         Property + money formatting helpers

# ├── services/                 one service per API area

# │   ├── api\_client.dart       HTTP wrapper: GET/POST/PATCH/DELETE + multipart, holds the JWT

# │   ├── auth\_service.dart     OTP, JWT, profile, session persistence

# │   ├── property\_service.dart properties + their images

# │   ├── wallet\_service.dart   balance, transactions, deposit, withdraw

# │   ├── investment\_service.dart  buy shares, portfolio aggregation

# │   ├── marketplace\_service.dart secondary market listings

# │   └── kyc\_service.dart      verification status + submission

# └── screens/                  one file per screen

# ```

# 

# \*\*The pattern:\*\* screens never call HTTP directly. They call a service; the service calls `apiClient`, which attaches the `Authorization: Bearer` header. Swapping mock for real data is a flag in `config.dart`.

# 

# `useMock = true` falls back to built-in sample data with no backend — useful for UI work on a plane.

# 

# \---

# 

# \## API contract

# 

# Everything the app depends on. Money is in \*\*rupees\*\*, never paisa. Several numeric fields come back as \*\*strings\*\* (Postgres `numeric`), so the parsers are deliberately tolerant.

# 

# \### Auth

# | | |

# |---|---|

# | `POST /auth/otp/request` | `{phoneNumber}` → code printed to the backend console |

# | `POST /auth/otp/verify` | `{phoneNumber, otp}` → `{success, accessToken, user}` |

# | `PATCH /auth/profile` | `{fullName}` → updated user |

# | `GET /auth/me` | JWT payload only — \*not\* the full user record |

# 

# Token key is `accessToken`. Valid 7 days. `user.fullName == null` is how the app detects a new signup.

# 

# \### Properties (public)

# | | |

# |---|---|

# | `GET /properties` | array |

# | `GET /properties/:id` | one |

# | `GET /properties/:id/images` | `\[{imagePath}]` — Windows-style relative paths |

# 

# Image URLs are built as `apiBaseUrl + '/' + imagePath.replaceAll('\\', '/')`; files are served from `/uploads`.

# 

# \### Wallet · Investments · Marketplace · KYC

# | | |

# |---|---|

# | `GET /wallet` | `{balance, currency}` |

# | `POST /wallet/deposit` · `POST /wallet/withdraw` | `{amountPkr}` → new balance |

# | `GET /wallet/transactions` | `\[{type, amountPkr, description, createdAt}]` |

# | `POST /investments` | `{propertyId, shares}` — deducts the wallet |

# | `GET /investments` | raw records; \*\*sales are stored as negative rows\*\* |

# | `POST /marketplace/listings` | `{propertyId, shares, pricePerShare}` |

# | `GET /marketplace/listings` | open listings, optional `?propertyId=` |

# | `DELETE /marketplace/listings/:id` | cancel |

# | `POST /marketplace/listings/:id/buy` | 1.5% exit fee deducted from the seller |

# | `GET /kyc/status` | `not\_started` \\| `pending` \\| `approved` \\| `rejected` |

# | `POST /kyc/submit` | multipart: `cnicNumber`, `fullNameOnCnic`, `cnicImage`, `selfieImage` |

# 

# There is no `/portfolio` endpoint — the app aggregates `GET /investments` by `propertyId` client-side.

# 

# \---

# 

# \## Gotchas worth knowing

# 

# \- \*\*CORS.\*\* The backend must allow the app's origin. Development uses `origin: '\*'` in `main.ts`. Lock this down before shipping.

# \- \*\*Numbers as strings.\*\* `sharePricePkr`, `expectedYieldPct`, `amountPkr` and friends arrive as strings. Parse, don't cast.

# \- \*\*Sales are negative investments.\*\* `sharesPurchased: -5`. Summing gives the true position; anything iterating raw records must handle the sign.

# \- \*\*Fields the API doesn't return yet.\*\* `type`, `fundingDeadline`, `holdingPeriod`, `shariah`, `highlights`, `documents`, `fees`, `investors`, `occupancy`, `projectedAppreciation` are defaulted in `Property.fromJson`. The UI renders, but those values aren't real yet.

# \- \*\*Fonts are bundled\*\*, not fetched at runtime — `assets/fonts/`, declared in `pubspec.yaml`.

# \- \*\*Kotlin incremental compilation is off\*\* (`android/gradle.properties`). Windows can't compute relative paths between the pub cache on `C:` and a project on `D:`, which crashes the Kotlin daemon.

# 

# \---

# 

# \## What works

# 

# Phone/OTP auth with persisted sessions · new-user profile setup · property browsing with real images and OpenStreetMap locations · KYC capture, upload, admin review, and invest-gating · wallet deposits, withdrawals and transaction history · share purchase against the wallet · portfolio aggregation · secondary marketplace (list, browse, buy, cancel) with exit fees · an activity feed derived from real account events.

# 

# \## What's not done

# 

# \- \*\*Not deployed.\*\* The backend runs on a laptop. The app only works on the same Wi-Fi.

# \- \*\*Payments are simulated.\*\* Deposits are ledger entries, not money. Real deposits need a licensed Pakistani gateway (Safepay / PayFast / JazzCash / Easypaisa / Raast), webhooks, and custody that isn't a personal bank account.

# \- \*\*Not regulated.\*\* Taking public money to invest in property is an SECP matter. That's a lawyer conversation, not a code one.

# \- \*\*Dark mode is parked.\*\* Palette and plumbing exist; roughly two thirds of screens still hardcode light surfaces, so enabling it renders white-on-white. See the comment in `main.dart`.

# \- \*\*Google/Apple/email sign-in\*\* are placeholders.

# \- \*\*No tests, no error monitoring.\*\*

# \- \*\*Untested at scale\*\* — no concurrent-purchase testing, no load testing.

# 

# \---

# 

# \## Design system

# 

# Brand `#0C5A4E` · deep `#073E36` · ink `#14231F` · accent `#2FA39A` · gold `#E2A33B`. Plus Jakarta Sans for headings, Inter for body. Cards 16–24px radius, pills 999. Full tokens in `lib/theme.dart`.

