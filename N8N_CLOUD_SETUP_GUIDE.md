# 🌐 CoCounsel Setup Guide for n8n Cloud

Complete guide for deploying the CoCounsel Legal Research Agent on **n8n Cloud** (cloud.n8n.io).

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Part 1: Set Up n8n Cloud Account](#part-1-set-up-n8n-cloud-account)
4. [Part 2: Set Up External Database (Supabase)](#part-2-set-up-external-database-supabase)
5. [Part 3: Import Workflow to n8n Cloud](#part-3-import-workflow-to-n8n-cloud)
6. [Part 4: Configure Credentials](#part-4-configure-credentials)
7. [Part 5: Test the Workflow](#part-5-test-the-workflow)
8. [Part 6: Production Considerations](#part-6-production-considerations)
9. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

### What's Different from Self-Hosted?

| Feature | Self-Hosted (Docker) | n8n Cloud |
|---------|---------------------|-----------|
| **Infrastructure** | You manage | n8n manages |
| **Database** | Included (local) | External required |
| **Scaling** | Manual | Automatic |
| **Updates** | Manual | Automatic |
| **Cost** | Server + resources | Subscription only |
| **Setup Time** | 30-60 minutes | 10-15 minutes |

### Architecture for n8n Cloud

```
┌─────────────────────────────────────┐
│         n8n Cloud                   │
│  ┌──────────────────────────────┐  │
│  │   CoCounsel Workflow         │  │
│  │   (Imported from JSON)       │  │
│  └──────────────────────────────┘  │
│              ↓                      │
└──────────────┼──────────────────────┘
               ↓
    ┌──────────┴──────────┐
    ↓                     ↓
┌────────────┐      ┌─────────────┐
│  Supabase  │      │  Anthropic  │
│ (Database) │      │    (API)    │
└────────────┘      └─────────────┘
```

---

## 🔑 Prerequisites

### Required Accounts & API Keys

- [ ] **n8n Cloud Account**
  - Sign up: https://n8n.io/cloud/
  - Plans: Starter ($20/mo) or Pro ($50/mo)
  - Free trial available

- [ ] **Supabase Account** (for database)
  - Sign up: https://supabase.com/
  - Free tier available (2 projects)
  - Includes PostgreSQL with pgvector

- [ ] **Anthropic API Key**
  - Get from: https://console.anthropic.com/
  - Required for Claude models
  - Pay-as-you-go pricing

- [ ] **OpenAI API Key** (optional, for embeddings)
  - Get from: https://platform.openai.com/
  - Used for vector embeddings
  - Alternative: Use Supabase Edge Functions

### Required Files

- [ ] `CoCounsel_Complete_Final.json` - The workflow file
- [ ] Database schema SQL (we'll create in Supabase)

---

## 🚀 Part 1: Set Up n8n Cloud Account

### Step 1.1: Sign Up for n8n Cloud

1. **Go to**: https://n8n.io/cloud/
2. **Click**: "Start free trial"
3. **Choose plan**:
   - **Starter** ($20/mo): Up to 10,000 workflow executions
   - **Pro** ($50/mo): Up to 50,000 executions (recommended)
4. **Enter details**:
   - Email address
   - Password
   - Organization name
5. **Verify email**
6. **Complete payment** (free trial period varies)

### Step 1.2: Create Your First Instance

1. **After signup**, you'll be at the dashboard
2. **Click**: "Create new instance"
3. **Choose region**:
   - US East (Virginia) - Recommended for US
   - EU (Frankfurt) - For GDPR compliance
   - Choose closest to your users
4. **Instance name**: `cocounsel-production`
5. **Click**: "Create"
6. **Wait** ~2 minutes for provisioning

### Step 1.3: Access Your n8n Instance

1. **Click** on your instance name
2. **Click**: "Open Editor"
3. You'll see the n8n workflow editor
4. **Bookmark** this URL for easy access

**Your n8n Cloud URL will be:**
```
https://YOUR-INSTANCE.app.n8n.cloud
```

---

## 🗄️ Part 2: Set Up External Database (Supabase)

n8n Cloud doesn't include a database, so we'll use Supabase (which provides PostgreSQL with pgvector).

### Step 2.1: Create Supabase Account

1. **Go to**: https://supabase.com/
2. **Click**: "Start your project"
3. **Sign in with GitHub** (recommended) or email
4. **Complete profile**

### Step 2.2: Create New Project

1. **Click**: "New Project"
2. **Organization**: Create or select existing
3. **Project name**: `cocounsel-db`
4. **Database password**: 
   ```
   Generate a strong password (min 12 characters)
   SAVE THIS PASSWORD - You'll need it!
   ```
5. **Region**: Choose same as n8n instance
   - US East → `East US (North Virginia)`
   - EU → `West EU (Ireland)`
6. **Pricing Plan**: 
   - Free tier works for development
   - Pro ($25/mo) recommended for production
7. **Click**: "Create new project"
8. **Wait** ~2 minutes for provisioning

### Step 2.3: Note Your Connection Details

Once created, you'll need these details:

1. **Go to**: Settings → Database
2. **Copy these values**:
   ```
   Host: db.xxxxxx.supabase.co
   Database name: postgres
   Port: 5432
   User: postgres
   Password: [your password from step 2.2]
   ```
3. **Also copy**: Connection string (we'll use this)
   ```
   postgresql://postgres:[PASSWORD]@db.xxxxxx.supabase.co:5432/postgres
   ```

### Step 2.4: Enable pgvector Extension

1. **In Supabase dashboard**, go to: **Database** → **Extensions**
2. **Search for**: `vector`
3. **Toggle ON**: `vector` extension
4. **Wait** for activation (~30 seconds)

### Step 2.5: Create Database Schema

#### Option A: Using SQL Editor (Recommended)

1. **In Supabase**, go to: **SQL Editor**
2. **Click**: "New Query"
3. **Copy and paste** this schema:

```sql
-- ============================================
-- CoCounsel Database Schema for Supabase
-- ============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USER RESEARCH HISTORY
-- ============================================
CREATE TABLE IF NOT EXISTS user_research_history (
    id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(255) UNIQUE NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    query TEXT NOT NULL,
    jurisdiction VARCHAR(100),
    practice_area VARCHAR(100),
    output_format VARCHAR(50) DEFAULT 'memo',
    
    -- Research results
    issues_identified JSONB,
    cases_cited JSONB,
    analysis JSONB,
    memorandum TEXT,
    
    -- Quality metrics
    quality_score INTEGER,
    retry_count INTEGER DEFAULT 0,
    needs_expert_review BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_id ON user_research_history(user_id);
CREATE INDEX IF NOT EXISTS idx_session_id ON user_research_history(session_id);
CREATE INDEX IF NOT EXISTS idx_practice_area ON user_research_history(practice_area);
CREATE INDEX IF NOT EXISTS idx_jurisdiction ON user_research_history(jurisdiction);
CREATE INDEX IF NOT EXISTS idx_created_at ON user_research_history(created_at DESC);

-- ============================================
-- USER PREFERENCES
-- ============================================
CREATE TABLE IF NOT EXISTS user_preferences (
    user_id VARCHAR(255) PRIMARY KEY,
    preferred_jurisdictions JSONB DEFAULT '[]'::jsonb,
    practice_areas JSONB DEFAULT '[]'::jsonb,
    citation_style VARCHAR(50) DEFAULT 'bluebook',
    detail_level VARCHAR(20) DEFAULT 'comprehensive',
    language_preferences JSONB DEFAULT '{"formality": "professional", "technical_depth": "high"}'::jsonb,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- RESEARCH PATTERNS
-- ============================================
CREATE TABLE IF NOT EXISTS research_patterns (
    id BIGSERIAL PRIMARY KEY,
    query_pattern TEXT NOT NULL,
    successful_search_terms JSONB,
    relevant_cases JSONB,
    average_quality_score FLOAT,
    usage_count INTEGER DEFAULT 1,
    last_used TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_query_pattern UNIQUE (query_pattern)
);

CREATE INDEX IF NOT EXISTS idx_query_pattern ON research_patterns(query_pattern);

-- ============================================
-- EXPERT LESSONS
-- ============================================
CREATE TABLE IF NOT EXISTS learning_examples (
    id BIGSERIAL PRIMARY KEY,
    query_type VARCHAR(100) NOT NULL,
    lesson_learned TEXT NOT NULL,
    correct_analysis TEXT,
    incorrect_analysis JSONB,
    importance_weight FLOAT DEFAULT 1.0,
    examples JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_query_type ON learning_examples(query_type);

-- ============================================
-- CASE KNOWLEDGE BASE (with vectors)
-- ============================================
CREATE TABLE IF NOT EXISTS case_knowledge_base (
    case_id VARCHAR(255) PRIMARY KEY,
    citation TEXT NOT NULL,
    jurisdiction VARCHAR(100) NOT NULL,
    court VARCHAR(255),
    decision_date DATE,
    holding TEXT,
    key_facts TEXT,
    legal_issues JSONB,
    full_text TEXT,
    authority_level VARCHAR(50),
    times_cited INTEGER DEFAULT 0,
    embedding VECTOR(1536),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_jurisdiction_cases ON case_knowledge_base(jurisdiction);
CREATE INDEX IF NOT EXISTS idx_case_embedding ON case_knowledge_base 
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- ============================================
-- EXPERT REVIEW QUEUE
-- ============================================
CREATE TABLE IF NOT EXISTS expert_review_queue (
    id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    query TEXT NOT NULL,
    analysis JSONB,
    memorandum TEXT,
    quality_issues JSONB,
    quality_score INTEGER,
    priority VARCHAR(20) DEFAULT 'medium',
    status VARCHAR(20) DEFAULT 'pending',
    assigned_expert VARCHAR(255),
    expert_feedback JSONB,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (session_id) REFERENCES user_research_history(session_id)
);

CREATE INDEX IF NOT EXISTS idx_status ON expert_review_queue(status);
CREATE INDEX IF NOT EXISTS idx_priority ON expert_review_queue(priority);

-- ============================================
-- AUDIT LOG
-- ============================================
CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(255),
    user_id VARCHAR(255) NOT NULL,
    action VARCHAR(100) NOT NULL,
    details JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_action ON audit_log(user_id, action);
CREATE INDEX IF NOT EXISTS idx_created_at_audit ON audit_log(created_at DESC);

-- ============================================
-- INSERT MOCK DATA FOR TESTING
-- ============================================

-- User Preferences
INSERT INTO user_preferences (user_id, preferred_jurisdictions, practice_areas, citation_style)
VALUES 
    ('user_123', '["federal", "california"]'::jsonb, '["contract", "employment"]'::jsonb, 'bluebook'),
    ('user_456', '["new_york", "federal"]'::jsonb, '["corporate", "securities"]'::jsonb, 'alwd'),
    ('user_789', '["texas", "federal"]'::jsonb, '["patent", "ip"]'::jsonb, 'bluebook')
ON CONFLICT (user_id) DO NOTHING;

-- Research Patterns
INSERT INTO research_patterns (query_pattern, successful_search_terms, relevant_cases, average_quality_score, usage_count)
VALUES 
    ('breach of contract', '["breach", "material breach", "damages", "remedies"]'::jsonb, 
     '["Hadley v. Baxendale", "Jacob & Youngs v. Kent"]'::jsonb, 90.5, 15),
    ('specific performance', '["specific performance", "equitable remedy", "inadequate remedy"]'::jsonb,
     '["Lucy v. Zehmer", "Lumley v. Wagner"]'::jsonb, 88.0, 10),
    ('employment discrimination', '["Title VII", "protected class", "disparate treatment", "adverse action"]'::jsonb,
     '["McDonnell Douglas Corp. v. Green", "Texas Dept. v. Burdine"]'::jsonb, 92.0, 8)
ON CONFLICT (query_pattern) DO NOTHING;

-- Expert Lessons
INSERT INTO learning_examples (query_type, lesson_learned, importance_weight, examples)
VALUES 
    ('contract', 'Always cite UCC sections for commercial contracts. Reference both common law and UCC when applicable.',
     0.95, '["UCC §2-201 (Statute of Frauds)", "UCC §2-207 (Battle of Forms)"]'::jsonb),
    ('contract', 'Distinguish between material and minor breaches. Material breach affects substantial rights.',
     0.88, '["Jacob & Youngs - substantial performance doctrine"]'::jsonb),
    ('employment', 'For discrimination claims, establish prima facie case using McDonnell Douglas framework.',
     0.92, '["McDonnell Douglas Corp. v. Green, 411 U.S. 792 (1973)"]'::jsonb);

-- Case Knowledge Base (sample cases)
INSERT INTO case_knowledge_base (case_id, citation, jurisdiction, court, decision_date, holding, key_facts, legal_issues, authority_level)
VALUES 
    ('hadley_v_baxendale', 'Hadley v. Baxendale, 156 Eng. Rep. 145 (1854)', 'federal', 'Court of Exchequer', 
     '1854-02-01', 'Damages for breach of contract are limited to losses that were foreseeable at the time of contracting.',
     'Miller hired carrier to transport broken mill shaft. Carrier delayed, causing lost profits. Court limited damages to foreseeable losses.',
     '["contract damages", "foreseeability", "consequential damages"]'::jsonb, 'binding'),
    ('lucy_v_zehmer', 'Lucy v. Zehmer, 196 Va. 493, 84 S.E.2d 516 (1954)', 'virginia', 'Supreme Court of Virginia',
     '1954-03-15', 'Contract formation requires objective manifestation of mutual assent, regardless of secret intentions.',
     'Lucy offered to buy Zehmer farm. Zehmer signed agreement but claimed joking. Court enforced contract based on objective manifestation.',
     '["contract formation", "mutual assent", "objective theory"]'::jsonb, 'binding'),
    ('mcconnell_douglas', 'McDonnell Douglas Corp. v. Green, 411 U.S. 792 (1973)', 'federal', 'Supreme Court',
     '1973-05-14', 'Established framework for proving employment discrimination claims under Title VII.',
     'Employee claimed discriminatory discharge. Court created burden-shifting framework for discrimination cases.',
     '["employment discrimination", "Title VII", "prima facie case"]'::jsonb, 'binding');

-- Sample Research History
INSERT INTO user_research_history (session_id, user_id, query, jurisdiction, practice_area, issues_identified, quality_score, retry_count, created_at, completed_at)
VALUES 
    ('session_test_001', 'user_123', 'What are the remedies for breach of contract?', 'federal', 'contract',
     '["Breach of contract", "Contract remedies", "Damages"]'::jsonb, 88, 0, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
    ('session_test_002', 'user_123', 'When is specific performance available?', 'federal', 'contract',
     '["Specific performance", "Equitable remedies", "Adequate remedy at law"]'::jsonb, 92, 0, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
    ('session_test_003', 'user_456', 'Elements of employment discrimination claim', 'federal', 'employment',
     '["Title VII", "Discrimination", "Prima facie case"]'::jsonb, 90, 1, NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours');
```

4. **Click**: "Run" (bottom right)
5. **Verify**: You should see "Success. No rows returned"
6. **Check tables**: Go to **Table Editor** → You should see 7 tables

#### Option B: Using Supabase Table Editor (Manual)

If you prefer UI, manually create tables in **Table Editor** → **New Table**, but Option A is much faster.

### Step 2.6: Enable Row Level Security (RLS) - Optional but Recommended

For production, enable RLS:

1. **Go to**: **Authentication** → **Policies**
2. **For each table**, click "Enable RLS"
3. **Add policies** based on your security requirements

For development/testing, you can skip this step.

### Step 2.7: Get Your Supabase Connection String

1. **Go to**: **Settings** → **Database**
2. **Scroll to**: "Connection string"
3. **Select**: "URI"
4. **Copy** the connection string:
   ```
   postgresql://postgres:[YOUR-PASSWORD]@db.xxxxxx.supabase.co:5432/postgres
   ```
5. **Replace** `[YOUR-PASSWORD]` with your actual password
6. **Save this** - you'll need it for n8n credentials

---

## 📥 Part 3: Import Workflow to n8n Cloud

### Step 3.1: Get the Workflow File

You should have: `CoCounsel_Complete_Final.json`

If not, extract it from the tarball:
```bash
tar -xzf cocounsel-n8n.tar.gz
cd cocounsel-n8n/workflows/
# The file is: CoCounsel_Complete_Final.json
```

### Step 3.2: Import to n8n Cloud

1. **Open your n8n Cloud instance**
2. **Click**: "+" (top right) → "Import from File"
3. **Upload**: `CoCounsel_Complete_Final.json`
4. **Click**: "Import"
5. **Wait** for import to complete

You should now see the complete workflow with all nodes!

### Step 3.3: Review the Workflow

The workflow includes these sections:

1. **Webhook** - Entry point for queries
2. **Memory Initialization** - 3-tier memory setup
3. **Database Queries** - Load user history, preferences, patterns
4. **Issue Spotter** - Claude analyzes query
5. **Case Search** - Vector + traditional search
6. **Case Analysis** - Claude scores relevance
7. **Synthesis** - Claude creates analysis
8. **Quality Control** - Automatic scoring
9. **Quality Gate** - Retry logic
10. **Memorandum** - Draft final document
11. **Save Results** - Persist to database

---

## 🔑 Part 4: Configure Credentials

### Step 4.1: Add PostgreSQL Credentials (Supabase)

1. **In the workflow**, click any **PostgreSQL node**
2. **Click** the credential dropdown
3. **Click**: "Create New Credential"
4. **Enter details**:
   ```
   Name: Supabase CoCounsel DB
   Host: db.xxxxxx.supabase.co
   Database: postgres
   User: postgres
   Password: [your Supabase password]
   Port: 5432
   SSL: On
   ```
5. **Click**: "Save"
6. **Test connection**: Click "Test Credentials"
7. **Should see**: "Connection successful!"

**Apply to all PostgreSQL nodes:**
1. For each PostgreSQL node in the workflow
2. Select the credential you just created
3. Click "Save" on each node

### Step 4.2: Add Anthropic Credentials

1. **Click** any **Claude/Anthropic node**
2. **Click** the credential dropdown
3. **Click**: "Create New Credential"
4. **Enter**:
   ```
   Name: Anthropic API
   API Key: sk-ant-[your-key-here]
   ```
5. **Click**: "Save"
6. **Test**: The node should show green when valid

**Apply to all Claude nodes:**
- Issue Spotter Agent
- Case Analysis Agent
- Synthesis Agent
- Quality Control Agent
- Draft Memorandum Agent

### Step 4.3: Configure Webhook (Optional)

The webhook is automatically configured, but you can customize:

1. **Click** the **Webhook node**
2. **Note the URL**: `https://YOUR-INSTANCE.app.n8n.cloud/webhook/legal-research`
3. **Optional**: Change the path if desired
4. **Method**: POST (keep as is)
5. **Authentication**: None (or add if needed)

---

## ✅ Part 5: Test the Workflow

### Step 5.1: Activate the Workflow

1. **Top right corner**: Toggle "Active" switch to ON
2. **Wait** for webhook to register (~10 seconds)
3. **You should see**: "Workflow is now active"

### Step 5.2: Get Your Webhook URL

1. **Click** the Webhook node
2. **Copy** the "Production URL":
   ```
   https://YOUR-INSTANCE.app.n8n.cloud/webhook/legal-research
   ```

### Step 5.3: Test with curl

Open terminal and run:

```bash
curl -X POST https://YOUR-INSTANCE.app.n8n.cloud/webhook/legal-research \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What are the remedies for material breach of contract?",
    "jurisdiction": "federal",
    "practiceArea": "contract",
    "userId": "test_user_001",
    "isFollowUp": false,
    "outputFormat": "memo"
  }'
```

### Step 5.4: Test with Postman

1. **Open Postman**
2. **Create new request**:
   - Method: POST
   - URL: `https://YOUR-INSTANCE.app.n8n.cloud/webhook/legal-research`
   - Headers: `Content-Type: application/json`
   - Body (raw JSON):
     ```json
     {
       "query": "What are the elements of breach of contract?",
       "jurisdiction": "federal",
       "practiceArea": "contract",
       "userId": "test_user_001"
     }
     ```
3. **Click**: "Send"
4. **Expected response**: JSON with memorandum and analysis

### Step 5.5: Monitor Execution

1. **In n8n**, click "Executions" (left sidebar)
2. **You should see** your test execution
3. **Click** on it to see:
   - Execution time
   - Data flow between nodes
   - Any errors
   - Final output

### Step 5.6: Check Database

1. **Go to Supabase** → **Table Editor**
2. **Open** `user_research_history`
3. **You should see** your test query saved
4. **Check** quality_score, retry_count, etc.

---

## 🏗️ Part 6: Production Considerations

### 6.1: Environment Variables in n8n Cloud

n8n Cloud doesn't support .env files directly. Instead:

**Option A: Use n8n Cloud Environment Variables**
1. **Go to**: Instance Settings → Environment Variables
2. **Add**:
   - `ANTHROPIC_API_KEY` (if not in credentials)
   - `OPENAI_API_KEY` (for embeddings)
   - `WESTLAW_API_KEY` (if using)
   - `LEXISNEXIS_API_KEY` (if using)

**Option B: Store in Credentials**
- Keep sensitive keys in n8n credentials
- Reference with expressions: `{{$credentials.Anthropic.apiKey}}`

### 6.2: Webhook Security

**Add authentication to your webhook:**

1. **Edit Webhook node**
2. **Authentication**: "Header Auth"
3. **Add header**:
   ```
   Name: X-API-Key
   Value: your-secret-api-key-here
   ```
4. **Save workflow**

**Then in requests:**
```bash
curl -X POST https://YOUR-INSTANCE.app.n8n.cloud/webhook/legal-research \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-secret-api-key-here" \
  -d '{"query": "..."}'
```

### 6.3: Rate Limiting

n8n Cloud has built-in rate limiting:
- **Starter**: 10,000 executions/month
- **Pro**: 50,000 executions/month

Monitor usage:
1. **Dashboard** → **Usage**
2. **View**: Executions, active workflows

### 6.4: Error Handling

**Set up error notifications:**

1. **Workflow Settings** → **Error Workflow**
2. **Create error workflow**:
   - Sends email on failure
   - Logs to external system
   - Creates ticket in tracking system

**Example error workflow:**
```
Error Trigger → Email Node (notify admin)
```

### 6.5: Monitoring & Alerts

**Option A: n8n Cloud Monitoring**
- Built-in execution history
- Automatic error alerts
- Usage dashboards

**Option B: External Monitoring**
- Send metrics to Datadog
- Log to CloudWatch
- Create Slack alerts

### 6.6: Backup Strategy

**Database backups (Supabase):**
1. **Go to**: Supabase → Database → Backups
2. **Enable**: Daily backups
3. **Retention**: 7 days (free) or 30 days (pro)

**Workflow backups:**
1. **In n8n**, click workflow settings
2. **Export workflow** regularly
3. **Save to GitHub** or version control

### 6.7: Scaling Considerations

**For high volume:**
- Upgrade to Pro plan (50k executions)
- Enable workflow queue mode
- Optimize database queries with indexes
- Use connection pooling in Supabase
- Consider caching frequent queries

### 6.8: Cost Optimization

**Estimated monthly costs:**

```
n8n Cloud Pro:           $50/month
Supabase Pro:            $25/month
Anthropic API:           ~$50-200/month (usage-based)
OpenAI Embeddings:       ~$10-30/month (if used)
──────────────────────────────────────
Total:                   ~$135-305/month
```

**Reduce costs:**
- Use cheaper models where possible (Haiku vs Sonnet)
- Cache frequent queries
- Batch database operations
- Optimize token usage in prompts

---

## 🐛 Troubleshooting

### Issue: Workflow Import Failed

**Solution:**
1. Check JSON file is valid
2. Try importing in parts (copy nodes manually)
3. Ensure all required nodes are available in n8n Cloud

### Issue: Database Connection Failed

**Symptoms:** "Connection refused" or "Timeout"

**Solutions:**
1. **Check Supabase credentials**:
   - Host, port, user, password all correct
   - SSL is enabled
2. **Verify Supabase project is active**:
   - Go to Supabase dashboard
   - Check project status
3. **Test connection string** directly:
   ```bash
   psql "postgresql://postgres:PASSWORD@db.xxx.supabase.co:5432/postgres"
   ```
4. **Check Supabase IP allowlist**:
   - Supabase → Settings → Database
   - Ensure n8n Cloud IPs are allowed (usually allowed by default)

### Issue: Anthropic API Errors

**Symptoms:** 401 Unauthorized, 429 Rate Limited

**Solutions:**
1. **Verify API key**:
   - Check key is active in Anthropic console
   - No extra spaces in credential
2. **Check rate limits**:
   - Anthropic console → Usage
   - Upgrade tier if hitting limits
3. **Check credits/billing**:
   - Ensure billing is active
   - Add payment method

### Issue: Webhook Not Responding

**Symptoms:** Timeout, 404, no response

**Solutions:**
1. **Check workflow is active**:
   - Toggle must be ON
   - Green indicator visible
2. **Verify webhook URL**:
   - Copy from webhook node
   - Include correct instance domain
3. **Test webhook settings**:
   - Method is POST
   - Path is correct
   - No authentication issues
4. **Check executions list**:
   - See if execution started
   - Check for errors

### Issue: Slow Performance

**Symptoms:** Long execution times (>60 seconds)

**Solutions:**
1. **Optimize database queries**:
   - Add indexes for frequently queried columns
   - Limit result sets
2. **Reduce API calls**:
   - Cache results where possible
   - Use batch operations
3. **Check network latency**:
   - Ensure n8n and Supabase are in same region
4. **Upgrade plans**:
   - n8n Pro for better performance
   - Supabase Pro for dedicated resources

### Issue: Vector Search Not Working

**Symptoms:** No results from case_knowledge_base

**Solutions:**
1. **Verify pgvector extension**:
   ```sql
   SELECT * FROM pg_extension WHERE extname = 'vector';
   ```
2. **Check embeddings exist**:
   ```sql
   SELECT COUNT(*) FROM case_knowledge_base WHERE embedding IS NOT NULL;
   ```
3. **Test vector query**:
   ```sql
   SELECT * FROM case_knowledge_base 
   ORDER BY embedding <=> '[0,0,0,...]'::vector 
   LIMIT 5;
   ```
4. **Rebuild vector index**:
   ```sql
   DROP INDEX IF EXISTS idx_case_embedding;
   CREATE INDEX idx_case_embedding ON case_knowledge_base 
   USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
   ```

### Issue: Memory/Timeout Issues

**Symptoms:** Workflow times out, incomplete executions

**Solutions:**
1. **Simplify prompts**: Reduce token usage
2. **Split workflow**: Break into smaller workflows
3. **Use sub-workflows**: Modularize complex logic
4. **Upgrade plan**: More resources on Pro plan

---

## 📊 Monitoring & Analytics

### View Execution Stats

**In n8n Cloud:**
1. **Dashboard** → **Analytics**
2. **View**:
   - Total executions
   - Success rate
   - Average execution time
   - Error rate

### Database Analytics

**In Supabase:**
1. **Reports** tab
2. **View**:
   - Query performance
   - Table sizes
   - Index usage
   - Slow queries

### Create Custom Views

**In Supabase SQL Editor:**
```sql
-- Research quality over time
SELECT 
    DATE(created_at) as date,
    AVG(quality_score) as avg_quality,
    COUNT(*) as total_queries,
    COUNT(CASE WHEN needs_expert_review THEN 1 END) as needs_review
FROM user_research_history
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Most common practice areas
SELECT 
    practice_area,
    COUNT(*) as query_count,
    AVG(quality_score) as avg_quality
FROM user_research_history
GROUP BY practice_area
ORDER BY query_count DESC;

-- User activity
SELECT 
    user_id,
    COUNT(*) as total_queries,
    MAX(created_at) as last_query,
    AVG(quality_score) as avg_quality
FROM user_research_history
GROUP BY user_id
ORDER BY total_queries DESC;
```

---

## 🎓 Next Steps

### Recommended Enhancements

1. **Add user authentication**:
   - Use Supabase Auth
   - Implement JWT tokens
   - Add row-level security

2. **Create a frontend**:
   - Build Next.js app
   - Connect to n8n webhook
   - Display results beautifully

3. **Implement caching**:
   - Use Supabase Edge Functions
   - Cache frequent queries
   - Reduce API costs

4. **Add monitoring**:
   - Integrate with monitoring service
   - Set up alerts
   - Track performance

5. **Improve embeddings**:
   - Populate case_knowledge_base
   - Generate real embeddings
   - Implement RAG properly

---

## 📚 Resources

- **n8n Cloud Docs**: https://docs.n8n.io/hosting/cloud/
- **Supabase Docs**: https://supabase.com/docs
- **Anthropic API**: https://docs.anthropic.com/
- **n8n Community**: https://community.n8n.io/
- **Supabase Discord**: https://discord.supabase.com/

---

## ✅ Checklist

- [ ] n8n Cloud account created
- [ ] Supabase project created
- [ ] Database schema deployed
- [ ] Mock data loaded
- [ ] Workflow imported to n8n
- [ ] PostgreSQL credentials configured
- [ ] Anthropic credentials configured
- [ ] Workflow activated
- [ ] Webhook tested successfully
- [ ] Database records verified
- [ ] Monitoring set up
- [ ] Backup strategy in place

---

## 🎉 Congratulations!

You've successfully deployed CoCounsel to n8n Cloud!

**Your live endpoints:**
- n8n Editor: `https://YOUR-INSTANCE.app.n8n.cloud`
- Webhook: `https://YOUR-INSTANCE.app.n8n.cloud/webhook/legal-research`
- Supabase Dashboard: `https://app.supabase.com/project/YOUR-PROJECT`

**Test query:**
```bash
curl -X POST https://YOUR-INSTANCE.app.n8n.cloud/webhook/legal-research \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What are the remedies for breach of contract?",
    "jurisdiction": "federal",
    "practiceArea": "contract",
    "userId": "test_user"
  }'
```

---

**Built with ❤️ for the legal community**
