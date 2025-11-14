# Dotenv Variables Actually Used in the Codebase

This document lists all environment variables that are actually accessed in the codebase using `dotenv.env['...']` or `dotenv.get('...')`.

## Variables Used

### Monerium Integration
- **MONERIUM_CLIENT_ID** - Used in `lib/services/monerium/monerium_auth_service.dart`
- **MONERIUM_CLIENT_SECRET** - Used in `lib/services/monerium/monerium_auth_service.dart`
- **MONERIUM_REDIRECT_URI** - Used in `lib/services/monerium/monerium_auth_service.dart` (default: 'rimba://monerium')
- **MONERIUM_BASE_URL** - Used in `lib/services/monerium/monerium_auth_service.dart` (default: 'https://api.monerium.dev')

### WalletConnect
- **WALLETCONNECT_PROJECT_ID** - Used in `lib/services/wallet/wallet_service.dart`

### API Base URLs
- **CHECKOUT_API_BASE_URL** - Used in multiple payment-related services:
  - `lib/services/pay/payments.dart`
  - `lib/services/pay/interactions.dart`
  - `lib/services/pay/profile.dart`
  - `lib/services/pay/transactions.dart`
  - `lib/services/pay/transactions_with_user.dart`
  - `lib/services/pay/places.dart`
  - `lib/services/pay/orders.dart`
  - `lib/services/pay/cards.dart`

- **RIMBA_API_BASE_URL** - Used in:
  - `lib/services/request/requests.dart`
  - `lib/services/groups/groups.dart`
  - `lib/services/groups/group_members.dart`

- **SESSION_API_BASE_URL** - Used in `lib/services/session/session.dart`

### App Configuration
- **APP_REDIRECT_DOMAIN** - Used in:
  - `lib/state/topup.dart`
  - `lib/screens/home/screen.dart`
  - `lib/routes/home_shell.dart`
  - `lib/widgets/account_card.dart`
  - `lib/utils/qr.dart`

- **APP_ALIAS** - Used in `lib/services/session/session.dart`

- **DEFAULT_COMMUNITY_ALIAS** - Used in `lib/models/wallet.dart`

### Domain Configuration
- **CHECKOUT_DOMAIN** - Used in `lib/utils/qr.dart`
- **CARD_DOMAIN** - Used in:
  - `lib/utils/qr.dart`
  - `lib/state/scanner.dart`

### Routing
- **DEEPLINK_DOMAINS** - Used in `lib/routes/router.dart` (comma-separated list)

## Variables in .example.env but NOT Used
- **DASHBOARD_API_BASE_URL** - Listed in `.example.env` but not found in codebase
- **ORIGIN_HEADER** - Listed in `.example.env` but only found in commented-out code in `lib/services/nfc/nfc.dart`
- **DEFAULT_PHONE_COUNTRY_CODE** - Listed in `.example.env` but not found in codebase

## Summary
**Total variables actually used: 15**

1. MONERIUM_CLIENT_ID
2. MONERIUM_CLIENT_SECRET
3. MONERIUM_REDIRECT_URI
4. MONERIUM_BASE_URL
5. WALLETCONNECT_PROJECT_ID
6. CHECKOUT_API_BASE_URL
7. RIMBA_API_BASE_URL
8. SESSION_API_BASE_URL
9. APP_REDIRECT_DOMAIN
10. APP_ALIAS
11. DEFAULT_COMMUNITY_ALIAS
12. CHECKOUT_DOMAIN
13. CARD_DOMAIN
14. DEEPLINK_DOMAINS

