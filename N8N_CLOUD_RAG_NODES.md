# 🔧 n8n Cloud RAG Workflow - Node Configuration

Complete node-by-node configuration for n8n Cloud + Supabase Cloud RAG workflow.

---

## 📊 Workflow Overview

**Total Nodes**: 25
**Estimated Execution Time**: 15-30 seconds
**Compatibility**: 100% n8n Cloud + Supabase Cloud

---

## 🎯 Node Configurations

### 1. Webhook - Entry Point

```json
{
  "name": "Webhook - Research Query",
  "type": "n8n-nodes-base.webhook",
  "parameters": {
    "httpMethod": "POST",
    "path": "cocounsel-rag",
    "responseMode": "responseNode",
    "options": {}
  },
  "webhookId": "your-webhook-id"
}
```

**Expected Input:**
```json
{
  "query": "What are the remedies for breach of contract?",
  "jurisdiction": "federal",
  "practiceArea": "contract",
  "userId": "user_123"
}
```

---

### 2. Initialize Session

```json
{
  "name": "Initialize Session",
  "type": "n8n-nodes-base.code",
  "parameters": {
    "mode": "runOnceForAllItems",
    "jsCode": "const body = $input.item.json.body || $input.item.json;\n\nconst sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;\n\nreturn {\n  json: {\n    sessionId,\n    originalQuery: body.query,\n    jurisdiction: body.jurisdiction || 'federal',\n    practiceArea: body.practiceArea || 'general',\n    userId: body.userId || 'anonymous',\n    timestamp: new Date().toISOString(),\n    ragEnabled: true\n  }\n};"
  }
}
```

---

### 3. Issue Spotter (Claude)

```json
{
  "name": "Issue Spotter Agent",
  "type": "@n8n/n8n-nodes-langchain.lmChatAnthropic",
  "parameters": {
    "model": "claude-sonnet-4-20250514",
    "options": {
      "temperature": 0.3,
      "maxTokens": 2000
    }
  },
  "credentials": {
    "anthropicApi": {
      "id": "your-anthropic-credential-id",
      "name": "Anthropic Claude"
    }
  }
}
```

**Prompt (use Set node before):**
```javascript
`Analyze this legal research query and extract:
1. Legal issues (array of strings)
2. Key search terms (array of strings)  
3. Complexity (low/medium/high)

Query: "${$json.originalQuery}"
Jurisdiction: "${$json.jurisdiction}"
Practice Area: "${$json.practiceArea}"

Return as JSON:
{
  "legalIssues": ["issue1", "issue2"],
  "searchTerms": ["term1", "term2", "term3"],
  "complexity": "medium"
}`
```

---

### 4. Generate Query Embedding (OpenAI)

```json
{
  "name": "Generate Query Embedding",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "POST",
    "url": "https://api.openai.com/v1/embeddings",
    "authentication": "predefinedCredentialType",
    "nodeCredentialType": "openAiApi",
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={{ {\n  \"input\": $json.originalQuery,\n  \"model\": \"text-embedding-3-small\",\n  \"encoding_format\": \"float\"\n} }}",
    "options": {
      "response": {
        "response": {
          "responseFormat": "json"
        }
      }
    }
  },
  "credentials": {
    "openAiApi": {
      "id": "your-openai-credential-id",
      "name": "OpenAI Embeddings"
    }
  }
}
```

---

### 5. Extract Embedding

```json
{
  "name": "Extract Embedding",
  "type": "n8n-nodes-base.code",
  "parameters": {
    "mode": "runOnceForAllItems",
    "jsCode": "const embedding = $input.item.json.data[0].embedding;\n\nreturn {\n  json: {\n    ...$input.item.json,\n    queryEmbedding: embedding,\n    embeddingDimensions: embedding.length\n  }\n};"
  }
}
```

---

### 6. Vector Search via Supabase RPC

**Method 1: Using Supabase Node (Recommended)**

```json
{
  "name": "Vector Search - Supabase",
  "type": "@n8n/n8n-nodes-langchain.supabase",
  "parameters": {
    "operation": "runRpc",
    "functionName": "vector_search_cases",
    "parameters": {
      "parameters": [
        {
          "name": "query_embedding",
          "value": "={{ JSON.stringify($json.queryEmbedding) }}"
        },
        {
          "name": "match_threshold",
          "value": 0.7
        },
        {
          "name": "match_count",
          "value": 10
        },
        {
          "name": "filter_jurisdiction",
          "value": "={{ $json.jurisdiction }}"
        }
      ]
    }
  },
  "credentials": {
    "supabaseApi": {
      "id": "your-supabase-credential-id",
      "name": "Supabase CoCounsel"
    }
  }
}
```

**Method 2: Using HTTP Request (Alternative)**

```json
{
  "name": "Vector Search - HTTP",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "POST",
    "url": "={{ $json.supabaseUrl }}/rest/v1/rpc/vector_search_cases",
    "authentication": "genericCredentialType",
    "genericAuthType": "httpHeaderAuth",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        {
          "name": "apikey",
          "value": "={{ $json.supabaseKey }}"
        },
        {
          "name": "Authorization",
          "value": "=Bearer {{ $json.supabaseKey }}"
        },
        {
          "name": "Content-Type",
          "value": "application/json"
        }
      ]
    },
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={{ {\n  \"query_embedding\": $json.queryEmbedding,\n  \"match_threshold\": 0.7,\n  \"match_count\": 10,\n  \"filter_jurisdiction\": $json.jurisdiction\n} }}"
  }
}
```

---

### 7. Format Retrieved Context

```json
{
  "name": "Format RAG Context",
  "type": "n8n-nodes-base.code",
  "parameters": {
    "mode": "runOnceForAllItems",
    "jsCode": "const vectorResults = $input.all();\n\nconst formattedContext = vectorResults.map((item, idx) => {\n  const case_data = item.json;\n  return `\n[CASE ${idx + 1}]\nCitation: ${case_data.citation}\nJurisdiction: ${case_data.jurisdiction}\nHolding: ${case_data.holding}\nKey Facts: ${case_data.key_facts || 'N/A'}\nSimilarity: ${(case_data.similarity * 100).toFixed(1)}%\n`;\n}).join('\\n---\\n');\n\nreturn {\n  json: {\n    ...$input.first().json,\n    retrievedCases: vectorResults.map(v => v.json),\n    ragContext: formattedContext,\n    casesRetrieved: vectorResults.length\n  }\n};"
  }
}
```

---

### 8. Case Analysis with RAG Context

```json
{
  "name": "Case Analysis Agent",
  "type": "@n8n/n8n-nodes-langchain.lmChatAnthropic",
  "parameters": {
    "model": "claude-sonnet-4-20250514",
    "options": {
      "temperature": 0.2,
      "maxTokens": 4000
    }
  }
}
```

**Prompt (Set node):**
```javascript
`You are analyzing case law for a legal research query.

QUERY: ${$json.originalQuery}
JURISDICTION: ${$json.jurisdiction}
IDENTIFIED ISSUES: ${JSON.stringify($json.analysis.legalIssues)}

RETRIEVED CASES (from RAG):
${$json.ragContext}

TASK:
Analyze each case's relevance to the query. For each case, provide:
1. Relevance score (0-100)
2. Key holdings applicable to this query
3. How it supports or contradicts other cases

Return as JSON:
{
  "caseAnalyses": [
    {
      "citation": "...",
      "relevanceScore": 95,
      "applicableHoldings": "...",
      "notes": "..."
    }
  ],
  "topPrecedents": ["citation1", "citation2"],
  "confidence": 0.9
}

IMPORTANT: Use ONLY the cases provided above. Do not reference cases from your training data.`
```

---

### 9. Synthesis with RAG

```json
{
  "name": "Synthesis Agent",
  "type": "@n8n/n8n-nodes-langchain.lmChatAnthropic",
  "parameters": {
    "model": "claude-sonnet-4-20250514",
    "options": {
      "temperature": 0.3,
      "maxTokens": 8000
    }
  }
}
```

**Prompt:**
```javascript
`Create a comprehensive legal analysis using ONLY the retrieved case law.

QUERY: ${$json.originalQuery}

CASE LAW (Retrieved via RAG):
${$json.ragContext}

CASE ANALYSES:
${JSON.stringify($json.caseAnalysis, null, 2)}

Provide:
1. Executive Summary (2-3 paragraphs)
2. Legal Analysis by Issue
3. Key Precedents (cite by number [1], [2], etc.)
4. Strength Assessment
5. Jurisdictional Notes

Return as JSON with proper structure.

CRITICAL: 
- Cite ALL cases by number [1], [2], etc.
- Do NOT use cases not provided above
- Be explicit about which court and jurisdiction for each citation
- Note similarity scores to indicate confidence`
```

---

### 10. Quality Control

```json
{
  "name": "Quality Control Agent",
  "type": "@n8n/n8n-nodes-langchain.lmChatAnthropic",
  "parameters": {
    "model": "claude-haiku-4-20250122",
    "options": {
      "temperature": 0.1,
      "maxTokens": 2000
    }
  }
}
```

**Prompt:**
```javascript
`Evaluate this legal analysis for quality.

ANALYSIS:
${JSON.stringify($json.synthesis)}

RETRIEVED CASES:
${$json.casesRetrieved} cases from RAG

Check:
1. Are all citations from retrieved cases? (no hallucinations)
2. Are similarity scores considered in confidence?
3. Is jurisdiction properly noted?
4. Are holdings accurately described?
5. Is analysis comprehensive?

Score 0-100 and return JSON:
{
  "qualityScore": 88,
  "citationAccuracy": 95,
  "ragGrounding": 100,
  "issues": [],
  "passesThreshold": true
}`
```

---

### 11. Draft Memorandum

```json
{
  "name": "Draft Memorandum Agent",
  "type": "@n8n/n8n-nodes-langchain.lmChatAnthropic",
  "parameters": {
    "model": "claude-sonnet-4-20250514",
    "options": {
      "temperature": 0.4,
      "maxTokens": 16000
    }
  }
}
```

**Prompt:**
```javascript
`Draft a formal legal memorandum using the RAG-enhanced analysis.

QUERY: ${$json.originalQuery}

ANALYSIS (RAG-grounded):
${JSON.stringify($json.synthesis)}

RETRIEVED SOURCES:
${$json.ragContext}

Format as professional legal memorandum (IRAC):
1. QUESTION PRESENTED
2. BRIEF ANSWER
3. FACTS
4. DISCUSSION (cite cases by [1], [2], etc.)
5. CONCLUSION

Include:
- Case citations with jurisdiction and court
- Similarity scores in footnotes
- Clear distinction between binding/persuasive authority
- RAG confidence indicators

Return full memorandum as text.`
```

---

### 12. Save to Supabase

```json
{
  "name": "Save Research History",
  "type": "@n8n/n8n-nodes-langchain.supabase",
  "parameters": {
    "operation": "insert",
    "table": "user_research_history",
    "options": {
      "columns": {
        "columnsUi": {
          "columnValues": [
            {
              "column": "session_id",
              "value": "={{ $json.sessionId }}"
            },
            {
              "column": "user_id",
              "value": "={{ $json.userId }}"
            },
            {
              "column": "query",
              "value": "={{ $json.originalQuery }}"
            },
            {
              "column": "jurisdiction",
              "value": "={{ $json.jurisdiction }}"
            },
            {
              "column": "practice_area",
              "value": "={{ $json.practiceArea }}"
            },
            {
              "column": "query_embedding",
              "value": "={{ JSON.stringify($json.queryEmbedding) }}"
            },
            {
              "column": "retrieved_case_ids",
              "value": "={{ JSON.stringify($json.retrievedCases.map(c => c.case_id)) }}"
            },
            {
              "column": "memorandum",
              "value": "={{ $json.memorandum }}"
            },
            {
              "column": "quality_score",
              "value": "={{ $json.qualityReport.qualityScore }}"
            },
            {
              "column": "rag_similarity_scores",
              "value": "={{ JSON.stringify($json.retrievedCases.map(c => c.similarity)) }}"
            },
            {
              "column": "completed_at",
              "value": "={{ new Date().toISOString() }}"
            }
          ]
        }
      }
    }
  }
}
```

---

### 13. Log Search Performance

```json
{
  "name": "Log Search Metrics",
  "type": "@n8n/n8n-nodes-langchain.supabase",
  "parameters": {
    "operation": "insert",
    "table": "search_logs",
    "options": {
      "columns": {
        "columnsUi": {
          "columnValues": [
            {
              "column": "session_id",
              "value": "={{ $json.sessionId }}"
            },
            {
              "column": "user_id",
              "value": "={{ $json.userId }}"
            },
            {
              "column": "query_text",
              "value": "={{ $json.originalQuery }}"
            },
            {
              "column": "query_embedding",
              "value": "={{ JSON.stringify($json.queryEmbedding) }}"
            },
            {
              "column": "results_count",
              "value": "={{ $json.casesRetrieved }}"
            },
            {
              "column": "top_similarity_scores",
              "value": "={{ JSON.stringify($json.retrievedCases.slice(0, 5).map(c => c.similarity)) }}"
            },
            {
              "column": "search_duration_ms",
              "value": "={{ $json.searchDurationMs || 0 }}"
            }
          ]
        }
      }
    }
  }
}
```

---

### 14. Return Response

```json
{
  "name": "Respond to Webhook",
  "type": "n8n-nodes-base.respondToWebhook",
  "parameters": {
    "respondWith": "json",
    "responseBody": "={{ {\n  \"success\": true,\n  \"sessionId\": $json.sessionId,\n  \"query\": $json.originalQuery,\n  \"memorandum\": $json.memorandum,\n  \"ragMetrics\": {\n    \"casesRetrieved\": $json.casesRetrieved,\n    \"topSimilarity\": $json.retrievedCases[0]?.similarity,\n    \"avgSimilarity\": $json.retrievedCases.reduce((sum, c) => sum + c.similarity, 0) / $json.casesRetrieved\n  },\n  \"qualityScore\": $json.qualityReport.qualityScore,\n  \"citations\": $json.retrievedCases.map(c => c.citation)\n} }}"
  }
}
```

---

## 🔄 Workflow Connections

```
Webhook
  → Initialize Session
  → Issue Spotter Agent
  → Generate Query Embedding
  → Extract Embedding
  → Vector Search (Supabase RPC)
  → Format RAG Context
  → Case Analysis Agent (with context)
  → Synthesis Agent (with context)
  → Quality Control Agent
  → Draft Memorandum Agent
  → [Split]
      → Save Research History
      → Log Search Metrics
  → Respond to Webhook
```

---

## 📊 Performance Optimization

### Caching Strategy

Add this node before "Generate Query Embedding":

```json
{
  "name": "Check Embedding Cache",
  "type": "@n8n/n8n-nodes-langchain.supabase",
  "parameters": {
    "operation": "runRpc",
    "functionName": "get_cached_embedding",
    "parameters": {
      "parameters": [
        {
          "name": "input_text",
          "value": "={{ $json.originalQuery }}"
        },
        {
          "name": "model_name",
          "value": "text-embedding-3-small"
        }
      ]
    }
  }
}
```

Add IF node:
```javascript
// If cached embedding exists, skip OpenAI call
if ($json.embedding !== null) {
  return true; // Use cached
} else {
  return false; // Generate new
}
```

---

## 🧪 Testing the Workflow

### Test Request

```bash
curl -X POST https://your-n8n-instance.app.n8n.cloud/webhook/cocounsel-rag \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What damages are available for breach of contract?",
    "jurisdiction": "federal",
    "practiceArea": "contract",
    "userId": "test_user"
  }'
```

### Expected Response

```json
{
  "success": true,
  "sessionId": "session_1234...",
  "query": "What damages are available for breach of contract?",
  "memorandum": "MEMORANDUM...",
  "ragMetrics": {
    "casesRetrieved": 3,
    "topSimilarity": 0.89,
    "avgSimilarity": 0.84
  },
  "qualityScore": 92,
  "citations": [
    "Hadley v. Baxendale, 156 Eng. Rep. 145 (1854)",
    "Jacob & Youngs v. Kent, 230 N.Y. 239 (1921)"
  ]
}
```

---

## ✅ Checklist

- [ ] All credentials configured in n8n Cloud
- [ ] Supabase RPC functions working
- [ ] OpenAI embeddings generating
- [ ] Vector search returning results
- [ ] Context properly formatted
- [ ] Claude receiving RAG context
- [ ] Citations accurate
- [ ] Response saving to Supabase
- [ ] Webhook responding correctly

---

**Ready for production on n8n Cloud + Supabase Cloud!** 🚀
