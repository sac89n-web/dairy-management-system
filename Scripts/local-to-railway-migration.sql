-- Generated schema from local PostgreSQL
-- Run this on Railway PostgreSQL

CREATE SCHEMA IF NOT EXISTS dairy;
SET search_path TO dairy, public;

-- Table: audit_log
CREATE TABLE IF NOT EXISTS dairy.audit_log (
    id SERIAL PRIMARY KEY NOT NULL,
    user_id INTEGER,
    action VARCHAR(100) NOT NULL,
    entity VARCHAR(50),
    entity_id INTEGER,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);

-- Table: bank
CREATE TABLE IF NOT EXISTS dairy.bank (
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL
);

-- Table: branch
CREATE TABLE IF NOT EXISTS dairy.branch (
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    contact VARCHAR(50)
);

-- Table: customer
CREATE TABLE IF NOT EXISTS dairy.customer (
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL,
    contact VARCHAR(50) NOT NULL,
    branch_id INTEGER,
    email VARCHAR(100),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50) DEFAULT 'Maharashtra'::character varying,
    pincode VARCHAR(10),
    gst_number VARCHAR(15),
    customer_type VARCHAR(50) DEFAULT 'Individual'::character varying,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Table: employee
CREATE TABLE IF NOT EXISTS dairy.employee (
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL,
    contact VARCHAR(50) NOT NULL,
    branch_id INTEGER,
    role VARCHAR(30) NOT NULL
);

-- Table: expense
CREATE TABLE IF NOT EXISTS dairy.expense (
    id SERIAL PRIMARY KEY NOT NULL,
    category_id INTEGER,
    branch_id INTEGER,
    amount DECIMAL(10,2) NOT NULL,
    date DATE NOT NULL,
    notes TEXT,
    created_by INTEGER
);

-- Table: expense_category
CREATE TABLE IF NOT EXISTS dairy.expense_category (
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL
);

-- Table: farmer
CREATE TABLE IF NOT EXISTS dairy.farmer (
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) NOT NULL,
    contact VARCHAR(50) NOT NULL,
    bank_id INTEGER,
    branch_id INTEGER,
    email VARCHAR(100),
    address TEXT,
    village VARCHAR(100),
    taluka VARCHAR(100),
    district VARCHAR(100),
    state VARCHAR(50) DEFAULT 'Maharashtra'::character varying,
    pincode VARCHAR(10),
    bank_name VARCHAR(100),
    account_number VARCHAR(20),
    ifsc_code VARCHAR(15),
    aadhar_number VARCHAR(12),
    pan_number VARCHAR(10),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Table: farmer_loans
CREATE TABLE IF NOT EXISTS dairy.farmer_loans (
    id SERIAL PRIMARY KEY NOT NULL,
    farmer_id INTEGER NOT NULL,
    loan_type VARCHAR(20) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    outstanding_amount DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    interest_rate DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'Active'::character varying,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Table: inventory_items
CREATE TABLE IF NOT EXISTS dairy.inventory_items (
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(20) NOT NULL DEFAULT 'Liters'::character varying,
    min_stock DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Table: inventory_transactions
CREATE TABLE IF NOT EXISTS dairy.inventory_transactions (
    id SERIAL PRIMARY KEY NOT NULL,
    item_id INTEGER NOT NULL,
    transaction_type VARCHAR(10) NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    reference VARCHAR(255),
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Table: invoice_items
CREATE TABLE IF NOT EXISTS dairy.invoice_items (
    id SERIAL PRIMARY KEY NOT NULL,
    invoice_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL
);

-- Table: invoices
CREATE TABLE IF NOT EXISTS dairy.invoices (
    id SERIAL PRIMARY KEY NOT NULL,
    invoice_number VARCHAR(30) NOT NULL,
    customer_id INTEGER,
    invoice_date DATE NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'Pending'::character varying,
    paid_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Table: item
CREATE TABLE IF NOT EXISTS dairy.item (
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL
);

-- Table: loan_payments
CREATE TABLE IF NOT EXISTS dairy.loan_payments (
    id SERIAL PRIMARY KEY NOT NULL,
    loan_id INTEGER NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Table: milk_collection
CREATE TABLE IF NOT EXISTS dairy.milk_collection (
    id SERIAL PRIMARY KEY NOT NULL,
    farmer_id INTEGER,
    shift_id INTEGER,
    date DATE NOT NULL,
    qty_ltr DECIMAL(10,2) NOT NULL,
    fat_pct DECIMAL(10,2) NOT NULL,
    price_per_ltr DECIMAL(10,2) NOT NULL,
    due_amt DECIMAL(10,2) NOT NULL,
    notes TEXT,
    created_by INTEGER,
    snf_pct DECIMAL(10,2) DEFAULT 8.5,
    payment_status VARCHAR(20) DEFAULT 'Pending'::character varying,
    payment_date TIMESTAMP,
    payment_reference VARCHAR(50)
);

-- Table: payment_customer
CREATE TABLE IF NOT EXISTS dairy.payment_customer (
    id SERIAL PRIMARY KEY NOT NULL,
    customer_id INTEGER,
    sale_id INTEGER,
    amount DECIMAL(10,2) NOT NULL,
    date DATE NOT NULL,
    invoice_no VARCHAR(30),
    pdf_path VARCHAR(255)
);

-- Table: payment_farmer
CREATE TABLE IF NOT EXISTS dairy.payment_farmer (
    id SERIAL PRIMARY KEY NOT NULL,
    farmer_id INTEGER,
    milk_collection_id INTEGER,
    amount DECIMAL(10,2) NOT NULL,
    date DATE NOT NULL,
    invoice_no VARCHAR(30),
    pdf_path VARCHAR(255)
);

-- Table: payment_transactions
CREATE TABLE IF NOT EXISTS dairy.payment_transactions (
    id SERIAL PRIMARY KEY NOT NULL,
    payment_type VARCHAR(20) NOT NULL,
    farmer_id INTEGER,
    customer_id INTEGER,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'Pending'::character varying,
    reference_id VARCHAR(50) NOT NULL,
    transaction_id VARCHAR(100),
    gateway_response TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Table: product_conversion
CREATE TABLE IF NOT EXISTS dairy.product_conversion (
    id SERIAL PRIMARY KEY NOT NULL,
    item_id INTEGER,
    milk_qty DECIMAL(10,2) NOT NULL,
    product_qty DECIMAL(10,2) NOT NULL
);

-- Table: products
CREATE TABLE IF NOT EXISTS dairy.products (
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(20) DEFAULT 'Liters'::character varying,
    price DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Table: quality_tests
CREATE TABLE IF NOT EXISTS dairy.quality_tests (
    id SERIAL PRIMARY KEY NOT NULL,
    batch_id INTEGER NOT NULL,
    test_date DATE NOT NULL DEFAULT CURRENT_DATE,
    fat_pct DECIMAL(10,2) NOT NULL DEFAULT 0,
    snf_pct DECIMAL(10,2) NOT NULL DEFAULT 0,
    bacterial_count INTEGER DEFAULT 0,
    adulteration_detected BOOLEAN DEFAULT false,
    fssai_compliant BOOLEAN DEFAULT true,
    tested_by VARCHAR(100),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Table: rate_chart
CREATE TABLE IF NOT EXISTS dairy.rate_chart (
    id SERIAL PRIMARY KEY NOT NULL,
    milk_type VARCHAR(30) NOT NULL,
    shift_id INTEGER,
    rate DECIMAL(10,2) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    file_ref VARCHAR(255)
);

-- Table: rate_slabs
CREATE TABLE IF NOT EXISTS dairy.rate_slabs (
    id SERIAL PRIMARY KEY NOT NULL,
    fat_min DECIMAL(10,2) NOT NULL,
    fat_max DECIMAL(10,2) NOT NULL,
    snf_min DECIMAL(10,2) NOT NULL,
    snf_max DECIMAL(10,2) NOT NULL,
    base_rate DECIMAL(10,2) NOT NULL,
    incentive DECIMAL(10,2) DEFAULT 0,
    effective_from DATE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT now()
);

-- Table: route_farmers
CREATE TABLE IF NOT EXISTS dairy.route_farmers (
    id SERIAL PRIMARY KEY NOT NULL,
    route_id INTEGER NOT NULL,
    farmer_id INTEGER NOT NULL,
    sequence_order INTEGER NOT NULL,
    estimated_time TIME
);

-- Table: routes
CREATE TABLE IF NOT EXISTS dairy.routes (
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(100) NOT NULL,
    driver_name VARCHAR(100) NOT NULL,
    vehicle_number VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'Active'::character varying,
    total_distance DECIMAL(10,2) DEFAULT 0,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Table: sales
CREATE TABLE IF NOT EXISTS dairy.sales (
    id SERIAL PRIMARY KEY NOT NULL,
    customer_id INTEGER,
    shift_id INTEGER,
    date DATE NOT NULL,
    qty_ltr DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount DECIMAL(10,2) DEFAULT 0,
    paid_amt DECIMAL(10,2) NOT NULL,
    due_amt DECIMAL(10,2) NOT NULL,
    created_by INTEGER
);

-- Table: sell_rate
CREATE TABLE IF NOT EXISTS dairy.sell_rate (
    id SERIAL PRIMARY KEY NOT NULL,
    item_id INTEGER,
    rate DECIMAL(10,2) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    branch_id INTEGER
);

-- Table: settings
CREATE TABLE IF NOT EXISTS dairy.settings (
    id SERIAL PRIMARY KEY NOT NULL,
    system_name VARCHAR(100) NOT NULL,
    contact VARCHAR(50) NOT NULL,
    address TEXT NOT NULL
);

-- Table: shift
CREATE TABLE IF NOT EXISTS dairy.shift (
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(50) NOT NULL,
    start_time TIME,
    end_time TIME
);

-- Table: subscription_deliveries
CREATE TABLE IF NOT EXISTS dairy.subscription_deliveries (
    id SERIAL PRIMARY KEY NOT NULL,
    subscription_id INTEGER NOT NULL,
    delivery_date DATE NOT NULL,
    delivered_quantity DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'Scheduled'::character varying,
    notes TEXT,
    delivered_by INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Table: subscriptions
CREATE TABLE IF NOT EXISTS dairy.subscriptions (
    id SERIAL PRIMARY KEY NOT NULL,
    customer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    frequency VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    next_delivery_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(20) DEFAULT 'Active'::character varying,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Table: tanker_intake
CREATE TABLE IF NOT EXISTS dairy.tanker_intake (
    id SERIAL PRIMARY KEY NOT NULL,
    intake_date DATE NOT NULL,
    tanker_id INTEGER NOT NULL,
    quantity_liters DECIMAL(10,2) NOT NULL,
    fat_percentage DECIMAL(10,2),
    snf_percentage DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: user_account
CREATE TABLE IF NOT EXISTS dairy.user_account (
    id SERIAL PRIMARY KEY NOT NULL,
    login VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(30) NOT NULL,
    person_ref INTEGER
);

-- Indexes
CREATE UNIQUE INDEX payment_customer_invoice_no_key ON dairy.payment_customer USING btree (invoice_no);
CREATE UNIQUE INDEX payment_farmer_invoice_no_key ON dairy.payment_farmer USING btree (invoice_no);
CREATE UNIQUE INDEX user_account_login_key ON dairy.user_account USING btree (login);
CREATE UNIQUE INDEX milk_collection_farmer_id_shift_id_date_key ON dairy.milk_collection USING btree (farmer_id, shift_id, date);
CREATE INDEX idx_milk_collection_date_shift ON dairy.milk_collection USING btree (date, shift_id);
CREATE INDEX idx_milk_collection_farmer_date ON dairy.milk_collection USING btree (farmer_id, date);
CREATE INDEX idx_milk_collection_payment_status ON dairy.milk_collection USING btree (payment_status);
CREATE INDEX idx_subscription_deliveries_date ON dairy.subscription_deliveries USING btree (delivery_date);
CREATE INDEX idx_inventory_transactions_item_date ON dairy.inventory_transactions USING btree (item_id, transaction_date);
CREATE INDEX idx_inventory_transactions_type ON dairy.inventory_transactions USING btree (transaction_type);
CREATE UNIQUE INDEX route_farmers_route_id_farmer_id_key ON dairy.route_farmers USING btree (route_id, farmer_id);
CREATE INDEX idx_route_farmers_route ON dairy.route_farmers USING btree (route_id);
CREATE INDEX idx_route_farmers_farmer ON dairy.route_farmers USING btree (farmer_id);
CREATE INDEX idx_subscriptions_customer ON dairy.subscriptions USING btree (customer_id);
CREATE INDEX idx_subscriptions_next_delivery ON dairy.subscriptions USING btree (next_delivery_date, status);
CREATE INDEX idx_farmer_loans_farmer ON dairy.farmer_loans USING btree (farmer_id);
CREATE INDEX idx_farmer_loans_status ON dairy.farmer_loans USING btree (status);
CREATE INDEX idx_farmer_loans_due_date ON dairy.farmer_loans USING btree (due_date);
CREATE INDEX idx_loan_payments_loan ON dairy.loan_payments USING btree (loan_id);
CREATE UNIQUE INDEX invoices_invoice_number_key ON dairy.invoices USING btree (invoice_number);
CREATE INDEX idx_invoices_customer ON dairy.invoices USING btree (customer_id);
CREATE INDEX idx_invoices_date ON dairy.invoices USING btree (invoice_date);
CREATE INDEX idx_invoices_status ON dairy.invoices USING btree (status);
CREATE INDEX idx_invoice_items_invoice ON dairy.invoice_items USING btree (invoice_id);
CREATE INDEX idx_invoice_items_product ON dairy.invoice_items USING btree (product_id);
CREATE INDEX idx_quality_tests_batch_id ON dairy.quality_tests USING btree (batch_id);
CREATE INDEX idx_quality_tests_test_date ON dairy.quality_tests USING btree (test_date);
CREATE INDEX idx_quality_tests_fssai_compliant ON dairy.quality_tests USING btree (fssai_compliant);
CREATE INDEX idx_quality_tests_fssai ON dairy.quality_tests USING btree (fssai_compliant);
CREATE UNIQUE INDEX payment_transactions_reference_id_key ON dairy.payment_transactions USING btree (reference_id);
CREATE INDEX idx_payment_transactions_farmer_id ON dairy.payment_transactions USING btree (farmer_id);
CREATE INDEX idx_payment_transactions_customer_id ON dairy.payment_transactions USING btree (customer_id);
CREATE INDEX idx_payment_transactions_status ON dairy.payment_transactions USING btree (status);
CREATE INDEX idx_payment_transactions_created_at ON dairy.payment_transactions USING btree (created_at);
CREATE INDEX idx_payment_transactions_reference_id ON dairy.payment_transactions USING btree (reference_id);
CREATE UNIQUE INDEX farmer_code_key ON dairy.farmer USING btree (code);
CREATE INDEX idx_farmer_village ON dairy.farmer USING btree (village);
CREATE INDEX idx_farmer_taluka ON dairy.farmer USING btree (taluka);
CREATE INDEX idx_farmer_district ON dairy.farmer USING btree (district);
CREATE INDEX idx_farmer_active ON dairy.farmer USING btree (is_active);
CREATE INDEX idx_farmer_code ON dairy.farmer USING btree (code);
CREATE INDEX idx_farmer_contact ON dairy.farmer USING btree (contact);
CREATE INDEX idx_farmer_aadhar ON dairy.farmer USING btree (aadhar_number);
CREATE INDEX idx_farmer_pan ON dairy.farmer USING btree (pan_number);
CREATE UNIQUE INDEX uk_farmer_code ON dairy.farmer USING btree (code);
CREATE INDEX idx_customer_city ON dairy.customer USING btree (city);
CREATE INDEX idx_customer_type ON dairy.customer USING btree (customer_type);
CREATE INDEX idx_customer_active ON dairy.customer USING btree (is_active);
CREATE INDEX idx_customer_contact ON dairy.customer USING btree (contact);
CREATE INDEX idx_customer_gst ON dairy.customer USING btree (gst_number);
CREATE UNIQUE INDEX uk_customer_contact ON dairy.customer USING btree (contact);
CREATE INDEX idx_sale_customer_date ON dairy.sales USING btree (customer_id, date);
CREATE INDEX idx_sale_date_shift ON dairy.sales USING btree (date, shift_id);

-- Foreign Keys
ALTER TABLE dairy.employee ADD CONSTRAINT employee_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES dairy.branch(id);
ALTER TABLE dairy.farmer ADD CONSTRAINT farmer_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES dairy.branch(id);
ALTER TABLE dairy.customer ADD CONSTRAINT customer_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES dairy.branch(id);
ALTER TABLE dairy.farmer ADD CONSTRAINT fk_farmer_bank FOREIGN KEY (bank_id) REFERENCES dairy.bank(id);
ALTER TABLE dairy.expense ADD CONSTRAINT expense_category_id_fkey FOREIGN KEY (category_id) REFERENCES dairy.expense_category(id);
ALTER TABLE dairy.expense ADD CONSTRAINT expense_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES dairy.branch(id);
ALTER TABLE dairy.expense ADD CONSTRAINT expense_created_by_fkey FOREIGN KEY (created_by) REFERENCES dairy.employee(id);
ALTER TABLE dairy.sell_rate ADD CONSTRAINT sell_rate_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES dairy.branch(id);
ALTER TABLE dairy.rate_chart ADD CONSTRAINT rate_chart_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES dairy.shift(id);
ALTER TABLE dairy.product_conversion ADD CONSTRAINT product_conversion_item_id_fkey FOREIGN KEY (item_id) REFERENCES dairy.item(id);
ALTER TABLE dairy.milk_collection ADD CONSTRAINT milk_collection_farmer_id_fkey FOREIGN KEY (farmer_id) REFERENCES dairy.farmer(id);
ALTER TABLE dairy.milk_collection ADD CONSTRAINT milk_collection_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES dairy.shift(id);
ALTER TABLE dairy.milk_collection ADD CONSTRAINT milk_collection_created_by_fkey FOREIGN KEY (created_by) REFERENCES dairy.employee(id);
ALTER TABLE dairy.payment_customer ADD CONSTRAINT payment_customer_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES dairy.customer(id);
ALTER TABLE dairy.payment_farmer ADD CONSTRAINT payment_farmer_farmer_id_fkey FOREIGN KEY (farmer_id) REFERENCES dairy.farmer(id);
ALTER TABLE dairy.payment_farmer ADD CONSTRAINT payment_farmer_milk_collection_id_fkey FOREIGN KEY (milk_collection_id) REFERENCES dairy.milk_collection(id);
ALTER TABLE dairy.user_account ADD CONSTRAINT user_account_person_ref_fkey FOREIGN KEY (person_ref) REFERENCES dairy.employee(id);
ALTER TABLE dairy.audit_log ADD CONSTRAINT audit_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES dairy.user_account(id);
ALTER TABLE dairy.sales ADD CONSTRAINT sale_created_by_fkey FOREIGN KEY (created_by) REFERENCES dairy.employee(id);
ALTER TABLE dairy.sales ADD CONSTRAINT sale_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES dairy.customer(id);
ALTER TABLE dairy.sales ADD CONSTRAINT sale_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES dairy.shift(id);
ALTER TABLE dairy.inventory_transactions ADD CONSTRAINT inventory_transactions_item_id_fkey FOREIGN KEY (item_id) REFERENCES dairy.inventory_items(id);
ALTER TABLE dairy.route_farmers ADD CONSTRAINT route_farmers_route_id_fkey FOREIGN KEY (route_id) REFERENCES dairy.routes(id);
ALTER TABLE dairy.route_farmers ADD CONSTRAINT route_farmers_farmer_id_fkey FOREIGN KEY (farmer_id) REFERENCES dairy.farmer(id);
ALTER TABLE dairy.subscriptions ADD CONSTRAINT subscriptions_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES dairy.customer(id);
ALTER TABLE dairy.subscriptions ADD CONSTRAINT subscriptions_product_id_fkey FOREIGN KEY (product_id) REFERENCES dairy.products(id);
ALTER TABLE dairy.subscription_deliveries ADD CONSTRAINT subscription_deliveries_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES dairy.subscriptions(id);
ALTER TABLE dairy.subscription_deliveries ADD CONSTRAINT subscription_deliveries_delivered_by_fkey FOREIGN KEY (delivered_by) REFERENCES dairy.employee(id);
ALTER TABLE dairy.payment_customer ADD CONSTRAINT payment_customer_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES dairy.sales(id);
ALTER TABLE dairy.farmer_loans ADD CONSTRAINT farmer_loans_farmer_id_fkey FOREIGN KEY (farmer_id) REFERENCES dairy.farmer(id);
ALTER TABLE dairy.loan_payments ADD CONSTRAINT loan_payments_loan_id_fkey FOREIGN KEY (loan_id) REFERENCES dairy.farmer_loans(id);
ALTER TABLE dairy.invoices ADD CONSTRAINT invoices_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES dairy.customer(id);
ALTER TABLE dairy.invoice_items ADD CONSTRAINT invoice_items_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES dairy.invoices(id);
ALTER TABLE dairy.invoice_items ADD CONSTRAINT invoice_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES dairy.products(id);
ALTER TABLE dairy.payment_transactions ADD CONSTRAINT payment_transactions_farmer_id_fkey FOREIGN KEY (farmer_id) REFERENCES dairy.farmer(id);
ALTER TABLE dairy.payment_transactions ADD CONSTRAINT payment_transactions_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES dairy.customer(id);

-- Data
INSERT INTO dairy.bank (id, name) VALUES (1, 'State Bank of India') ON CONFLICT DO NOTHING;
INSERT INTO dairy.bank (id, name) VALUES (2, 'Bank of Maharashtra') ON CONFLICT DO NOTHING;
INSERT INTO dairy.branch (id, name, address, contact) VALUES (1, 'Main Branch', '123 Dairy Lane', '9876543210') ON CONFLICT DO NOTHING;
INSERT INTO dairy.customer (id, name, contact, branch_id, email, address, city, state, pincode, gst_number, customer_type, is_active, created_at, updated_at) VALUES (1, 'Customer X', '5555555555', 1, NULL, NULL, 'City-1', 'Maharashtra', NULL, NULL, 'Individual', TRUE, '2025-08-20T15:35:56.296973', '2025-08-20T15:35:56.296973') ON CONFLICT DO NOTHING;
INSERT INTO dairy.customer (id, name, contact, branch_id, email, address, city, state, pincode, gst_number, customer_type, is_active, created_at, updated_at) VALUES (2, 'Customer Y', '4444444444', 1, NULL, NULL, 'City-2', 'Maharashtra', NULL, NULL, 'Individual', TRUE, '2025-08-20T15:35:56.296973', '2025-08-20T15:35:56.296973') ON CONFLICT DO NOTHING;
INSERT INTO dairy.customer (id, name, contact, branch_id, email, address, city, state, pincode, gst_number, customer_type, is_active, created_at, updated_at) VALUES (3, 'Shravani Sawant', '0000000000', 1, NULL, NULL, 'City-3', 'Maharashtra', NULL, NULL, 'Individual', TRUE, '2025-08-20T15:35:56.296973', '2025-08-20T15:35:56.296973') ON CONFLICT DO NOTHING;
INSERT INTO dairy.employee (id, name, contact, branch_id, role) VALUES (1, 'Admin User', '9999999999', 1, 'Admin') ON CONFLICT DO NOTHING;
INSERT INTO dairy.employee (id, name, contact, branch_id, role) VALUES (2, 'Collector One', '8888888888', 1, 'CollectionBoy') ON CONFLICT DO NOTHING;
INSERT INTO dairy.expense_category (id, name) VALUES (1, 'Transport') ON CONFLICT DO NOTHING;
INSERT INTO dairy.expense_category (id, name) VALUES (2, 'Feed') ON CONFLICT DO NOTHING;
INSERT INTO dairy.expense_category (id, name) VALUES (3, 'Maintenance') ON CONFLICT DO NOTHING;
INSERT INTO dairy.farmer (id, name, code, contact, bank_id, branch_id, email, address, village, taluka, district, state, pincode, bank_name, account_number, ifsc_code, aadhar_number, pan_number, is_active, created_at, updated_at) VALUES (1, 'Farmer A', 'F001', '7777777777', 1, 1, NULL, NULL, 'Village-1', 'Taluka-2', 'District-2', 'Maharashtra', NULL, NULL, NULL, NULL, NULL, NULL, TRUE, '2025-08-20T15:35:56.296973', '2025-08-20T15:35:56.296973') ON CONFLICT DO NOTHING;
INSERT INTO dairy.farmer (id, name, code, contact, bank_id, branch_id, email, address, village, taluka, district, state, pincode, bank_name, account_number, ifsc_code, aadhar_number, pan_number, is_active, created_at, updated_at) VALUES (2, 'Farmer B', 'F002', '6666666666', 2, 1, NULL, NULL, 'Village-2', 'Taluka-3', 'District-3', 'Maharashtra', NULL, NULL, NULL, NULL, NULL, NULL, TRUE, '2025-08-20T15:35:56.296973', '2025-08-20T15:35:56.296973') ON CONFLICT DO NOTHING;
INSERT INTO dairy.farmer (id, name, code, contact, bank_id, branch_id, email, address, village, taluka, district, state, pincode, bank_name, account_number, ifsc_code, aadhar_number, pan_number, is_active, created_at, updated_at) VALUES (3, 'Sachin Sawant', 'F124', '0000000000', NULL, 1, NULL, NULL, 'Village-3', 'Taluka-4', 'District-4', 'Maharashtra', NULL, NULL, NULL, NULL, NULL, NULL, TRUE, '2025-08-20T15:35:56.296973', '2025-08-20T15:35:56.296973') ON CONFLICT DO NOTHING;
INSERT INTO dairy.farmer (id, name, code, contact, bank_id, branch_id, email, address, village, taluka, district, state, pincode, bank_name, account_number, ifsc_code, aadhar_number, pan_number, is_active, created_at, updated_at) VALUES (4, 'Aaryan Sawnt', 'F716', '0000000000', NULL, 1, NULL, NULL, 'Village-4', 'Taluka-5', 'District-5', 'Maharashtra', NULL, NULL, NULL, NULL, NULL, NULL, TRUE, '2025-08-20T15:35:56.296973', '2025-08-20T15:35:56.296973') ON CONFLICT DO NOTHING;
INSERT INTO dairy.farmer (id, name, code, contact, bank_id, branch_id, email, address, village, taluka, district, state, pincode, bank_name, account_number, ifsc_code, aadhar_number, pan_number, is_active, created_at, updated_at) VALUES (5, 'Naitik Sawant', 'F704', '0000000000', NULL, 1, NULL, NULL, 'Village-5', 'Taluka-6', 'District-1', 'Maharashtra', NULL, NULL, NULL, NULL, NULL, NULL, TRUE, '2025-08-20T15:35:56.296973', '2025-08-20T15:35:56.296973') ON CONFLICT DO NOTHING;
INSERT INTO dairy.farmer_loans (id, farmer_id, loan_type, amount, outstanding_amount, due_date, interest_rate, status, created_at) VALUES (1, 1, 'Advance', 5000.00, 5000.00, '2025-09-19', 0.00, 'Active', '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.farmer_loans (id, farmer_id, loan_type, amount, outstanding_amount, due_date, interest_rate, status, created_at) VALUES (2, 2, 'Loan', 15000.00, 15000.00, '2025-11-18', 12.00, 'Active', '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_items (id, name, unit, min_stock, created_at) VALUES (1, 'Milk', 'Liters', 100.00, '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_items (id, name, unit, min_stock, created_at) VALUES (2, 'Paneer', 'Kg', 10.00, '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_items (id, name, unit, min_stock, created_at) VALUES (3, 'Ghee', 'Kg', 5.00, '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_items (id, name, unit, min_stock, created_at) VALUES (4, 'Butter', 'Kg', 8.00, '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_items (id, name, unit, min_stock, created_at) VALUES (5, 'Curd', 'Liters', 50.00, '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_items (id, name, unit, min_stock, created_at) VALUES (6, 'Milk', 'Liters', 100.00, '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_items (id, name, unit, min_stock, created_at) VALUES (7, 'Paneer', 'Kg', 10.00, '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_items (id, name, unit, min_stock, created_at) VALUES (8, 'Ghee', 'Kg', 5.00, '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_items (id, name, unit, min_stock, created_at) VALUES (9, 'Butter', 'Kg', 8.00, '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_items (id, name, unit, min_stock, created_at) VALUES (10, 'Curd', 'Liters', 50.00, '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_transactions (id, item_id, transaction_type, quantity, reference, transaction_date) VALUES (1, 1, 'IN', 500.00, 'Initial Stock', '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_transactions (id, item_id, transaction_type, quantity, reference, transaction_date) VALUES (2, 2, 'IN', 25.00, 'Production', '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_transactions (id, item_id, transaction_type, quantity, reference, transaction_date) VALUES (3, 3, 'IN', 15.00, 'Production', '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_transactions (id, item_id, transaction_type, quantity, reference, transaction_date) VALUES (4, 1, 'IN', 500.00, 'Initial Stock', '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_transactions (id, item_id, transaction_type, quantity, reference, transaction_date) VALUES (5, 2, 'IN', 25.00, 'Production', '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_transactions (id, item_id, transaction_type, quantity, reference, transaction_date) VALUES (6, 3, 'IN', 15.00, 'Production', '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_transactions (id, item_id, transaction_type, quantity, reference, transaction_date) VALUES (7, 1, 'OUT', 150.00, 'Sale Order #001', '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_transactions (id, item_id, transaction_type, quantity, reference, transaction_date) VALUES (8, 2, 'OUT', 5.00, 'Sale Order #002', '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_transactions (id, item_id, transaction_type, quantity, reference, transaction_date) VALUES (9, 9, 'IN', 12.00, NULL, '2025-08-20T16:28:30.776473+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_transactions (id, item_id, transaction_type, quantity, reference, transaction_date) VALUES (10, 5, 'IN', 20.00, NULL, '2025-08-20T16:28:42.875961+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.inventory_transactions (id, item_id, transaction_type, quantity, reference, transaction_date) VALUES (11, 5, 'IN', 50.00, NULL, '2025-08-20T16:28:59.526114+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.invoice_items (id, invoice_id, product_id, quantity, unit_price, total_price) VALUES (1, 1, 11, 1.00, 1.00, 1.00) ON CONFLICT DO NOTHING;
INSERT INTO dairy.invoice_items (id, invoice_id, product_id, quantity, unit_price, total_price) VALUES (2, 2, 11, 12.00, 400.00, 4800.00) ON CONFLICT DO NOTHING;
INSERT INTO dairy.invoice_items (id, invoice_id, product_id, quantity, unit_price, total_price) VALUES (3, 3, 11, 1210.00, 4500.00, 5445000.00) ON CONFLICT DO NOTHING;
INSERT INTO dairy.invoices (id, invoice_number, customer_id, invoice_date, subtotal, tax_amount, total_amount, payment_method, status, paid_date, created_at) VALUES (1, 'INV20250820135717', 3, '2025-08-20', 1.00, 0.18, 1.18, 'Cash', 'Paid', NULL, '2025-08-20T13:57:17.341216+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.invoices (id, invoice_number, customer_id, invoice_date, subtotal, tax_amount, total_amount, payment_method, status, paid_date, created_at) VALUES (2, 'INV20250826194922', 3, '2025-08-26', 4800.00, 864.00, 5664.00, 'Cash', 'Paid', NULL, '2025-08-26T19:49:22.031734+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.invoices (id, invoice_number, customer_id, invoice_date, subtotal, tax_amount, total_amount, payment_method, status, paid_date, created_at) VALUES (3, 'INV20250826200819', 3, '2025-08-26', 5445000.00, 980100.00, 6425100.00, 'Cash', 'Paid', NULL, '2025-08-26T20:08:19.849052+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.item (id, name) VALUES (1, 'Milk') ON CONFLICT DO NOTHING;
INSERT INTO dairy.item (id, name) VALUES (2, 'Paneer') ON CONFLICT DO NOTHING;
INSERT INTO dairy.item (id, name) VALUES (3, 'Ghee') ON CONFLICT DO NOTHING;
INSERT INTO dairy.milk_collection (id, farmer_id, shift_id, date, qty_ltr, fat_pct, price_per_ltr, due_amt, notes, created_by, snf_pct, payment_status, payment_date, payment_reference) VALUES (3, 4, 1, '2025-08-19', 78.00, 10.00, 99.00, 7722.00, NULL, NULL, 8.50, 'Pending', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO dairy.milk_collection (id, farmer_id, shift_id, date, qty_ltr, fat_pct, price_per_ltr, due_amt, notes, created_by, snf_pct, payment_status, payment_date, payment_reference) VALUES (7, 1, 1, '2025-08-20', 40.00, 2.90, 109.00, 4360.00, NULL, NULL, 8.50, 'Pending', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO dairy.milk_collection (id, farmer_id, shift_id, date, qty_ltr, fat_pct, price_per_ltr, due_amt, notes, created_by, snf_pct, payment_status, payment_date, payment_reference) VALUES (2, 3, 1, '2025-08-19', 100.00, 14.00, 90.00, 9000.00, NULL, NULL, 8.50, 'Paid', '2025-08-19T00:00:00', NULL) ON CONFLICT DO NOTHING;
INSERT INTO dairy.milk_collection (id, farmer_id, shift_id, date, qty_ltr, fat_pct, price_per_ltr, due_amt, notes, created_by, snf_pct, payment_status, payment_date, payment_reference) VALUES (4, 5, 1, '2025-08-19', 85.00, 12.00, 98.00, 8330.00, NULL, NULL, 8.50, 'Paid', '2025-08-19T00:00:00', NULL) ON CONFLICT DO NOTHING;
INSERT INTO dairy.payment_transactions (id, payment_type, farmer_id, customer_id, amount, payment_method, status, reference_id, transaction_id, gateway_response, created_at, updated_at) VALUES (1, 'farmer', 1, NULL, 5000.00, 'UPI', 'Success', 'UPI1755687005', NULL, NULL, '2025-08-20T16:20:05.426583', '2025-08-20T16:20:05.426583') ON CONFLICT DO NOTHING;
INSERT INTO dairy.payment_transactions (id, payment_type, farmer_id, customer_id, amount, payment_method, status, reference_id, transaction_id, gateway_response, created_at, updated_at) VALUES (2, 'farmer', 2, NULL, 3500.00, 'Cash', 'Success', 'CASH1755687005', NULL, NULL, '2025-08-20T16:20:05.426583', '2025-08-20T16:20:05.426583') ON CONFLICT DO NOTHING;
INSERT INTO dairy.payment_transactions (id, payment_type, farmer_id, customer_id, amount, payment_method, status, reference_id, transaction_id, gateway_response, created_at, updated_at) VALUES (3, 'customer', 1, NULL, 2000.00, 'Card', 'Success', 'CARD1755687005', NULL, NULL, '2025-08-20T16:20:05.426583', '2025-08-20T16:20:05.426583') ON CONFLICT DO NOTHING;
INSERT INTO dairy.payment_transactions (id, payment_type, farmer_id, customer_id, amount, payment_method, status, reference_id, transaction_id, gateway_response, created_at, updated_at) VALUES (4, 'farmer', 1, NULL, 2758.00, 'UPI', 'Success', 'UPI1755691316', NULL, NULL, '2025-08-20T17:31:55.758501', '2025-08-20T17:31:55.758501') ON CONFLICT DO NOTHING;
INSERT INTO dairy.payment_transactions (id, payment_type, farmer_id, customer_id, amount, payment_method, status, reference_id, transaction_id, gateway_response, created_at, updated_at) VALUES (5, 'farmer', 2, NULL, 1422.50, 'Cash', 'Success', 'CASH1755691316', NULL, NULL, '2025-08-20T17:31:55.758501', '2025-08-20T17:31:55.758501') ON CONFLICT DO NOTHING;
INSERT INTO dairy.payment_transactions (id, payment_type, farmer_id, customer_id, amount, payment_method, status, reference_id, transaction_id, gateway_response, created_at, updated_at) VALUES (6, 'farmer', 3, NULL, 3758.00, 'UPI', 'Success', 'UPI1755691317', NULL, NULL, '2025-08-20T17:31:55.758501', '2025-08-20T17:31:55.758501') ON CONFLICT DO NOTHING;
INSERT INTO dairy.products (id, name, unit, price, is_active, created_at) VALUES (1, 'Fresh Milk', 'Liters', 55.00, TRUE, '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.products (id, name, unit, price, is_active, created_at) VALUES (2, 'Toned Milk', 'Liters', 50.00, TRUE, '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.products (id, name, unit, price, is_active, created_at) VALUES (3, 'Full Cream Milk', 'Liters', 60.00, TRUE, '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.products (id, name, unit, price, is_active, created_at) VALUES (4, 'Paneer', 'Kg', 350.00, TRUE, '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.products (id, name, unit, price, is_active, created_at) VALUES (10, 'Curd', 'Liters', 45.00, TRUE, '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.products (id, name, unit, price, is_active, created_at) VALUES (11, 'Butter', 'Kg', 450.00, TRUE, '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.products (id, name, unit, price, is_active, created_at) VALUES (12, 'Ghee', 'Kg', 550.00, TRUE, '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.quality_tests (id, batch_id, test_date, fat_pct, snf_pct, bacterial_count, adulteration_detected, fssai_compliant, tested_by, remarks, created_at, updated_at) VALUES (1, 1, '2025-08-20', 4.20, 8.50, 50000, FALSE, TRUE, NULL, NULL, '2025-08-20T16:01:20.235358', '2025-08-20T16:01:20.235358') ON CONFLICT DO NOTHING;
INSERT INTO dairy.quality_tests (id, batch_id, test_date, fat_pct, snf_pct, bacterial_count, adulteration_detected, fssai_compliant, tested_by, remarks, created_at, updated_at) VALUES (2, 2, '2025-08-20', 3.80, 8.20, 45000, FALSE, TRUE, NULL, NULL, '2025-08-20T16:01:20.235358', '2025-08-20T16:01:20.235358') ON CONFLICT DO NOTHING;
INSERT INTO dairy.quality_tests (id, batch_id, test_date, fat_pct, snf_pct, bacterial_count, adulteration_detected, fssai_compliant, tested_by, remarks, created_at, updated_at) VALUES (3, 3, '2025-08-20', 4.50, 8.80, 30000, FALSE, TRUE, NULL, NULL, '2025-08-20T16:01:20.235358', '2025-08-20T16:01:20.235358') ON CONFLICT DO NOTHING;
INSERT INTO dairy.quality_tests (id, batch_id, test_date, fat_pct, snf_pct, bacterial_count, adulteration_detected, fssai_compliant, tested_by, remarks, created_at, updated_at) VALUES (4, 4, '2025-08-20', 3.50, 8.00, 60000, FALSE, FALSE, NULL, NULL, '2025-08-20T16:01:20.235358', '2025-08-20T16:01:20.235358') ON CONFLICT DO NOTHING;
INSERT INTO dairy.quality_tests (id, batch_id, test_date, fat_pct, snf_pct, bacterial_count, adulteration_detected, fssai_compliant, tested_by, remarks, created_at, updated_at) VALUES (5, 5, '2025-08-20', 4.00, 8.30, 40000, FALSE, TRUE, NULL, NULL, '2025-08-20T16:01:20.235358', '2025-08-20T16:01:20.235358') ON CONFLICT DO NOTHING;
INSERT INTO dairy.quality_tests (id, batch_id, test_date, fat_pct, snf_pct, bacterial_count, adulteration_detected, fssai_compliant, tested_by, remarks, created_at, updated_at) VALUES (6, 1, '2025-08-20', 4.20, 8.50, 50000, FALSE, TRUE, 'Lab Tech A', NULL, '2025-08-20T17:31:55.758501', '2025-08-20T17:31:55.758501') ON CONFLICT DO NOTHING;
INSERT INTO dairy.quality_tests (id, batch_id, test_date, fat_pct, snf_pct, bacterial_count, adulteration_detected, fssai_compliant, tested_by, remarks, created_at, updated_at) VALUES (7, 2, '2025-08-20', 3.80, 8.20, 45000, FALSE, TRUE, 'Lab Tech B', NULL, '2025-08-20T17:31:55.758501', '2025-08-20T17:31:55.758501') ON CONFLICT DO NOTHING;
INSERT INTO dairy.quality_tests (id, batch_id, test_date, fat_pct, snf_pct, bacterial_count, adulteration_detected, fssai_compliant, tested_by, remarks, created_at, updated_at) VALUES (8, 3, '2025-08-20', 4.50, 8.80, 30000, FALSE, TRUE, 'Lab Tech A', NULL, '2025-08-20T17:31:55.758501', '2025-08-20T17:31:55.758501') ON CONFLICT DO NOTHING;
INSERT INTO dairy.quality_tests (id, batch_id, test_date, fat_pct, snf_pct, bacterial_count, adulteration_detected, fssai_compliant, tested_by, remarks, created_at, updated_at) VALUES (9, 4, '2025-08-20', 3.50, 8.00, 180000, FALSE, TRUE, 'Lab Tech C', NULL, '2025-08-20T17:31:55.758501', '2025-08-20T17:31:55.758501') ON CONFLICT DO NOTHING;
INSERT INTO dairy.quality_tests (id, batch_id, test_date, fat_pct, snf_pct, bacterial_count, adulteration_detected, fssai_compliant, tested_by, remarks, created_at, updated_at) VALUES (10, 5, '2025-08-20', 4.00, 8.30, 40000, FALSE, TRUE, 'Lab Tech B', NULL, '2025-08-20T17:31:55.758501', '2025-08-20T17:31:55.758501') ON CONFLICT DO NOTHING;
INSERT INTO dairy.rate_slabs (id, fat_min, fat_max, snf_min, snf_max, base_rate, incentive, effective_from, is_active, created_at) VALUES (1, 3.00, 3.50, 8.00, 8.50, 40.00, 0.00, '2025-08-26', TRUE, '2025-08-26T19:53:37.047756') ON CONFLICT DO NOTHING;
INSERT INTO dairy.rate_slabs (id, fat_min, fat_max, snf_min, snf_max, base_rate, incentive, effective_from, is_active, created_at) VALUES (2, 3.50, 4.00, 8.00, 8.50, 42.00, 1.00, '2025-08-26', TRUE, '2025-08-26T19:53:37.047756') ON CONFLICT DO NOTHING;
INSERT INTO dairy.rate_slabs (id, fat_min, fat_max, snf_min, snf_max, base_rate, incentive, effective_from, is_active, created_at) VALUES (3, 4.00, 4.50, 8.50, 9.00, 45.00, 2.00, '2025-08-26', TRUE, '2025-08-26T19:53:37.047756') ON CONFLICT DO NOTHING;
INSERT INTO dairy.rate_slabs (id, fat_min, fat_max, snf_min, snf_max, base_rate, incentive, effective_from, is_active, created_at) VALUES (4, 4.50, 5.00, 9.00, 9.50, 48.00, 3.00, '2025-08-26', TRUE, '2025-08-26T19:53:37.047756') ON CONFLICT DO NOTHING;
INSERT INTO dairy.rate_slabs (id, fat_min, fat_max, snf_min, snf_max, base_rate, incentive, effective_from, is_active, created_at) VALUES (5, 5.00, 6.00, 9.50, 10.00, 52.00, 5.00, '2025-08-26', TRUE, '2025-08-26T19:53:37.047756') ON CONFLICT DO NOTHING;
INSERT INTO dairy.route_farmers (id, route_id, farmer_id, sequence_order, estimated_time) VALUES (1, 1, 1, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO dairy.route_farmers (id, route_id, farmer_id, sequence_order, estimated_time) VALUES (2, 1, 2, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO dairy.routes (id, name, driver_name, vehicle_number, status, total_distance, started_at, completed_at, created_at) VALUES (1, 'Route A - North', 'Ramesh Kumar', 'MH12AB1234', 'Active', 25.50, NULL, NULL, '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.routes (id, name, driver_name, vehicle_number, status, total_distance, started_at, completed_at, created_at) VALUES (2, 'Route B - South', 'Suresh Patil', 'MH12CD5678', 'Active', 18.20, NULL, NULL, '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.routes (id, name, driver_name, vehicle_number, status, total_distance, started_at, completed_at, created_at) VALUES (3, 'Route C - East', 'Mahesh Singh', 'MH12EF9012', 'Active', 32.10, NULL, NULL, '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.routes (id, name, driver_name, vehicle_number, status, total_distance, started_at, completed_at, created_at) VALUES (4, 'Route A - North', 'Ramesh Kumar', 'MH12AB1234', 'Active', 25.50, NULL, NULL, '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.routes (id, name, driver_name, vehicle_number, status, total_distance, started_at, completed_at, created_at) VALUES (5, 'Route B - South', 'Suresh Patil', 'MH12CD5678', 'Active', 18.20, NULL, NULL, '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.routes (id, name, driver_name, vehicle_number, status, total_distance, started_at, completed_at, created_at) VALUES (6, 'Route C - East', 'Mahesh Singh', 'MH12EF9012', 'Active', 32.10, NULL, NULL, '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.settings (id, system_name, contact, address) VALUES (1, 'Dairy Management System', '9876543210', '123 Dairy Lane') ON CONFLICT DO NOTHING;
INSERT INTO dairy.shift (id, name, start_time, end_time) VALUES (1, 'Morning', '06:00:00', '10:00:00') ON CONFLICT DO NOTHING;
INSERT INTO dairy.shift (id, name, start_time, end_time) VALUES (2, 'Evening', '16:00:00', '20:00:00') ON CONFLICT DO NOTHING;
INSERT INTO dairy.subscriptions (id, customer_id, product_id, quantity, frequency, start_date, next_delivery_date, end_date, status, created_at) VALUES (1, 1, 1, 2.00, 'Daily', '2025-08-20', '2025-08-21', NULL, 'Active', '2025-08-20T13:43:38.430270+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.subscriptions (id, customer_id, product_id, quantity, frequency, start_date, next_delivery_date, end_date, status, created_at) VALUES (2, 1, 1, 2.00, 'Daily', '2025-08-20', '2025-08-21', NULL, 'Active', '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;
INSERT INTO dairy.subscriptions (id, customer_id, product_id, quantity, frequency, start_date, next_delivery_date, end_date, status, created_at) VALUES (3, 1, 2, 1.00, 'Daily', '2025-08-20', '2025-08-21', NULL, 'Active', '2025-08-20T13:53:14.911610+05:30') ON CONFLICT DO NOTHING;

-- Permissions
GRANT ALL PRIVILEGES ON SCHEMA dairy TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA dairy TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA dairy TO PUBLIC;

SELECT 'Schema migration completed successfully!' as status;