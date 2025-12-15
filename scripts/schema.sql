-- ============================================
-- CoCounsel Database Schema
-- PostgreSQL 15 with pgvector extension
-- ============================================

-- Note: Extensions and users are created in init-db.sh
-- This file contains the application schema only

-- ============================================
-- USER RESEARCH HISTORY TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS user_research_history (
    id SERIAL PRIMARY KEY,
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
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_id ON user_research_history(user_id);
CREATE INDEX IF NOT EXISTS idx_session_id ON user_research_history(session_id);
CREATE INDEX IF NOT EXISTS idx_practice_area ON user_research_history(practice_area);
CREATE INDEX IF NOT EXISTS idx_jurisdiction ON user_research_history(jurisdiction);
CREATE INDEX IF NOT EXISTS idx_created_at ON user_research_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_quality_score ON user_research_history(quality_score) WHERE quality_score IS NOT NULL;

-- ============================================
-- USER PREFERENCES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS user_preferences (
    user_id VARCHAR(255) PRIMARY KEY,
    preferred_jurisdictions JSONB DEFAULT '[]'::jsonb,
    practice_areas JSONB DEFAULT '[]'::jsonb,
    citation_style VARCHAR(50) DEFAULT 'bluebook',
    detail_level VARCHAR(20) DEFAULT 'comprehensive',
    language_preferences JSONB DEFAULT '{"formality": "professional", "technical_depth": "high"}'::jsonb,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- RESEARCH PATTERNS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS research_patterns (
    id SERIAL PRIMARY KEY,
    query_pattern TEXT NOT NULL,
    successful_search_terms JSONB,
    relevant_cases JSONB,
    average_quality_score FLOAT,
    usage_count INTEGER DEFAULT 1,
    last_used TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT unique_query_pattern UNIQUE (query_pattern)
);

-- Index for pattern matching
CREATE INDEX IF NOT EXISTS idx_query_pattern ON research_patterns(query_pattern);
CREATE INDEX IF NOT EXISTS idx_quality_score_patterns ON research_patterns(average_quality_score DESC);

-- ============================================
-- EXPERT LESSONS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS learning_examples (
    id SERIAL PRIMARY KEY,
    query_type VARCHAR(100) NOT NULL,
    lesson_learned TEXT NOT NULL,
    correct_analysis TEXT,
    incorrect_analysis JSONB,
    importance_weight FLOAT DEFAULT 1.0,
    examples JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_query_type ON learning_examples(query_type);
CREATE INDEX IF NOT EXISTS idx_importance ON learning_examples(importance_weight DESC);

-- ============================================
-- CASE KNOWLEDGE BASE TABLE (with vectors)
-- ============================================

CREATE TABLE IF NOT EXISTS case_knowledge_base (
    case_id VARCHAR(255) PRIMARY KEY,
    citation TEXT NOT NULL,
    jurisdiction VARCHAR(100) NOT NULL,
    court VARCHAR(255),
    decision_date DATE,
    
    -- Case content
    holding TEXT,
    key_facts TEXT,
    legal_issues JSONB,
    full_text TEXT,
    
    -- Metadata
    authority_level VARCHAR(50), -- binding, persuasive, etc.
    times_cited INTEGER DEFAULT 0,
    
    -- Vector embedding for semantic search
    embedding VECTOR(1536),
    
    -- Timestamps
    last_updated TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_jurisdiction_cases ON case_knowledge_base(jurisdiction);
CREATE INDEX IF NOT EXISTS idx_citation ON case_knowledge_base(citation);
CREATE INDEX IF NOT EXISTS idx_authority ON case_knowledge_base(authority_level);
CREATE INDEX IF NOT EXISTS idx_decision_date ON case_knowledge_base(decision_date DESC);

-- Vector index for similarity search
CREATE INDEX IF NOT EXISTS idx_case_embedding ON case_knowledge_base 
USING ivfflat (embedding vector_cosine_ops) 
WITH (lists = 100);

-- ============================================
-- EXPERT REVIEW QUEUE TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS expert_review_queue (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    query TEXT NOT NULL,
    
    -- Content for review
    analysis JSONB,
    memorandum TEXT,
    quality_issues JSONB,
    quality_score INTEGER,
    
    -- Queue management
    priority VARCHAR(20) DEFAULT 'medium', -- high, medium, low
    status VARCHAR(20) DEFAULT 'pending', -- pending, in_review, completed
    assigned_expert VARCHAR(255),
    
    -- Expert feedback
    expert_feedback JSONB,
    reviewed_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW(),
    
    FOREIGN KEY (session_id) REFERENCES user_research_history(session_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_status ON expert_review_queue(status);
CREATE INDEX IF NOT EXISTS idx_priority ON expert_review_queue(priority);
CREATE INDEX IF NOT EXISTS idx_user_id_queue ON expert_review_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_created_at_queue ON expert_review_queue(created_at DESC);

-- ============================================
-- AUDIT LOG TABLE (for compliance)
-- ============================================

CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255),
    user_id VARCHAR(255) NOT NULL,
    action VARCHAR(100) NOT NULL,
    details JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_action ON audit_log(user_id, action);
CREATE INDEX IF NOT EXISTS idx_session_audit ON audit_log(session_id);
CREATE INDEX IF NOT EXISTS idx_created_at_audit ON audit_log(created_at DESC);

-- ============================================
-- HELPER FUNCTION: Generate Embeddings
-- ============================================

-- Placeholder function - replace with actual embedding API
CREATE OR REPLACE FUNCTION generate_embedding(input_text TEXT)
RETURNS TABLE(embedding VECTOR(1536)) AS $$
BEGIN
    -- In production, call your embedding service (OpenAI, Cohere, etc.)
    -- This is a mock that returns a zero vector for development
    RETURN QUERY SELECT array_fill(0, ARRAY[1536])::VECTOR(1536);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- VIEWS FOR ANALYTICS
-- ============================================

CREATE OR REPLACE VIEW user_research_stats AS
SELECT 
    user_id,
    COUNT(*) as total_researches,
    AVG(quality_score) as avg_quality,
    AVG(retry_count) as avg_retries,
    COUNT(CASE WHEN needs_expert_review THEN 1 END) as expert_reviews_needed,
    MAX(completed_at) as last_research_date
FROM user_research_history
GROUP BY user_id;

CREATE OR REPLACE VIEW quality_trends AS
SELECT 
    DATE(created_at) as research_date,
    practice_area,
    AVG(quality_score) as avg_quality,
    COUNT(*) as research_count,
    COUNT(CASE WHEN needs_expert_review THEN 1 END) as reviews_needed
FROM user_research_history
WHERE completed_at IS NOT NULL
GROUP BY DATE(created_at), practice_area
ORDER BY research_date DESC;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

-- Grant permissions to application user
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO cocounsel_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO cocounsel_app;
GRANT EXECUTE ON FUNCTION generate_embedding(TEXT) TO cocounsel_app;

-- Grant SELECT on views
GRANT SELECT ON user_research_stats TO cocounsel_app;
GRANT SELECT ON quality_trends TO cocounsel_app;

-- ============================================
-- COMPLETION MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE 'CoCounsel database schema created successfully!';
    RAISE NOTICE 'Tables created: 7';
    RAISE NOTICE 'Views created: 2';
    RAISE NOTICE 'Functions created: 1';
END $$;
