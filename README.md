# Ramadan Meal Managment App

## Project Overview
A mobile application to manage and streamline Ramadan meal distribution for two user roles:
- **Administrators**: Full control over cases, filtering, data export, meal preparation tracking, expense logging, and reports.
- **Donors**: View curated content (image carousel, daily meal details), cumulative feeding statistics, historical meal records, and make donations.

---

## Table of Contents
1. [Screenshots](#screenshots)  
2. [Administrator Features](#administrator-features)  
&nbsp;&nbsp;&nbsp;2.1 [Main Screen (TabBar)](#main-screen-tabbar)  
&nbsp;&nbsp;&nbsp;2.2 [Cases Tab](#cases-tab)  
&nbsp;&nbsp;&nbsp;2.3 [Control Panel Tab](#control-panel-tab)  
&nbsp;&nbsp;&nbsp;2.4 [Statistics Screen](#statistics-screen-admin)  
&nbsp;&nbsp;&nbsp;2.5 [Expenses Screen](#expenses-screen)  
&nbsp;&nbsp;&nbsp;2.6 [Reports Screen](#reports-screen-admin)  
3. [Donor Features](#donor-features)  
&nbsp;&nbsp;&nbsp;3.1 [Main Screen](#main-screen-donor)  
&nbsp;&nbsp;&nbsp;3.2 [Statistics Screen](#donor-statistics-screen)  
&nbsp;&nbsp;&nbsp;3.3 [Past Days Screen](#past-days-screen)  
&nbsp;&nbsp;&nbsp;3.4 [Reports Screen](#donor-reports-screen)  
4. [Getting Started](#getting-started)  
5. [Export & Data Management](#export--data-management)  
6. [Appendices](#appendices)

---

## <a name="screenshots"></a>Screenshots

To help visualize each feature of the Ramadan Meal Distribution App, below is a professionally numbered grid of screenshots organized by user role.

### Administrator Features

| # | Feature                               | Screenshot                                           |
|---|---------------------------------------|------------------------------------------------------|
| 1 | Main Screen (TabBar)                  | ![1. Main Screen](screenshots/admin-main-screen.png) |
| 2 | Cases Tab                             | ![2. Cases Tab](screenshots/admin-cases-tab.png)     |
| 3 | Control Panel Tab                     | ![3. Control Panel](screenshots/admin-control-panel.png) |
| 4 | Statistics Screen                     | ![4. Statistics Screen](screenshots/admin-statistics.png) |
| 5 | Expenses Screen                       | ![5. Expenses Screen](screenshots/admin-expenses.png) |
| 6 | Reports Screen                        | ![6. Reports Screen](screenshots/admin-reports.png)  |

### Donor Features

| # | Feature                 | Screenshot                                         |
|---|-------------------------|----------------------------------------------------|
| 1 | Main Screen             | ![1. Donor Main](screenshots/donor-main-screen.png) |
| 2 | Statistics Screen       | ![2. Donor Statistics](screenshots/donor-statistics.png) |
| 3 | Past Days Screen        | ![3. Past Days](screenshots/donor-past-days.png)   |
| 4 | Reports Screen          | ![4. Donor Reports](screenshots/donor-reports.png) |

---

## <a name="administrator-features"></a>Administrator Features

### <a name="main-screen-tabbar"></a>Main Screen (TabBar)
- **Tabs:**  
  1. **Cases**  
  2. **Control Panel**

### <a name="cases-tab"></a>Cases Tab
- **Case List**  
  - Name, Bag ID, Family Size  
  - Distribution Status (Done/Pending)  
  - Bag Availability (Here/Not Here)
- **Actions:**  
  - **Filter** by status (Ready to Distribute, Bag Here), group, family size, or all  
  - **Start New Day** — resets daily statistics  
  - **Export to Excel** — exports current case data  
  - **Manage Cases** — CRUD operations and view full family details (ID photo, contact, ages)

### <a name="control-panel-tab"></a>Control Panel Tab
- **Carousel** of images/promotions  
- **Daily Meal Display**  
  - Date & Day  
  - Meal Title & Description  
  - Expected Number of Recipients
- **Notifications**  
- **Donation Payment Info**  
  - List existing payment methods  
  - Add new payment info

### <a name="statistics-screen-admin"></a>Statistics Screen
- **Tab 1: Real-Time & Daily Metrics**  
  - Total fed today  
  - Prepared meals  
  - Remaining meals  
  - Fulfillment percentage
- **Tab 2: Cumulative Animated Progress**  
  - Engaging animation showing total fed since start of Ramadan

### <a name="expenses-screen"></a>Expenses Screen
- **Fields:**  
  - Product Category → Product → Unit  
  - Quantity → Unit Price → Payment Status (Paid/Unpaid)

### <a name="reports-screen-admin"></a>Reports Screen
- **Tab 1: Daily Expense Invoices**  
  - One “invoice” per day: date, total spent, list of purchased items  
- **Tab 2: Aggregated Quantities**  
  - Total purchased per product across days  
  - Purchase frequency details (date/time of each buy)

---

## <a name="donor-features"></a>Donor Features

### <a name="main-screen-donor"></a>Main Screen
- Mirrors Admin’s carousel & daily meal info  
- View notifications, donation contact methods, and logout

### <a name="donor-statistics-screen"></a>Statistics Screen
- Displays total individuals fed since Ramadan began (static or animated)

### <a name="past-days-screen"></a>Past Days Screen
- List of previous days, each linking to that day’s meal details

### <a name="donor-reports-screen"></a>Reports Screen
- Full access to expense and quantity reports like Admin view

---

## <a name="getting-started"></a>Getting Started
1. Clone repo:
   ```bash
   git clone https://github.com/yourusername/ramadan-kitchen-app.git
   cd ramadan-kitchen-app
   ```
2. Install dependencies: `flutter pub get`
3. Configure Firebase: `flutterfire configure`
4. Add Cloudinary keys in `lib/core/private/private.dart`
5. Run: `flutter run`

## <a name="export--data-management"></a>Export & Data Management
- Use the Export to Excel action in the Cases Tab for case data  
- Reports Screen provides CSV/PDF exports for daily invoices and aggregated quantities

## <a name="appendices"></a>Appendices
- **CI/CD:** GitHub Actions (`.github/workflows/flutter.yml`) for linting, testing, and building APK/IPA
- **Testing:** `flutter test` for unit & widget tests, `flutter drive` for integration tests
- **License:** MIT — see [LICENSE](LICENSE)
- **Acknowledgements:** Flutter, Dart, Firebase, Material Design Icons — inspired by community Ramadan kitchen initiatives.

*Built with ❤️ by Hamdy Haggag.*

