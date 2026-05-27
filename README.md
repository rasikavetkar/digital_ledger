# Digital Ledger - Sand Transport Logistics Application

A powerful cross-platform Flutter application for tracking sand transport logistics, functioning as a digital account book (like KhataBook) for managing vehicle owners, their vehicles, and financial transactions with PDF invoice generation.

## Features

### ✨ Core Features
- **Party Management**: Add, view, and manage vehicle owners (parties) with contact information
- **Vehicle Tracking**: Track multiple vehicles per party with vehicle type classification
- **Transaction Ledger**: Record credit/debit transactions for each vehicle with detailed tracking
- **Financial Summary**: View party-wise balance, overall statistics, and transaction history
- **PDF Invoice Generation**: Generate and share party-wise ledger reports in PDF format
- **Offline-First**: Works completely offline without internet requirement
- **Indian Format Support**: Amounts displayed in Indian Rupee format (₹1,23,456)

### 📊 Dashboard Screens

#### HomeScreen
- Bottom Navigation Bar with 4 tabs: Ledger, Parties, Vehicles, Summary
- Floating Action Button for quick entry addition
- Clean navigation between all features

#### LedgerScreen
- Summary cards showing Total Credit, Total Debit, and Balance
- Real-time search by vehicle number
- Filter chips for All/Credit/Debit transactions
- Expandable transaction tiles with detailed view
- Empty state with helpful guidance

#### PartiesScreen
- Party count and quick add button
- Party cards showing:
  - Avatar with initials
  - Vehicle count and trip count
  - Credit/Debit breakdown
  - Net balance (color-coded)
  - PDF export button
- Navigation to party detail screen

#### VehiclesScreen
- Search functionality for vehicle numbers
- Vehicle cards with:
  - Vehicle type icon
  - Owner name
  - Trip count and total loads
  - Quick add vehicle button
- Validation to ensure parties exist before adding vehicles

#### SummaryScreen
- 2×2 grid of overall statistics
  - Total Credit
  - Total Debit
  - Net Balance
  - Total Loads
- Party-wise balance ranking
- Outstanding balance visualization
- PDF export for each party

### 🎯 Data Models

#### Party
- Auto-incrementing ID (primary key)
- Name (required)
- Phone (optional)
- Created timestamp

#### Vehicle
- Auto-incrementing ID (primary key)
- Vehicle number (unique, auto-uppercased)
- Party ID (foreign key with cascade delete)
- Type: Truck, Tractor, Tipper, or Other
- Created timestamp

#### Transaction
- Auto-incrementing ID (primary key)
- Vehicle ID (foreign key with cascade delete)
- Date (customizable, defaults to today)
- Quantity (number of sand loads)
- Amount (in Rupees)
- Type: Credit (Jama) or Debit (Udhaar)
- Remarks (optional)
- Created timestamp

### 💾 Database

SQLite database (`digital_ledger.db`) with:
- Foreign key constraints with cascade delete
- Proper indexing for performance:
  - `idx_vehicle_party` on vehicles(partyId)
  - `idx_transaction_vehicle` on transactions(vehicleId)
  - `idx_transaction_date` on transactions(date)
- Aggregate queries for financial summaries
- Thread-safe singleton database helper

### 🏗️ Architecture

#### State Management (Provider)
- **PartyProvider**: Manages party list, add, delete, update operations
- **VehicleProvider**: Manages vehicle list with party filtering and search
- **TransactionProvider**: Manages transactions with advanced filtering and computed balances

#### Services
- **DatabaseHelper**: SQLite database operations with full CRUD
- **PdfService**: PDF generation with professional formatting

#### Utilities
- **Theme**: Consistent UI with Indian business colors
  - Primary: `#185FA5` (Blue)
  - Credit: `#3B6D11` on `#EAF3DE` (Green)
  - Debit: `#A32D2D` on `#FCEBEB` (Red)
- **Formatters**: 
  - Indian currency format (₹1,23,456)
  - Date formatting (15 Jun 24)
  - Vehicle number uppercase conversion

### 📱 UI Components

#### Widgets
- **StatCard**: Display financial metrics with icons and colors
- **TransactionTile**: Expandable transaction card with details and delete
- **PartyCard**: Party overview with stats and PDF button
- **VehicleCard**: Vehicle details with trip and load information

#### Modal Sheets
- **AddTransactionSheet**: Full entry form with date picker, party/vehicle dropdowns, type toggle, quantity, amount, remarks
- **AddPartySheet**: Simple party creation with name and optional phone
- **AddVehicleSheet**: Vehicle creation with number, party selection, and type dropdown

### 🎨 Design System
- Material 3 Design principles
- Google Fonts (Nunito font family)
- Rounded corners (8-12px border radius)
- Consistent spacing and padding
- Color-coded financial indicators
- Responsive grid layouts

### 📖 Key Behaviors
- All amounts in Indian format with ₹ symbol
- Dates displayed as "15 Jun 24"
- Vehicle numbers auto-uppercased on input
- Cascading deletes: Removing party deletes vehicles and transactions
- Search debounced for performance
- Confirmation dialogs for destructive actions
- Snackbar feedback for user actions

## Project Structure

```
lib/
  main.dart                      # App entry point with providers
  models/
    party.dart                   # Party data model
    vehicle.dart                 # Vehicle data model
    transaction.dart             # Transaction data model
  providers/
    party_provider.dart          # Party state management
    vehicle_provider.dart        # Vehicle state management
    transaction_provider.dart    # Transaction state management
  db/
    database_helper.dart         # SQLite database operations
  screens/
    home_screen.dart             # Main shell with bottom nav
    ledger_screen.dart           # Transaction ledger view
    parties_screen.dart          # Party management
    vehicles_screen.dart         # Vehicle management
    summary_screen.dart          # Financial summary
    party_detail_screen.dart     # Party details and transactions
  widgets/
    stat_card.dart               # Statistics display card
    transaction_tile.dart        # Expandable transaction item
    party_card.dart              # Party card component
    vehicle_card.dart            # Vehicle card component
    add_transaction_sheet.dart   # Transaction input form
    add_party_sheet.dart         # Party creation form
    add_vehicle_sheet.dart       # Vehicle creation form
  services/
    pdf_service.dart             # PDF generation and sharing
  utils/
    theme.dart                   # App theme and colors
    formatters.dart              # Text and number formatting
```

## Technologies Used

### Core Framework
- **Flutter**: Cross-platform mobile development
- **Dart**: Programming language

### State Management
- **Provider 6.1.5+**: Efficient state management and dependency injection

### Database
- **SQLite (sqflite)**: Local persistent storage
- **Path**: File path utilities

### UI & Styling
- **Google Fonts**: Typography with Nunito font family
- **Material Design 3**: Modern UI components

### PDF & Sharing
- **pdf 3.11.3**: PDF document generation
- **printing 5.14.3**: Printing and PDF sharing
- **share_plus 7.2.1**: Native share functionality

### Utilities
- **intl 0.20.2**: Internationalization and number formatting

## Getting Started

### Prerequisites
- Flutter SDK 3.6.1 or higher
- Android SDK (for Android builds)
- Xcode (for iOS builds)

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd digital_ledger
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
flutter run
```

### Build for Production

#### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

## Usage Guide

### Adding a Party
1. Go to Parties screen
2. Tap "Add Party" button
3. Enter party name and optional phone
4. Save

### Adding a Vehicle
1. Go to Vehicles screen
2. Tap "Add Vehicle" button
3. Select party owner, enter vehicle number, select vehicle type
4. Save

### Recording a Transaction
1. Tap the + FAB from any screen
2. Select or leave blank party (optional)
3. Select vehicle
4. Choose Credit or Debit
5. Enter quantity (number of loads) and amount
6. Add optional remarks
7. Save

### Viewing Party Summary
1. Go to Parties screen
2. Tap on a party card
3. View vehicles, transactions, and balance details

### Generating PDF Reports
1. Go to Parties screen or Summary screen
2. Tap PDF button on a party card
3. Choose action: Save, Share, Print, or Email

## Data Persistence

All data is stored locally in SQLite database:
- **Location**: Device's app-specific documents directory
- **Database File**: `digital_ledger.db`
- **Auto-creation**: Database created on first launch
- **Backup**: Recommended to export and backup database regularly

## Offline Operation

The app is completely offline-capable:
- No internet connection required
- All data stored locally
- PDF generation works offline
- PDF sharing requires native share options

## Future Enhancements

- Monthly breakdown charts using fl_chart
- Image storage for invoices
- Party communication history
- Recurring transaction templates
- Data export to CSV/Excel
- Cloud backup integration
- Multi-user support
- Advanced reporting and analytics
- Voice transaction entry
- Bill splitting between parties

## License

This project is proprietary and confidential.

## Support

For issues or feature requests, contact the development team.

---

**Version**: 1.0.0  
**Last Updated**: May 2026
