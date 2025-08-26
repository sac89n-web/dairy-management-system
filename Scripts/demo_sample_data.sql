-- Demo Sample Data for Dairy Management System
-- Run this script to populate the database with realistic demo data

-- Insert sample farmers
INSERT INTO dairy.farmer (name, code, contact, email, address, village, taluka, district, state, pincode, bank_name, account_number, ifsc_code, aadhar_number, pan_number, branch_id, is_active) VALUES
('राम शर्मा', 'F001', '9876543210', 'ram.sharma@example.com', 'गांव रोड, मुख्य चौक के पास', 'रामपुर', 'शिरूर', 'पुणे', 'महाराष्ट्र', '412208', 'State Bank of India', '12345678901234', 'SBIN0001234', '123456789012', 'ABCDE1234F', 1, true),
('सुनील पाटील', 'F002', '9876543211', 'sunil.patil@example.com', 'मेन रोड, बस स्टॉप के पास', 'पाटिलगांव', 'शिरूर', 'पुणे', 'महाराष्ट्र', '412209', 'Bank of Maharashtra', '23456789012345', 'MAHB0001235', '234567890123', 'BCDEF2345G', 1, true),
('अनिल कुलकर्णी', 'F003', '9876543212', 'anil.kulkarni@example.com', 'स्कूल रोड, मंदिर के सामने', 'कुलकर्णीवाडी', 'शिरूर', 'पुणे', 'महाराष्ट्र', '412210', 'HDFC Bank', '34567890123456', 'HDFC0001236', '345678901234', 'CDEFG3456H', 1, true),
('विजय जाधव', 'F004', '9876543213', 'vijay.jadhav@example.com', 'कॉलेज रोड, पार्क के पास', 'जाधवगांव', 'शिरूर', 'पुणे', 'महाराष्ट्र', '412211', 'ICICI Bank', '45678901234567', 'ICIC0001237', '456789012345', 'DEFGH4567I', 1, true),
('संजय देशमुख', 'F005', '9876543214', 'sanjay.deshmukh@example.com', 'हॉस्पिटल रोड, क्लिनिक के पास', 'देशमुखगांव', 'शिरूर', 'पुणे', 'महाराष्ट्र', '412212', 'Axis Bank', '56789012345678', 'UTIB0001238', '567890123456', 'EFGHI5678J', 1, true),
('प्रकाश मोरे', 'F006', '9876543215', 'prakash.more@example.com', 'मार्केट यार्ड, दुकान नं. 5', 'मोरेगांव', 'शिरूर', 'पुणे', 'महाराष्ट्र', '412213', 'Punjab National Bank', '67890123456789', 'PUNB0001239', '678901234567', 'FGHIJ6789K', 1, true),
('राजेश भोसले', 'F007', '9876543216', 'rajesh.bhosale@example.com', 'रेल्वे स्टेशन रोड', 'भोसलेगांव', 'शिरूर', 'पुणे', 'महाराष्ट्र', '412214', 'Canara Bank', '78901234567890', 'CNRB0001240', '789012345678', 'GHIJK7890L', 1, true),
('महेश गायकवाड', 'F008', '9876543217', 'mahesh.gaikwad@example.com', 'पेट्रोल पंप के पास', 'गायकवाडगांव', 'शिरूर', 'पुणे', 'महाराष्ट्र', '412215', 'Union Bank', '89012345678901', 'UBIN0001241', '890123456789', 'HIJKL8901M', 1, true),
('दिनेश शिंदे', 'F009', '9876543218', 'dinesh.shinde@example.com', 'पोस्ट ऑफिस रोड', 'शिंदेगांव', 'शिरूर', 'पुणे', 'महाराष्ट्र', '412216', 'Indian Bank', '90123456789012', 'IDIB0001242', '901234567890', 'IJKLM9012N', 1, true),
('अशोक काळे', 'F010', '9876543219', 'ashok.kale@example.com', 'बाजार पेठ, दुकान नं. 12', 'काळेगांव', 'शिरूर', 'पुणे', 'महाराष्ट्र', '412217', 'Central Bank', '01234567890123', 'CBIN0001243', '012345678901', 'JKLMN0123O', 1, true)
ON CONFLICT (code) DO NOTHING;

-- Insert sample customers
INSERT INTO dairy.customer (name, contact, email, address, city, state, pincode, gst_number, customer_type, branch_id, is_active) VALUES
('सुनील ट्रेडर्स', '9876543220', 'sunil.traders@example.com', 'मार्केट यार्ड, दुकान नं. 15', 'पुणे', 'महाराष्ट्र', '411001', '27ABCDE1234F1Z5', 'Retailer', 1, true),
('राज होटल', '9876543221', 'raj.hotel@example.com', 'एमजी रोड, होटल कॉम्प्लेक्स', 'पुणे', 'महाराष्ट्र', '411002', '27BCDEF2345G2Z6', 'Hotel/Restaurant', 1, true),
('श्री गणेश डेअरी', '9876543222', 'ganesh.dairy@example.com', 'कैंप एरिया, शॉप नं. 8', 'पुणे', 'महाराष्ट्र', '411003', '27CDEFG3456H3Z7', 'Distributor', 1, true),
('प्रिया रेस्टॉरंट', '9876543223', 'priya.restaurant@example.com', 'एफसी रोड, रेस्टॉरंट कॉम्प्लेक्स', 'पुणे', 'महाराष्ट्र', '411004', '27DEFGH4567I4Z8', 'Hotel/Restaurant', 1, true),
('महाराष्ट्र मिल्क फेडरेशन', '9876543224', 'maharashtra.milk@example.com', 'शिवाजीनगर, ऑफिस कॉम्प्लेक्स', 'पुणे', 'महाराष्ट्र', '411005', '27EFGHI5678J5Z9', 'Corporate', 1, true)
ON CONFLICT (contact) DO NOTHING;

-- Insert sample shifts
INSERT INTO dairy.shift (name, start_time, end_time, branch_id) VALUES
('Morning', '06:00:00', '10:00:00', 1),
('Evening', '16:00:00', '20:00:00', 1)
ON CONFLICT (name, branch_id) DO NOTHING;

-- Insert sample milk collections
INSERT INTO dairy.milk_collection (farmer_id, shift_id, qty_ltr, fat_pct, snf_pct, price_per_ltr, due_amt, date, payment_status, branch_id) VALUES
(1, 1, 25.5, 4.2, 8.5, 45.00, 1147.50, CURRENT_DATE, 'Pending', 1),
(2, 1, 18.0, 3.8, 8.2, 42.00, 756.00, CURRENT_DATE, 'Pending', 1),
(3, 1, 32.0, 4.5, 8.8, 48.00, 1536.00, CURRENT_DATE, 'Paid', 1),
(4, 1, 22.5, 4.0, 8.3, 44.00, 990.00, CURRENT_DATE, 'Pending', 1),
(5, 1, 28.0, 4.3, 8.6, 46.00, 1288.00, CURRENT_DATE, 'Pending', 1),
(1, 2, 20.0, 4.1, 8.4, 44.50, 890.00, CURRENT_DATE, 'Pending', 1),
(2, 2, 15.5, 3.9, 8.1, 43.00, 666.50, CURRENT_DATE, 'Pending', 1),
(3, 2, 26.0, 4.4, 8.7, 47.00, 1222.00, CURRENT_DATE, 'Paid', 1),
(4, 2, 19.0, 4.2, 8.5, 45.00, 855.00, CURRENT_DATE, 'Pending', 1),
(5, 2, 24.5, 4.0, 8.2, 44.00, 1078.00, CURRENT_DATE, 'Pending', 1);

-- Insert sample products
INSERT INTO dairy.products (name, price, unit, category, is_active) VALUES
('Full Cream Milk', 55.00, 'Liter', 'Milk', true),
('Toned Milk', 50.00, 'Liter', 'Milk', true),
('Skimmed Milk', 45.00, 'Liter', 'Milk', true),
('Paneer', 350.00, 'Kg', 'Dairy Products', true),
('Butter', 450.00, 'Kg', 'Dairy Products', true),
('Ghee', 550.00, 'Kg', 'Dairy Products', true),
('Curd', 60.00, 'Kg', 'Dairy Products', true),
('Buttermilk', 25.00, 'Liter', 'Beverages', true)
ON CONFLICT (name) DO NOTHING;

-- Insert sample sales
INSERT INTO dairy.sale (customer_id, product_id, quantity, unit_price, total_amount, sale_date, payment_method, branch_id) VALUES
(1, 1, 50.0, 55.00, 2750.00, CURRENT_DATE, 'Credit', 1),
(2, 2, 30.0, 50.00, 1500.00, CURRENT_DATE, 'Cash', 1),
(3, 3, 100.0, 45.00, 4500.00, CURRENT_DATE, 'UPI', 1),
(4, 4, 5.0, 350.00, 1750.00, CURRENT_DATE, 'Card', 1),
(5, 5, 10.0, 450.00, 4500.00, CURRENT_DATE, 'Credit', 1);

-- Insert sample invoices
INSERT INTO dairy.invoices (invoice_number, customer_id, invoice_date, subtotal, tax_amount, total_amount, payment_method, status) VALUES
('INV' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '001', 1, CURRENT_DATE, 2750.00, 495.00, 3245.00, 'Credit', 'Pending'),
('INV' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '002', 2, CURRENT_DATE, 1500.00, 270.00, 1770.00, 'Cash', 'Paid'),
('INV' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '003', 3, CURRENT_DATE, 4500.00, 810.00, 5310.00, 'UPI', 'Paid');

-- Insert sample quality tests
INSERT INTO dairy.quality_tests (batch_id, fat_pct, snf_pct, bacterial_count, adulteration_detected, fssai_compliant, tested_by) VALUES
(1, 4.2, 8.5, 50000, false, true, 'Lab Technician A'),
(2, 3.8, 8.2, 45000, false, true, 'Lab Technician B'),
(3, 4.5, 8.8, 30000, false, true, 'Lab Technician A'),
(4, 3.5, 8.0, 180000, false, true, 'Lab Technician C'),
(5, 4.0, 8.3, 40000, false, true, 'Lab Technician B');

-- Insert sample payment transactions
INSERT INTO dairy.payment_transactions (payment_type, farmer_id, customer_id, amount, payment_method, status, reference_id) VALUES
('farmer', 3, NULL, 2758.00, 'UPI', 'Success', 'UPI' || EXTRACT(EPOCH FROM NOW())::bigint),
('farmer', 1, NULL, 2037.50, 'Cash', 'Success', 'CASH' || EXTRACT(EPOCH FROM NOW())::bigint),
('customer', NULL, 2, 1770.00, 'Cash', 'Success', 'CASH' || EXTRACT(EPOCH FROM NOW())::bigint),
('customer', NULL, 3, 5310.00, 'UPI', 'Success', 'UPI' || EXTRACT(EPOCH FROM NOW())::bigint);

-- Insert sample routes
INSERT INTO dairy.routes (name, driver_name, vehicle_number, status, total_distance) VALUES
('Route A - East Zone', 'राहुल पवार', 'MH12AB1234', 'Active', 25.5),
('Route B - West Zone', 'अमित जोशी', 'MH12CD5678', 'Active', 18.2),
('Route C - North Zone', 'विकास शर्मा', 'MH12EF9012', 'In Progress', 22.8);

-- Insert sample route farmers
INSERT INTO dairy.route_farmers (route_id, farmer_id) VALUES
(1, 1), (1, 2), (1, 3),
(2, 4), (2, 5), (2, 6),
(3, 7), (3, 8), (3, 9), (3, 10);

-- Insert sample subscriptions
INSERT INTO dairy.subscriptions (customer_id, product_id, quantity, frequency, start_date, next_delivery_date, status) VALUES
(2, 1, 10.0, 'Daily', CURRENT_DATE - INTERVAL '7 days', CURRENT_DATE + INTERVAL '1 day', 'Active'),
(4, 2, 15.0, 'Daily', CURRENT_DATE - INTERVAL '5 days', CURRENT_DATE + INTERVAL '1 day', 'Active'),
(1, 3, 50.0, 'Weekly', CURRENT_DATE - INTERVAL '10 days', CURRENT_DATE + INTERVAL '4 days', 'Active');

-- Insert sample farmer loans
INSERT INTO dairy.farmer_loans (farmer_id, loan_type, amount, outstanding_amount, due_date, interest_rate, status) VALUES
(1, 'Advance Payment', 10000.00, 8500.00, CURRENT_DATE + INTERVAL '30 days', 2.0, 'Active'),
(4, 'Equipment Loan', 25000.00, 22000.00, CURRENT_DATE + INTERVAL '90 days', 8.5, 'Active'),
(7, 'Emergency Loan', 5000.00, 0.00, CURRENT_DATE - INTERVAL '5 days', 5.0, 'Paid');

-- Insert sample expenses
INSERT INTO dairy.expenses (category, amount, description, expense_date, branch_id) VALUES
('Transport', 2500.00, 'Fuel for collection vehicles', CURRENT_DATE, 1),
('Maintenance', 1800.00, 'Equipment servicing', CURRENT_DATE, 1),
('Utilities', 3200.00, 'Electricity and water bills', CURRENT_DATE, 1),
('Staff Salary', 45000.00, 'Monthly staff payments', CURRENT_DATE, 1);

-- Update payment status for paid collections
UPDATE dairy.milk_collection 
SET payment_date = CURRENT_DATE 
WHERE payment_status = 'Paid';

-- Insert sample inventory
INSERT INTO dairy.inventory (product_id, quantity, unit_price, total_value, last_updated) VALUES
(1, 500.0, 55.00, 27500.00, CURRENT_DATE),
(2, 300.0, 50.00, 15000.00, CURRENT_DATE),
(3, 200.0, 45.00, 9000.00, CURRENT_DATE),
(4, 25.0, 350.00, 8750.00, CURRENT_DATE),
(5, 15.0, 450.00, 6750.00, CURRENT_DATE);

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Demo sample data inserted successfully!';
    RAISE NOTICE 'Farmers: 10 records';
    RAISE NOTICE 'Customers: 5 records';
    RAISE NOTICE 'Collections: 10 records';
    RAISE NOTICE 'Sales: 5 records';
    RAISE NOTICE 'Quality Tests: 5 records';
    RAISE NOTICE 'Payment Transactions: 4 records';
    RAISE NOTICE 'Routes: 3 records';
    RAISE NOTICE 'System ready for demo!';
END $$;