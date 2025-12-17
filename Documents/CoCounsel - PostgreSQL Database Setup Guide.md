# **CoCounsel**

## **PostgreSQL Database Setup Guide**

**Complete Installation & Configuration — Version 1.0**

---

## **Overview**

**This guide walks you through setting up the PostgreSQL database required for CoCounsel. The system uses three main tables to store research results, manage the expert review queue, and maintain audit logs of all workflow executions.**

**CoCounsel is designed to work with Supabase (a hosted PostgreSQL service), but can also work with any PostgreSQL 13+ database.**

### **Prerequisites**

1. **Supabase account (free tier available) or PostgreSQL 13+ server**  
2. **n8n instance (cloud or self-hosted)**  
3. **Database admin access to create tables**  
4. **SQL client (Supabase SQL Editor, pgAdmin, or psql)**

---

## **Part 1: Supabase Project Setup**

### **Step 1: Create a Supabase Project**

1. **Go to https://supabase.com and sign in or create an account**  
2. **Click New Project**  
3. **Enter a project name (e.g., "cocounsel-legal")**  
4. **Set a strong database password — save this securely\!**  
5. **Select your preferred region (choose closest to your n8n instance)**  
6. **Click Create new project and wait for provisioning (1-2 minutes)**

### **Step 2: Get Connection Details**

**Once your project is ready, navigate to Settings → Database to find your connection details.**

| Parameter | Value / Location |
| ----- | ----- |
| **Host** | **aws-0-\[region\].pooler.supabase.com** |
| **Port** | **6543 (Transaction pooler) or 5432 (Session pooler)** |
| **Database** | **postgres** |
| **User** | **postgres.\[project-ref\]** |
| **Password** | **The password you set during project creation** |
| **SSL Mode** | **Required (verify-full recommended)** |

**TIP: Use port 6543 (Transaction pooler) for n8n connections. It handles connection pooling automatically and works better with serverless/workflow applications.**

---

## **Part 2: Create Database Tables**

**Navigate to the SQL Editor in your Supabase dashboard. Execute each SQL statement below to create the required tables.**

### **Table 1: research\_results**

**Stores completed legal research outputs including case analyses, synthesis, and generated memoranda.**

**CREATE TABLE research\_results (**  
    **id SERIAL PRIMARY KEY,**  
    **session\_id TEXT NOT NULL,**  
    **user\_id TEXT NOT NULL,**  
    **original\_query TEXT,**  
    **jurisdiction TEXT,**  
    **practice\_area TEXT,**  
    **legal\_issues JSONB,**  
    **search\_terms JSONB,**  
    **practice\_areas JSONB,**  
    **case\_analyses JSONB,**  
    **relevant\_cases JSONB,**  
    **key\_findings JSONB,**  
    **executive\_summary TEXT,**  
    **legal\_analysis TEXT,**  
    **precedents JSONB,**  
    **recommendations JSONB,**  
    **quality\_score INTEGER,**  
    **confidence\_rating TEXT,**  
    **expert\_review\_needed BOOLEAN DEFAULT FALSE,**  
    **quality\_gaps JSONB,**  
    **quality\_strengths JSONB,**  
    **memorandum TEXT,**  
    **created\_at TIMESTAMPTZ DEFAULT NOW(),**  
    **updated\_at TIMESTAMPTZ DEFAULT NOW()**  
**);**

**\-- Create indexes for common queries**  
**CREATE INDEX idx\_research\_session ON research\_results(session\_id);**  
**CREATE INDEX idx\_research\_user ON research\_results(user\_id);**  
**CREATE INDEX idx\_research\_created ON research\_results(created\_at DESC);**

### **Table 2: review\_queue**

**Holds research items that have been flagged for expert human review (quality score \< 80).**

**CREATE TABLE review\_queue (**  
    **id SERIAL PRIMARY KEY,**  
    **session\_id TEXT NOT NULL,**  
    **user\_id TEXT NOT NULL,**  
    **original\_query TEXT,**  
    **jurisdiction TEXT,**  
    **practice\_area TEXT,**  
    **legal\_issues JSONB,**  
    **search\_terms JSONB,**  
    **practice\_areas JSONB,**  
    **case\_analyses JSONB,**  
    **relevant\_cases JSONB,**  
    **key\_findings JSONB,**  
    **executive\_summary TEXT,**  
    **legal\_analysis TEXT,**  
    **precedents JSONB,**  
    **recommendations JSONB,**  
    **quality\_score INTEGER,**  
    **confidence\_rating TEXT,**  
    **expert\_review\_needed BOOLEAN DEFAULT TRUE,**  
    **quality\_gaps JSONB,**  
    **quality\_strengths JSONB,**  
    **memorandum TEXT,**  
    **review\_status TEXT DEFAULT 'pending',**  
    **reviewed\_by TEXT,**  
    **reviewed\_at TIMESTAMPTZ,**  
    **review\_notes TEXT,**  
    **created\_at TIMESTAMPTZ DEFAULT NOW(),**  
    **updated\_at TIMESTAMPTZ DEFAULT NOW()**  
**);**

**\-- Create indexes for review queue management**  
**CREATE INDEX idx\_review\_status ON review\_queue(review\_status);**  
**CREATE INDEX idx\_review\_user ON review\_queue(user\_id);**  
**CREATE INDEX idx\_review\_created ON review\_queue(created\_at DESC);**

### **Table 3: audit\_log**

**Tracks all workflow executions for monitoring, debugging, and compliance purposes.**

**CREATE TABLE audit\_log (**  
    **id SERIAL PRIMARY KEY,**  
    **session\_id TEXT NOT NULL,**  
    **user\_id TEXT NOT NULL,**  
    **workflow\_path TEXT NOT NULL,**  
    **final\_action TEXT NOT NULL,**  
    **status TEXT DEFAULT 'completed',**  
    **started\_at TIMESTAMPTZ NOT NULL,**  
    **completed\_at TIMESTAMPTZ NOT NULL,**  
    **execution\_time\_seconds INTEGER,**  
    **quality\_score INTEGER,**  
    **confidence\_rating TEXT,**  
    **expert\_review\_needed BOOLEAN,**  
    **original\_query TEXT,**  
    **jurisdiction TEXT,**  
    **practice\_area TEXT,**  
    **cases\_analyzed INTEGER,**  
    **issues\_identified INTEGER,**  
    **recommendations\_generated INTEGER,**  
    **metadata JSONB,**  
    **created\_at TIMESTAMPTZ DEFAULT NOW()**  
**);**

**\-- Create indexes for audit log queries**  
**CREATE INDEX idx\_audit\_session ON audit\_log(session\_id);**  
**CREATE INDEX idx\_audit\_user ON audit\_log(user\_id);**  
**CREATE INDEX idx\_audit\_status ON audit\_log(status);**  
**CREATE INDEX idx\_audit\_created ON audit\_log(created\_at DESC);**

**IMPORTANT: Do NOT set a default value or hardcode the 'id' column in n8n. Let PostgreSQL auto-generate it using SERIAL.**

---

## **Part 3: n8n Database Configuration**

### **Create PostgreSQL Credential**

1. **In n8n, go to Settings → Credentials**  
2. **Click Add Credential → Postgres**  
3. **Enter the connection details from Part 1, Step 2**  
4. **Enable SSL (required for Supabase)**  
5. **Click Test Connection to verify**  
6. **Save the credential**

### **n8n Credential Settings**

| Field | Value |
| ----- | ----- |
| **Host** | **aws-0-us-west-1.pooler.supabase.com** |
| **Database** | **postgres** |
| **User** | **postgres.\[your-project-ref\]** |
| **Password** | **\[Your database password\]** |
| **Port** | **6543** |
| **SSL** | **Enabled** |

---

## **Part 4: Verify Installation**

### **Test Database Connection**

**Run these queries in the Supabase SQL Editor to verify your tables were created correctly:**

**\-- Check all tables exist**  
**SELECT table\_name FROM information\_schema.tables**  
**WHERE table\_schema \= 'public'**  
**AND table\_name IN ('research\_results', 'review\_queue', 'audit\_log');**

**Expected output: 3 rows showing all three table names.**

### **Test Insert Operation**

**Test that inserts work correctly:**

**\-- Test insert into audit\_log**  
**INSERT INTO audit\_log (**  
    **session\_id, user\_id, workflow\_path, final\_action,**  
    **started\_at, completed\_at**  
**) VALUES (**  
    **'test\_session', 'test\_user', 'test\_path', 'test\_action',**  
    **NOW(), NOW()**  
**) RETURNING id;**

**\-- Clean up test data**  
**DELETE FROM audit\_log WHERE session\_id \= 'test\_session';**

---

## **Part 5: Troubleshooting**

### **Connection Issues**

#### **Error: Connection Refused / Timeout**

* **Cause: Wrong host, port, or firewall blocking connection**  
* **Solution: Verify you're using the pooler host (aws-0-\[region\].pooler.supabase.com) and port 6543**  
* **Check: Ensure your IP is not blocked in Supabase network settings**

#### **Error: SSL Required / SSL Connection Failed**

* **Cause: SSL not enabled in n8n credential or SSL mode mismatch**  
* **Solution: Enable SSL in the n8n Postgres credential settings**  
* **Note: Supabase requires SSL for all connections**

#### **Error: Authentication Failed**

* **Cause: Wrong username or password**  
* **Solution: Username format is postgres.\[project-ref\] — find project ref in Supabase URL**  
* **Reset: Reset database password in Supabase Settings → Database**

### **Insert/Query Issues**

#### **Error: Duplicate Key Violation (audit\_log\_pkey)**

* **Cause: Hardcoded id value (e.g., id: 0\) in n8n node configuration**  
* **Solution: Remove the id field from PostgreSQL node column mappings**  
* **Why: The id column uses SERIAL which auto-generates values**

#### **Error: Invalid Input for Column Type**

* **Cause: Wrong data type being sent (e.g., object instead of JSON string)**  
* **Solution: Use JSON.stringify() for all JSONB columns in n8n Code nodes**  
* **Example: `legal_issues: JSON.stringify(issuesArray)`**

#### **Error: Column Does Not Exist**

* **Cause: Table schema doesn't match n8n node configuration**  
* **Solution: Verify column names in Supabase match exactly (case-sensitive)**  
* **Check: Run: `SELECT column_name FROM information_schema.columns WHERE table_name = 'table_name';`**

### **Performance Issues**

#### **Slow Queries**

* **Cause: Missing indexes or large table scans**  
* **Solution: Ensure all indexes from Part 2 were created**  
* **Monitor: Use Supabase dashboard → Database → Query Performance**

#### **Connection Pool Exhausted**

* **Cause: Too many concurrent connections**  
* **Solution: Use transaction pooler (port 6543\) instead of session pooler**  
* **Upgrade: Consider Supabase Pro for higher connection limits**

### **Useful Diagnostic Queries**

**\-- Check table sizes**  
**SELECT relname AS table\_name,**  
       **pg\_size\_pretty(pg\_total\_relation\_size(relid)) AS total\_size**  
**FROM pg\_catalog.pg\_statio\_user\_tables**  
**ORDER BY pg\_total\_relation\_size(relid) DESC;**

**\-- Check recent audit log entries**  
**SELECT id, session\_id, status, quality\_score, created\_at**  
**FROM audit\_log**  
**ORDER BY created\_at DESC**  
**LIMIT 10;**

**\-- Check pending reviews**  
**SELECT COUNT(\*) AS pending\_reviews**  
**FROM review\_queue**  
**WHERE review\_status \= 'pending';**

---

***— End of Database Setup Guide —***

