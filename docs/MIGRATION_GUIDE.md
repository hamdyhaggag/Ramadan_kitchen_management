# 🗓️ Ramadan Seasons Migration Guide

## Overview
This guide explains how to migrate existing data to support the new Ramadan Seasons feature.

## Database Structure Changes

### New Collection: `ramadan_seasons`
```
ramadan_seasons/
├── {season_id}
│   ├── name: "رمضان 1447 هـ - 2026"
│   ├── hijriYear: "1447"
│   ├── gregorianYear: "2026"
│   ├── startDate: Timestamp
│   ├── endDate: Timestamp
│   ├── isActive: boolean
│   ├── isArchived: boolean
│   ├── createdAt: Timestamp
│   └── statistics: Map (optional, populated when archived)
```

### Modified Collections (new `seasonId` field)
- `cases` - Each case now has a `seasonId` field
- `caseGroups` - Each group now has a `seasonId` field
- `donations` - Each donation now has a `seasonId` field
- `expenses` - Each expense now has a `seasonId` field

---

## Migration Steps

### Step 1: Backup Existing Data
Before making any changes, ensure you have a backup of your Firestore data.

### Step 2: Create the First Season (for existing data)
Run this in Firebase Console > Firestore > ramadan_seasons > Add document:

```json
{
  "name": "رمضان 1446 هـ - 2025",
  "hijriYear": "1446",
  "gregorianYear": "2025",
  "startDate": "2025-03-01T00:00:00Z",
  "endDate": "2025-03-30T00:00:00Z",
  "isActive": false,
  "isArchived": true,
  "createdAt": "2025-03-01T00:00:00Z"
}
```

Note the document ID (e.g., `season_1446`).

### Step 3: Add seasonId to Existing Documents
In Firebase Console, for each collection, update existing documents to add the `seasonId` field.

#### Option A: Manual (for small datasets)
1. Go to each collection (cases, caseGroups, donations, expenses)
2. For each document, add field: `seasonId` = `{your_season_id_from_step_2}`

#### Option B: Using Firebase CLI (recommended for large datasets)
Create a migration script (`migrate_season.js`):

```javascript
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();
const SEASON_ID = 'YOUR_SEASON_ID_HERE'; // Replace with actual ID

async function migrateCollection(collectionName) {
  const snapshot = await db.collection(collectionName).get();
  const batch = db.batch();
  let count = 0;

  snapshot.docs.forEach(doc => {
    if (!doc.data().seasonId) {
      batch.update(doc.ref, { seasonId: SEASON_ID });
      count++;
    }
  });

  if (count > 0) {
    await batch.commit();
    console.log(`Updated ${count} documents in ${collectionName}`);
  } else {
    console.log(`No documents to update in ${collectionName}`);
  }
}

async function main() {
  await migrateCollection('cases');
  await migrateCollection('caseGroups');
  await migrateCollection('donations');
  await migrateCollection('expenses');
  console.log('Migration complete!');
}

main().catch(console.error);
```

### Step 4: Create New Season for Ramadan 1447
After migration, create the new season in the app:

1. Open the app as Admin
2. Go to "إدارة المواسم الرمضانية"
3. Click "موسم جديد"
4. Fill in:
   - Name: "رمضان 1447 هـ - 2026"
   - Hijri Year: 1447
   - Gregorian Year: 2026
   - Start Date: Expected start of Ramadan 2026
   - End Date: Expected end of Ramadan 2026
5. Check "نسخ الحالات والمجموعات من موسم سابق" if you want to copy cases
6. Click "إنشاء"

### Step 5: Activate the New Season
1. In the seasons list, find the new season
2. Click "تفعيل"
3. Confirm activation

---

## Firestore Security Rules Update
Add these rules to secure the new collection:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Existing rules...
    
    match /ramadan_seasons/{seasonId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

---

## Important Notes

1. **Data Isolation**: Each season's data is isolated. When you switch seasons, you only see that season's data.

2. **Copying Cases**: When creating a new season, you can optionally copy cases and groups from a previous season. This ONLY copies:
   - Cases (with `استلم` reset to false)
   - Case Groups
   
   It does NOT copy:
   - Donations
   - Expenses
   - Statistics/Reports

3. **Archiving**: When you archive a season, statistics are calculated and saved permanently. The season becomes read-only.

4. **User View**: Regular users can view archived seasons through the "سجل المواسم" screen.

---

## Rollback Plan
If something goes wrong:

1. The changes are in a separate git branch (`feature/ramadan-seasons`)
2. You can delete the branch and return to production code
3. The database changes can be reverted by removing the `seasonId` field from documents

---

## Testing Checklist
- [ ] Create a new season
- [ ] Activate the season
- [ ] Add a new case (verify seasonId is added)
- [ ] View cases (verify only current season's cases are shown)
- [ ] Create a donation (verify seasonId is added)
- [ ] Add an expense (verify seasonId is added)
- [ ] Archive a season
- [ ] View archived seasons as a user
- [ ] View season details (overview, meals, expenses tabs)
