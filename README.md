# Ramadan Meal Distribution App

## Project Overview
A mobile application to manage and streamline Ramadan meal distribution for two user roles:
- **Administrators**: Full control over cases, filtering, data export, meal preparation tracking, expense logging, and reports.
- **Donors**: View curated content (image carousel, daily meal details), cumulative feeding statistics, historical meal records, and make donations.

---

## Table of Contents
1. [Administrator Features](#administrator-features)  
   1.1 [Main Screen (TabBar)](#main-screen-tabbar)  
   1.2 [Cases Tab](#cases-tab)  
   1.3 [Control Panel Tab](#control-panel-tab)  
   1.4 [Statistics Screen](#statistics-screen)  
   1.5 [Expenses Screen](#expenses-screen)  
   1.6 [Reports Screen](#reports-screen)  
2. [Donor Features](#donor-features)  
   2.1 [Main Screen](#main-screen)  
   2.2 [Statistics Screen](#statistics-screen-1)  
   2.3 [Past Days Screen](#past-days-screen)  
   2.4 [Reports Screen](#reports-screen-1)  
3. [Getting Started](#getting-started)  
4. [Export & Data Management](#export--data-management)  
5. [Appendices](#appendices)

---

## Administrator Features

### Main Screen (TabBar)
- **Tabs:**  
  1. **Cases**  
  2. **Control Panel**

### Cases Tab
- **Case List**  
  - Name, Bag ID, Family Size  
  - Distribution Status (Done/Pending)  
  - Bag Availability (Here/Not Here)
- **Actions:**  
  - **Filter** by status (Ready to Distribute, Bag Here), group, family size, or all  
  - **Start New Day** — resets daily statistics  
  - **Export to Excel** — exports current case data  
  - **Manage Cases** — CRUD operations and view full family details (ID photo, contact, ages)

### Control Panel Tab
- **Carousel** of images/promotions  
- **Daily Meal Display**  
  - Date & Day  
  - Meal Title & Description  
  - Expected Number of Recipients  
- **Notifications**  
- **Donation Payment Info**  
  - List existing payment methods  
  - Add new payment info

### Statistics Screen
- **Tab 1: Real-Time & Daily Metrics**  
  - Total fed today  
  - Prepared meals  
  - Remaining meals  
  - Fulfillment percentage  
- **Tab 2: Cumulative Animated Progress**  
  - Engaging animation showing total fed since start of Ramadan

### Expenses Screen
- **Fields:**  
  - Product Category → Product → Unit  
  - Quantity → Unit Price → Payment Status (Paid/Unpaid)

### Reports Screen
- **Tab 1: Daily Expense Invoices**  
  - One “invoice” per day: date, total spent, list of purchased items  
- **Tab 2: Aggregated Quantities**  
  - Total purchased per product across days  
  - Purchase frequency details (date/time of each buy)

---

## Donor Features

### Main Screen
- Mirrors Admin’s carousel & daily meal info  
- View notifications, donation contact methods, and logout

### Statistics Screen
- Displays total individuals fed since Ramadan began (static or animated)

### Past Days Screen
- List of previous days, each linking to that day’s meal details

### Reports Screen
- Full access to expense and quantity reports like Admin view

---

## 4. Getting Started
1. Clone repo:
   ```bash
   git clone https://github.com/yourusername/ramadan-kitchen-app.git
   cd ramadan-kitchen-app
   ```
2. Install dependencies: `flutter pub get`
3. Configure Firebase: `flutterfire configure`
4. Add Cloudinary keys in `lib/core/private/private.dart`
5. Run: `flutter run`

## 5. Configuration
- Firebase: place `google-services.json` & `GoogleService-Info.plist`, run `flutterfire configure`
- Cloudinary: set credentials in `lib/core/private/private.dart`
- API endpoints: update `lib/core/constants/backend_endpoints.dart`

## 6. Usage
- **Admin**: navigate tabs to manage cases, expenses, reports, stats
- **Donor**: explore meals, view stats, check past days, read reports

## 7. Testing
- Unit & widget tests: `flutter test`
- Integration: `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart`

## 8. CI / CD
GitHub Actions (`.github/workflows/flutter.yml`): lint, test on PR; build APK/IPA on merge

## 9. Contributing
1. Fork & branch (`git checkout -b feat/...`)
2. Commit with Conventional Commits
3. Push & open PR

## 10. License
MIT — see [LICENSE](LICENSE)

## 11. Acknowledgements
Flutter, Dart, Firebase, Material Design Icons — inspired by community Ramadan kitchen initiatives.

Built with ❤️ by Hamdy Haggag.

