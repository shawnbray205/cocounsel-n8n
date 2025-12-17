*CoCounsel User's Guide* 

**CoCounsel** 

*Legal Research Agent \- User's Guide* 

Complete Setup, Configuration & Troubleshooting 

Version 2.0 \- December 2025 

**Table of Contents** 

1\. Introduction 

2\. Prerequisites 

3\. Database Setup (Supabase PostgreSQL) 

4\. Anthropic API Configuration 

5\. Case Law Search Node Setup 

6\. Workflow Architecture 

7\. Testing the Workflow 

8\. Troubleshooting Guide 

9\. Appendix: Complete SQL Schemas 

Page 1 of 12  
*CoCounsel User's Guide* 

**1\. Introduction** 

CoCounsel is a multi-agent legal research system built in n8n that processes legal queries  through a pipeline of five specialized AI agents. Inspired by Thomson Reuters' CoCounsel  platform, it automates the identification of legal issues, analysis of case law, synthesis of  findings, quality assessment, and generation of professional legal memoranda. 

**Key Features** 

• **Five specialized AI agents** powered by Claude Sonnet 4   
• **Quality-based routing:** Score ≥80 auto-drafts memorandum, \<80 flags for expert  review 

• **Session memory tracking** through decision trail   
• **PostgreSQL persistence** with three tables: research\_results, review\_queue,  audit\_log 

• **Structured JSON output** with JSONB storage for complex data   
• **RESTful webhook API** for easy integration 

**Agent Pipeline** 

| Agent  | Purpose  | Temperature |
| :---- | :---- | :---- |
| **Issue Spotter**  | Identifies legal issues, generates search  terms | 0.3 |
| **Case Analysis**  | Analyzes case law, extracts holdings  | 0.2 |
| **Legal Synthesis**  | Creates executive summary, analysis,  recommendations | 0.3 |
| **Quality Assurance**  | Scores quality (0-100), flags gaps  | 0.2 |
| **Memorandum   Drafter** | Generates formal legal memorandum  | 0.4 |

Page 2 of 12  
*CoCounsel User's Guide* 

**2\. Prerequisites** 

Before setting up CoCounsel, ensure you have the following: 

**Required Accounts & API Keys** 

1\. **n8n Instance:** Self-hosted or n8n.cloud account   
2\. **Anthropic API Key:** For Claude Sonnet 4 (claude-sonnet-4-20250514) 3\. **Supabase Account:** For PostgreSQL database (free tier available) 4\. **CourtListener Account (Optional):** For live case law search API 

**System Requirements** 

• n8n version 1.0 or higher   
• PostgreSQL 14+ (provided by Supabase)   
• Network access to api.anthropic.com and courtlistener.com 

Page 3 of 12  
*CoCounsel User's Guide* 

**3\. Database Setup (Supabase PostgreSQL)** 

**Step 1: Create Supabase Project** 

1\. Go to https://supabase.com and sign in   
2\. Click "New Project"   
3\. Select your organization and enter project details   
4\. **IMPORTANT:** Save your database password securely   
5\. Select a region close to your n8n instance   
6\. Wait for project initialization (2-3 minutes) 

**Step 2: Get Connection Details** 

Navigate to **Project Settings → Database** and note these values: 

| Setting  | Value |
| :---- | :---- |
| **Host**  | aws-0-\[region\].pooler.supabase.com |
| **Port**  | **6543** (Transaction Pooler \- RECOMMENDED) |
| **Database**  | postgres |
| **User**  | postgres.\[project-ref\] |
| **SSL**  | **Required** \- Must be enabled |

**TIP:** Use port 6543 (transaction pooler) for n8n. Port 5432 is for direct connections and may  cause pool exhaustion. 

**Step 3: Create Database Tables** 

Open the **SQL Editor** in Supabase and run the following SQL scripts. See **Appendix:  Complete SQL Schemas** for full table definitions. 

**WARNING:** Never hardcode id values in INSERT statements. The id column uses SERIAL for  auto-generation. 

Page 4 of 12  
*CoCounsel User's Guide* 

**4\. Anthropic API Configuration** 

**Step 1: Create API Credential in n8n** 

1\. In n8n, go to Settings → Credentials   
2\. Click "Add Credential" → Select "Anthropic"   
3\. Enter your Anthropic API key   
4\. Save the credential 

**Step 2: Configure Agent Nodes** 

Each AI agent node uses the same model but different temperatures: 

| Node Name  | Model  | Temperature |
| :---- | :---- | :---- |
| Anthropic Model \- Issue   Spotter | claude-sonnet-4-20250514  | 0.3 |
| Anthropic Model \- Case   Analysis | claude-sonnet-4-20250514  | 0.2 |
| Anthropic Model \- Synthesis  | claude-sonnet-4-20250514  | 0.3 |
| Anthropic Model \- QA  | claude-sonnet-4-20250514  | 0.2 |
| Anthropic Model \-   Memorandum | claude-sonnet-4-20250514  | 0.4 |

Page 5 of 12  
*CoCounsel User's Guide* 

**5\. Case Law Search Node Setup** 

The Case Law Search node retrieves relevant case law based on search terms from the  Issue Spotter. You have two options: use the Mock Case Law node for testing, or configure  the CourtListener API for live data. 

**CRITICAL:** The most common workflow failure occurs when this node returns wrong data or  empty results. Follow these instructions carefully. 

**Option A: Mock Case Law (Recommended for Testing)** 

The workflow includes a "Mock Code in JavaScript" node that returns realistic California non compete case law. To use it: 

1\. Open the workflow in n8n editor   
2\. Disconnect "Split Search Queries" from "Case Law Database Search" 3\. Connect "Split Search Queries" → "Mock Code in JavaScript" 

4\. Connect "Mock Code in JavaScript" → "Case Analysis Agent" 

**Option B: CourtListener API (Live Data)** 

To use the free CourtListener API for federal case law: 

**Step 1: Get API Token** 

1\. Create account at https://www.courtlistener.com/sign-in/   
2\. Go to your profile and generate an API token   
3\. Note: Rate limit is 5,000 requests/hour 

**Step 2: Configure HTTP Request Node** 

**CRITICAL:** The URL must include /search/ at the end. Missing this is the \#1 cause of failures. 

| Setting  | Value |
| :---- | :---- |
| **Method**  | GET |
| **URL**  | **https://www.courtlistener.com/api/rest/v4/search/** |

**Headers:** 

Authorization: Token YOUR\_API\_TOKEN 

**Query Parameters** (NOT Headers\!): 

| Parameter  | Value |
| :---- | :---- |
| **q**  | {{ $json.workingMemory.legalContext.searchTerms.join(' ') }} |
| **type**  | o |
| **order\_by**  | score desc |

**COMMON MISTAKE:** Putting q, type, and order\_by in the Headers section instead of Query  Parameters. This will cause the API to return an index of endpoints instead of search results. 

Page 6 of 12  
*CoCounsel User's Guide* 

**6\. Workflow Architecture** 

The workflow follows this execution path: 

Webhook \- Legal Query 

 ↓ 

Parse Legal Query → Initialize Working Memory 

 ↓ 

Issue Spotter Agent → Update Memory 

 ↓ 

Split Search Queries → Case Law Database Search 

 ↓ 

Case Analysis Agent → Merge All Analyses 

 ↓ 

Legal Synthesis Agent → Update Memory 

 ↓ 

Quality Assurance Agent 

 ↓ 

┌───────────────────────────────────────────┐ 

│ Needs Expert Review? │ 

│ Score \< 80 │ Score ≥ 80 │ 

└─────────┬───────────┴──────────┬──────────┘ 

 ↓ ↓ 

 Flag for Review Draft Legal Memorandum 

 ↓ ↓ 

 └──────────┬───────────┘ 

 ↓ 

 Prepare Database Insert 

 ↓ 

 Save to PostgreSQL (research\_results) 

 ↓ 

 Audit Log → Format Response 

 ↓ 

Page 7 of 12  
*CoCounsel User's Guide* 

**7\. Testing the Workflow** 

**Webhook Request Format** 

Send a POST request to your webhook URL: 

POST https://your-n8n-instance/webhook/legal-research 

Content-Type: application/json 

{ 

 "query": "Can an employer require a 2-year non-compete?", 

 "userId": "user\_001", 

 "jurisdiction": "California", 

 "practiceArea": "Employment Law" 

} 

**cURL Test Command** 

curl \-X POST https://your-n8n-instance/webhook/legal-research \\  \-H "Content-Type: application/json" \\ 

 \-d '{ 

 "query": "Is a non-compete enforceable in California?", 

 "userId": "test\_001", 

 "jurisdiction": "California", 

 "practiceArea": "Employment Law" 

 }' 

**Expected Success Response** 

{ 

 "sessionId": "session\_1234567890\_abc123", 

 "status": "completed", 

 "needsExpertReview": false, 

 "qualityScore": 85, 

 "confidenceRating": "high", 

 "memorandum": "LEGAL MEMORANDUM...", 

 "message": "Research completed successfully." 

} 

Page 8 of 12  
*CoCounsel User's Guide* 

**8\. Troubleshooting Guide** 

**Error: "Model output doesn't fit required format"** 

**Symptom:** Workflow fails at Case Analysis Agent, Quality Assurance Agent, or other AI  nodes with output parser errors. 

**Root Cause:** The AI model received empty or malformed input data, so it responded with a  clarifying question instead of JSON output. 

**Solutions:** 

1\. **Check Case Law Search output:** Run the workflow and inspect what the Case Law  Database Search node returns. If it returns an API index (list of endpoints), the URL  is wrong. 

2\. **Fix the URL:** Ensure URL is https://www.courtlistener.com/api/rest/v4/search/  (with /search/ at the end) 

3\. **Check Query Parameters:** Move q, type, order\_by from Headers to Query  Parameters 

4\. **Use Mock Data:** Switch to the Mock Case Law node to isolate the issue 

**Error: "duplicate key value violates unique constraint" Symptom:** Audit Log or Save Results node fails with primary key violation. **Root Cause:** The PostgreSQL node has a hardcoded id: 0 in the column mappings. **Solution:** 

• Open the PostgreSQL node (Audit Log or Save Results)   
• In Columns section, find the "id" field   
• Either remove it entirely or mark it as "removed" \- let PostgreSQL auto-generate 

**Error: "Connection refused" or "SSL required"** 

**Root Cause:** Incorrect PostgreSQL connection settings. 

**Solutions:** 

• Use port 6543 (transaction pooler), not 5432   
• Enable SSL in the n8n PostgreSQL credential   
• Verify host format: aws-0-\[region\].pooler.supabase.com 

**Error: "Invalid input syntax for type json"** 

**Root Cause:** JSONB columns receiving non-stringified data. 

**Solution:** 

• In "Prepare Database Insert" code node, ensure all JSONB fields use  JSON.stringify(): 

legal\_issues: JSON.stringify(issueSpotterOutput?.legalIssues || \[\]) **Error: Empty response or "Query: " with no data**   
**Symptom:** Case Analysis Agent prompt shows "Query: \[empty\]" or "Search Results:  \[empty\]" 

**Root Cause:** The Case Analysis Agent's text field uses incorrect expression paths. **Solution:** 

Page 9 of 12  
*CoCounsel User's Guide* 

Update the Case Analysis Agent's text field: 

Query: {{ $('Parse Legal Query').item.json.originalQuery }} 

Jurisdiction: {{ $('Parse Legal Query').item.json.jurisdiction }} Search Results: {{ JSON.stringify($json) }} 

Page 10 of 12  
*CoCounsel User's Guide* 

**9\. Appendix: Complete SQL Schemas** 

**Table: research\_results** 

CREATE TABLE research\_results ( 

 id SERIAL PRIMARY KEY, 

 session\_id TEXT NOT NULL, 

 user\_id TEXT NOT NULL, 

 original\_query TEXT, 

 jurisdiction TEXT, 

 practice\_area TEXT, 

 legal\_issues JSONB, 

 search\_terms JSONB, 

 practice\_areas JSONB, 

 case\_analyses JSONB, 

 relevant\_cases JSONB, 

 key\_findings JSONB, 

 executive\_summary TEXT, 

 legal\_analysis TEXT, 

 precedents JSONB, 

 recommendations JSONB, 

 quality\_score INTEGER, 

 confidence\_rating TEXT, 

 expert\_review\_needed BOOLEAN, 

 quality\_gaps JSONB, 

 quality\_strengths JSONB, 

 memorandum TEXT, 

 created\_at TIMESTAMPTZ DEFAULT NOW(), 

 updated\_at TIMESTAMPTZ DEFAULT NOW() 

); 

**Table: audit\_log** 

CREATE TABLE audit\_log ( 

 id SERIAL PRIMARY KEY, 

 session\_id TEXT NOT NULL, 

 user\_id TEXT NOT NULL, 

 workflow\_path TEXT NOT NULL, 

 final\_action TEXT NOT NULL, 

 status TEXT, 

 started\_at TIMESTAMPTZ NOT NULL, 

 completed\_at TIMESTAMPTZ NOT NULL, 

 execution\_time\_seconds INTEGER, 

 quality\_score INTEGER, 

 confidence\_rating TEXT, 

 expert\_review\_needed BOOLEAN, 

 original\_query TEXT, 

 jurisdiction TEXT, 

 practice\_area TEXT, 

 cases\_analyzed INTEGER, 

 issues\_identified INTEGER, 

 recommendations\_generated INTEGER, 

Page 11 of 12  
*CoCounsel User's Guide* 

 metadata JSONB, 

 created\_at TIMESTAMPTZ DEFAULT NOW() 

); 

**Indexes** 

CREATE INDEX idx\_research\_results\_session ON research\_results(session\_id); CREATE INDEX idx\_research\_results\_user ON research\_results(user\_id); CREATE INDEX idx\_audit\_log\_session ON audit\_log(session\_id); 

CREATE INDEX idx\_audit\_log\_user ON audit\_log(user\_id); 

CREATE INDEX idx\_audit\_log\_status ON audit\_log(status); 

*— End of User's Guide —* 

Page 12 of 12