# Architecture and Database Documentation

## Repository Rules Summary

The project follows a well-structured Flutter architecture with these key principles:

### **UI Framework**
- **Cupertino widgets only** - No Material Design components
- **Colors**: Defined as constants in `lib/theme` for global import
- **Modals**: Use `showCupertinoDialog` or `showCupertinoModalPopup` from `lib/widgets/modals/dismissible_modal_popup.dart`

### **Architecture Patterns**
- **Routing**: GoRouter in `lib/routes/router` with state management
- **State Management**: Provider pattern in `lib/state` (preferred over local state)
- **Services**: All external packages/APIs in `lib/services`
- **Models**: App-specific models in `lib/models`, service-specific models with services
- **Screens**: Organized in `lib/screens` following routing structure
- **Widgets**: Reusable components in `lib/widgets`

### **State Management Rules**
- **Provider over local state** - Use Provider for most state management
- **Service calls only from state** - Never call services directly from widgets
- **Scoped state** - State defined under routes or modals
- **Local state only** for self-contained widgets (animations, hiding widgets)

## Database Structure

The app uses **SQLite** with a well-designed abstract database architecture:

### **Database Architecture**
- **Abstract base classes**: `DBService` and `DBTable` in `lib/services/db/db.dart`
- **Concrete implementation**: `AppDBService` in `lib/services/db/app/db.dart`
- **Version management**: Database version 14 with migration support
- **Cross-platform**: Supports both mobile and web (using `sqflite_common_ffi_web`)

### **Database Tables**

#### 1. **`t_contacts`** - User and place contacts
```sql
CREATE TABLE t_contacts (
  account TEXT PRIMARY KEY,
  username TEXT NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  profile TEXT,
  place TEXT
)
```
- Stores user profiles and place information
- Supports both user and place contact types
- Indexed by account and username
- JSON serialization for profile and place data

#### 2. **`t_transactions`** - Financial transactions
```sql
CREATE TABLE t_transactions (
  id TEXT PRIMARY KEY,
  tx_hash TEXT NOT NULL,
  contract TEXT NOT NULL,
  from_account TEXT NOT NULL,
  to_account TEXT NOT NULL,
  amount TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL,
  created_at TEXT NOT NULL
)
```
- Blockchain transaction records
- Supports multiple contracts/tokens
- Efficient querying between users
- Status tracking (pending, success, fail)
- Composite indexes for user-to-user transactions

#### 3. **`preference`** - App preferences
```sql
CREATE TABLE preference (
  key TEXT PRIMARY KEY,
  created_at TEXT,
  updated_at TEXT,
  value TEXT
)
```
- Simple key-value storage
- Timestamp tracking for preferences

### **Key Database Features**

#### **Migration System**
- Version-controlled schema changes
- Graceful error handling during migrations
- Support for complex schema updates
- Current database version: 14

#### **Performance Optimization**
- Comprehensive indexing strategy
- Composite indexes for complex queries
- Optimized for common query patterns
- Efficient pagination support

#### **Data Integrity**
- Proper primary key constraints
- Foreign key relationships
- Conflict resolution with `REPLACE` algorithm
- Transaction support for batch operations

#### **Cross-Platform Support**
- Mobile: Standard SQLite
- Web: SQLite via WebAssembly (`sqflite_common_ffi_web`)
- Shared worker support for web performance

### **Database Operations**

#### **Common Patterns**
- **Upsert operations**: Use `ConflictAlgorithm.replace` for idempotent operations
- **Batch operations**: Support for bulk inserts/updates
- **Pagination**: Built-in limit/offset support
- **Filtering**: Comprehensive where clause support

#### **Query Optimization**
- Indexed lookups for primary keys
- Composite indexes for multi-column queries
- Efficient sorting with indexed columns
- Optimized for time-based queries (created_at, last_message_at)

### **Data Models**

The database works with several key data models:

- **`DBContact`**: Contact information with profile/place data
- **`Transaction`**: Blockchain transaction records
- **`Preference`**: Simple key-value preferences

### **Usage Guidelines**

1. **Always use the abstract base classes** for new tables
2. **Implement proper migration logic** for schema changes
3. **Use batch operations** for multiple inserts/updates
4. **Leverage indexes** for performance-critical queries
5. **Handle JSON serialization** properly for complex data types
6. **Use transactions** for operations that must be atomic

This database structure supports a streamlined payment app with user management and blockchain transaction tracking.
