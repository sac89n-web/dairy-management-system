# Database Setup Instructions

## Run the Complete Database Setup Script

**Script Location:** `scripts/complete_database_setup.sql`

### **Option 1: Using pgAdmin**
1. Open pgAdmin
2. Connect to your PostgreSQL server
3. Right-click on your `dairy_management` database
4. Select "Query Tool"
5. Open the file: `scripts/complete_database_setup.sql`
6. Click "Execute" (F5)

### **Option 2: Using Command Line**
```bash
# If psql is in PATH
psql -h localhost -U postgres -d dairy_management -f "scripts/complete_database_setup.sql"

# If psql is not in PATH, use full path (example)
"C:\Program Files\PostgreSQL\15\bin\psql.exe" -h localhost -U postgres -d dairy_management -f "scripts/complete_database_setup.sql"
```

### **Option 3: Copy and Paste**
1. Open the file `scripts/complete_database_setup.sql`
2. Copy all the SQL content
3. Paste it into your PostgreSQL query tool
4. Execute the script

## What This Script Does:

✅ **Adds Payment Status** to milk_collection table
✅ **Creates Payment Transactions** table for gateway
✅ **Creates Quality Tests** table for FSSAI compliance
✅ **Adds Sample Data** for demo purposes
✅ **Creates Indexes** for performance
✅ **Sets up Enhanced Features** for Dashboard and Payments

## After Running the Script:

1. **Restart the application**
2. **Clear browser cache** (Ctrl + F5)
3. **Visit enhanced pages:**
   - Dashboard: `https://localhost:5001/`
   - Payment Gateway: `https://localhost:5001/PaymentGateway`

## Expected Results:

**Dashboard Enhancements:**
- Advanced metric cards with growth indicators
- Top farmers leaderboard
- Quality score tracking
- Interactive trend charts

**Payment Gateway Enhancements:**
- 4-card payment metrics layout
- Payment method distribution charts
- Weekly payment analytics
- Professional UI with icons

The script will show success messages when completed successfully.