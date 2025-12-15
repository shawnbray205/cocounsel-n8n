# CoCounsel n8n - Legal Research Agent for n8n

A complete Docker-based deployment of the CoCounsel Legal Research Agent for n8n, featuring integrated Supabase (PostgreSQL with pgvector), automated setup, and production-ready configuration.

[![n8n](https://img.shields.io/badge/n8n-latest-orange.svg)](https://n8n.io/)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green.svg)](https://supabase.com/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://www.docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🎯 Overview

This repository provides a complete, production-ready Docker environment for running the CoCounsel Legal Research Agent in n8n. Everything you need is included:

- ✅ **n8n** - Workflow automation platform
- ✅ **Supabase** - PostgreSQL database with pgvector extension
- ✅ **Supabase Studio** - Database management UI
- ✅ **Redis** - Caching and session storage
- ✅ **Traefik** - Reverse proxy with automatic SSL (optional)
- ✅ **Automated Setup** - Database initialization, user creation, schema deployment
- ✅ **Pre-configured Workflow** - CoCounsel workflow JSON included
- ✅ **Mock Data** - Test data for immediate functionality

## ✨ Features

### 🚀 One-Command Deployment
```bash
docker compose up -d
```
Everything starts automatically with proper networking and dependencies.

### 🗄️ Supabase Integration
- PostgreSQL 15 with pgvector extension
- Supabase Studio for database management
- Automated schema creation with all tables
- Mock data pre-loaded for testing
- Connection pooling configured

### 🔐 Security Built-in
- Encrypted environment variables
- Database user isolation
- Network segmentation
- Optional SSL/TLS with Traefik
- API key authentication

### 📊 Monitoring & Management
- n8n execution logs
- Supabase Studio dashboard
- PostgreSQL metrics
- Health checks for all services

### 🔄 Production Ready
- Persistent volumes for data
- Automatic restarts
- Resource limits configured
- Backup scripts included
- Migration tools provided

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Workflow Import](#workflow-import)
- [Database Management](#database-management)
- [Usage](#usage)
- [Monitoring](#monitoring)
- [Backup & Restore](#backup--restore)
- [Troubleshooting](#troubleshooting)
- [Production Deployment](#production-deployment)

---

## 🚀 Quick Start

Get up and running in 5 minutes:

```bash
# 1. Clone repository
git clone https://github.com/yourusername/cocounsel-n8n.git
cd cocounsel-n8n

# 2. Configure environment
cp .env.example .env
# Edit .env with your ANTHROPIC_API_KEY

# 3. Start all services
docker compose up -d

# 4. Access services
# n8n: http://localhost:5678
# Supabase Studio: http://localhost:8000
```

First time setup will automatically:
- Create database schema
- Create users and roles
- Load mock data
- Configure extensions
- Set up authentication

---

## 📦 Prerequisites

### Required Software

- **Docker** 20.10+ ([Install Guide](https://docs.docker.com/get-docker/))
- **Docker Compose** 2.0+ ([Install Guide](https://docs.docker.com/compose/install/))
- **Git** (for cloning repository)
- **8GB RAM** minimum (16GB recommended)
- **10GB free disk space**

### Required API Keys

- **Anthropic API Key** (required)
  - Get from: https://console.anthropic.com/
  - Models: Claude Sonnet 4, Opus 4, Haiku 4

- **LangSmith API Key** (optional, for monitoring)
  - Get from: https://smith.langchain.com/

### Operating System Support

- ✅ Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+)
- ✅ macOS 11+ (Intel and Apple Silicon)
- ✅ Windows 10/11 with WSL2

---

## 🔧 Installation

### Step 1: Install Docker & Docker Compose

#### On Ubuntu/Debian:
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose plugin
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Verify
docker --version
docker compose version

# Log out and back in for group changes to take effect
```

#### On macOS:
```bash
# Install Docker Desktop
brew install --cask docker

# Or download from: https://www.docker.com/products/docker-desktop

# Start Docker Desktop application
open -a Docker

# Verify
docker --version
docker compose version
```

#### On Windows:
1. Install WSL2: https://docs.microsoft.com/en-us/windows/wsl/install
2. Install Docker Desktop: https://www.docker.com/products/docker-desktop
3. Enable WSL2 integration in Docker Desktop settings
4. Verify in PowerShell: `docker --version`

### Step 2: Clone Repository

```bash
# Clone from GitHub
git clone https://github.com/yourusername/cocounsel-n8n.git
cd cocounsel-n8n

# Or extract from tarball
tar -xzf cocounsel-n8n.tar.gz
cd cocounsel-n8n
```

### Step 3: Configure Environment Variables

```bash
# Copy environment template
cp .env.example .env

# Edit with your preferred editor
nano .env
# or
vim .env
# or
code .env  # VS Code
```

**Required Configuration:**

```bash
# ============================================
# ANTHROPIC API (REQUIRED)
# ============================================
ANTHROPIC_API_KEY=sk-ant-your-key-here

# ============================================
# DATABASE CREDENTIALS
# ============================================
POSTGRES_PASSWORD=your_secure_password_here
SUPABASE_JWT_SECRET=your_jwt_secret_minimum_32_chars
SUPABASE_ANON_KEY=generate_with_jwt_io_or_use_provided
SUPABASE_SERVICE_KEY=generate_with_jwt_io_or_use_provided

# ============================================
# n8n CONFIGURATION
# ============================================
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_n8n_password

# ============================================
# OPTIONAL: LANGSMITH (for monitoring)
# ============================================
LANGCHAIN_TRACING_V2=false
LANGCHAIN_API_KEY=lsv2_your_key_here
LANGCHAIN_PROJECT=cocounsel-n8n
```

**Generate Secure Secrets:**

```bash
# Generate PostgreSQL password
openssl rand -base64 32

# Generate JWT secret (minimum 32 characters)
openssl rand -base64 64

# Generate Supabase keys (or use provided defaults for development)
```

### Step 4: Start Services

```bash
# Start all services in detached mode
docker compose up -d

# View logs (optional)
docker compose logs -f

# Check service status
docker compose ps
```

**Expected Output:**
```
NAME                    STATUS              PORTS
cocounsel-n8n           running             0.0.0.0:5678->5678/tcp
cocounsel-db            running             0.0.0.0:5432->5432/tcp
cocounsel-supabase      running             0.0.0.0:8000->8000/tcp
cocounsel-redis         running             0.0.0.0:6379->6379/tcp
cocounsel-storage       running             0.0.0.0:8080->8080/tcp
```

### Step 5: Wait for Initialization

First-time setup takes 2-3 minutes:

```bash
# Watch initialization logs
docker compose logs -f db

# Wait for this message:
# "database system is ready to accept connections"
# "PostgreSQL init process complete; ready for start up"
```

### Step 6: Verify Installation

```bash
# Test n8n
curl http://localhost:5678/healthz

# Test Supabase
curl http://localhost:8000/

# Test database connection
docker compose exec db psql -U supabase_admin cocounsel -c "SELECT version();"
```

### Step 7: Access Services

Open in your browser:

1. **n8n Workflow Editor**
   - URL: http://localhost:5678
   - Username: `admin` (or from .env)
   - Password: (from .env N8N_BASIC_AUTH_PASSWORD)

2. **Supabase Studio**
   - URL: http://localhost:8000
   - Default credentials: Check Supabase docs or use JWT

3. **Database (direct connection)**
   - Host: localhost
   - Port: 5432
   - Database: cocounsel
   - User: supabase_admin
   - Password: (from .env POSTGRES_PASSWORD)

---

## ⚙️ Configuration

### Service Ports

| Service | Port | Purpose |
|---------|------|---------|
| n8n | 5678 | Workflow editor and webhooks |
| Supabase Studio | 8000 | Database management UI |
| PostgreSQL | 5432 | Direct database access |
| Supabase API | 8443 | REST API (optional) |
| Storage | 8080 | File storage (optional) |
| Redis | 6379 | Cache and sessions |

### Environment Variables Reference

See [CONFIGURATION.md](docs/CONFIGURATION.md) for detailed environment variable documentation.

### Resource Limits

Default resource limits (can be adjusted in docker-compose.yml):

```yaml
resources:
  limits:
    cpus: '2.0'
    memory: 4G
  reservations:
    cpus: '0.5'
    memory: 1G
```

### Network Configuration

All services run on isolated Docker network `cocounsel_network`:
- Internal DNS resolution
- Service discovery by name
- External access via mapped ports

---

## 📥 Workflow Import

### Automatic Import (Recommended)

The CoCounsel workflow is automatically imported on first startup.

**Verify import:**
1. Open n8n: http://localhost:5678
2. Click "Workflows" in left sidebar
3. Look for "CoCounsel - Complete with Memorandum"

### Manual Import

If automatic import failed:

1. Open n8n
2. Click "+" to create new workflow
3. Click "..." menu → "Import from File"
4. Select: `workflows/CoCounsel_Complete_Final.json`
5. Click "Import"

### Configure Workflow

After import, configure credentials:

1. **PostgreSQL Credentials**:
   - Click any PostgreSQL node
   - Click "Create New Credential"
   - Enter:
     ```
     Host: db
     Database: cocounsel
     User: cocounsel_app
     Password: (from .env POSTGRES_PASSWORD)
     Port: 5432
     ```

2. **Anthropic Credentials**:
   - Click any Claude node
   - Click "Create New Credential"
   - Enter API key from .env

3. **Activate Workflow**:
   - Toggle "Active" switch in top-right corner
   - Workflow is now listening for webhooks

---

## 🗄️ Database Management

### Access Supabase Studio

1. Open: http://localhost:8000
2. Navigate to "Table Editor"
3. View all tables and data

### Connect with psql

```bash
# From host machine
docker compose exec db psql -U supabase_admin cocounsel

# Run queries
SELECT COUNT(*) FROM user_research_history;
SELECT * FROM user_preferences WHERE user_id = 'user_123';
```

### Database Schema

Tables created automatically:

- `user_research_history` - Past research sessions
- `user_preferences` - User settings
- `research_patterns` - Successful search patterns
- `learning_examples` - Expert feedback
- `case_knowledge_base` - Case law with vector embeddings
- `expert_review_queue` - Cases needing review
- `audit_log` - Compliance tracking

### View Schema

```bash
# View all tables
docker compose exec db psql -U supabase_admin cocounsel -c "\dt"

# View table structure
docker compose exec db psql -U supabase_admin cocounsel -c "\d user_research_history"

# View indexes
docker compose exec db psql -U supabase_admin cocounsel -c "\di"
```

### Mock Data

Mock data is automatically loaded for testing:

- 3 user preferences
- 3 research patterns
- 3 expert lessons
- 3 case knowledge base entries
- 3 historical research sessions

**View mock data:**
```bash
docker compose exec db psql -U supabase_admin cocounsel -c "
SELECT table_name, 
       (SELECT COUNT(*) FROM information_schema.tables t 
        WHERE t.table_name = tables.table_name) as row_count
FROM information_schema.tables 
WHERE table_schema = 'public';
"
```

---

## 🚀 Usage

### Test with curl

```bash
# Get webhook URL from n8n
# Workflow → Webhook node → Copy URL
# Example: http://localhost:5678/webhook/legal-research

# Send test request
curl -X POST http://localhost:5678/webhook/legal-research \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What are the remedies for material breach of contract?",
    "jurisdiction": "federal",
    "practiceArea": "contract",
    "userId": "user_123",
    "isFollowUp": false,
    "outputFormat": "memo"
  }'
```

### Test with Postman

1. Import `docs/postman_collection.json`
2. Set webhook URL in collection variables
3. Run "Basic Research Query" request

### Monitor Execution

**In n8n:**
1. Click "Executions" in left sidebar
2. View execution list
3. Click any execution to see details
4. Inspect data flow between nodes

**Check logs:**
```bash
# n8n logs
docker compose logs -f n8n

# Database logs
docker compose logs -f db

# All logs
docker compose logs -f
```

### Common Queries

**Check quality scores:**
```sql
SELECT 
    session_id,
    query,
    quality_score,
    retry_count,
    needs_expert_review
FROM user_research_history
ORDER BY created_at DESC
LIMIT 10;
```

**View expert review queue:**
```sql
SELECT 
    session_id,
    query,
    quality_score,
    priority,
    status
FROM expert_review_queue
WHERE status = 'pending'
ORDER BY created_at DESC;
```

---

## 📊 Monitoring

### Health Checks

```bash
# Check all services
docker compose ps

# n8n health
curl http://localhost:5678/healthz

# Database health
docker compose exec db pg_isready

# Redis health
docker compose exec redis redis-cli ping
```

### Resource Usage

```bash
# View resource consumption
docker stats

# Specific service
docker stats cocounsel-n8n
```

### Logs

```bash
# View all logs
docker compose logs

# Follow logs
docker compose logs -f

# Specific service
docker compose logs n8n
docker compose logs db

# Last 100 lines
docker compose logs --tail=100 n8n

# Since specific time
docker compose logs --since 1h n8n
```

### Database Metrics

```bash
# Connection count
docker compose exec db psql -U supabase_admin cocounsel -c "
SELECT count(*) FROM pg_stat_activity;
"

# Database size
docker compose exec db psql -U supabase_admin cocounsel -c "
SELECT pg_size_pretty(pg_database_size('cocounsel'));
"

# Table sizes
docker compose exec db psql -U supabase_admin cocounsel -c "
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"
```

---

## 💾 Backup & Restore

### Backup Database

```bash
# Create backup directory
mkdir -p backups

# Full database backup
docker compose exec -T db pg_dump -U supabase_admin cocounsel \
  > backups/cocounsel_$(date +%Y%m%d_%H%M%S).sql

# Compressed backup
docker compose exec -T db pg_dump -U supabase_admin cocounsel \
  | gzip > backups/cocounsel_$(date +%Y%m%d_%H%M%S).sql.gz

# Schema only
docker compose exec -T db pg_dump -U supabase_admin cocounsel --schema-only \
  > backups/cocounsel_schema_$(date +%Y%m%d_%H%M%S).sql

# Data only
docker compose exec -T db pg_dump -U supabase_admin cocounsel --data-only \
  > backups/cocounsel_data_$(date +%Y%m%d_%H%M%S).sql
```

### Restore Database

```bash
# Stop n8n (to prevent new writes)
docker compose stop n8n

# Restore from backup
cat backups/cocounsel_20250109_120000.sql | \
  docker compose exec -T db psql -U supabase_admin cocounsel

# Or from compressed
gunzip -c backups/cocounsel_20250109_120000.sql.gz | \
  docker compose exec -T db psql -U supabase_admin cocounsel

# Restart n8n
docker compose start n8n
```

### Backup Workflows

```bash
# n8n workflows are stored in Docker volume
# Backup n8n data
docker run --rm \
  -v cocounsel-n8n_n8n_data:/source \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/n8n_data_$(date +%Y%m%d_%H%M%S).tar.gz -C /source .
```

### Automated Backups

See `scripts/backup.sh` for automated backup script with cron:

```bash
# Make executable
chmod +x scripts/backup.sh

# Add to cron (daily at 2 AM)
crontab -e
# Add line:
0 2 * * * /path/to/cocounsel-n8n/scripts/backup.sh
```

---

## 🐛 Troubleshooting

### Services Won't Start

**Check logs:**
```bash
docker compose logs
```

**Common issues:**

1. **Port already in use**:
   ```bash
   # Check what's using port
   sudo lsof -i :5678
   sudo lsof -i :5432
   
   # Change port in docker-compose.yml or kill process
   ```

2. **Permission denied**:
   ```bash
   # Fix permissions
   sudo chown -R $USER:$USER .
   chmod 600 .env
   ```

3. **Out of disk space**:
   ```bash
   # Check space
   df -h
   
   # Clean Docker
   docker system prune -a
   ```

### Database Connection Failed

```bash
# Check if database is running
docker compose ps db

# Check database logs
docker compose logs db

# Test connection
docker compose exec db psql -U supabase_admin cocounsel -c "SELECT 1;"

# Restart database
docker compose restart db
```

### n8n Can't Connect to Database

```bash
# Verify credentials in n8n
# Host should be: db (not localhost)
# Port: 5432
# Database: cocounsel
# User: cocounsel_app

# Test from n8n container
docker compose exec n8n nc -zv db 5432
```

### Workflow Execution Fails

1. **Check credentials**:
   - PostgreSQL credentials configured?
   - Anthropic API key valid?

2. **Check logs**:
   ```bash
   docker compose logs n8n
   ```

3. **Test individual nodes**:
   - Click node → "Execute Node"
   - Check output

4. **Verify database schema**:
   ```bash
   docker compose exec db psql -U supabase_admin cocounsel -c "\dt"
   ```

### High Memory Usage

```bash
# Check resource usage
docker stats

# Adjust limits in docker-compose.yml
# Restart services
docker compose down
docker compose up -d
```

### Reset Everything

```bash
# Stop all services
docker compose down

# Remove volumes (WARNING: deletes all data)
docker compose down -v

# Remove images
docker compose down --rmi all

# Start fresh
docker compose up -d
```

---

## 🚀 Production Deployment

### Security Checklist

- [ ] Change all default passwords
- [ ] Use strong JWT secrets (64+ characters)
- [ ] Enable SSL/TLS with Traefik
- [ ] Configure firewall rules
- [ ] Enable database encryption
- [ ] Set up automated backups
- [ ] Configure log rotation
- [ ] Enable audit logging
- [ ] Use secrets management (Vault, AWS Secrets Manager)
- [ ] Set up monitoring and alerts

### Enable SSL with Traefik

Uncomment Traefik section in `docker-compose.yml` and configure:

```yaml
traefik:
  image: traefik:v2.10
  command:
    - --api.insecure=false
    - --providers.docker=true
    - --entrypoints.web.address=:80
    - --entrypoints.websecure.address=:443
    - --certificatesresolvers.myresolver.acme.email=your@email.com
    - --certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json
    - --certificatesresolvers.myresolver.acme.httpchallenge.entrypoint=web
```

### Resource Scaling

For production load:

```yaml
n8n:
  deploy:
    replicas: 2
    resources:
      limits:
        cpus: '4.0'
        memory: 8G
```

### Monitoring Setup

See [MONITORING.md](docs/MONITORING.md) for:
- Prometheus metrics
- Grafana dashboards
- Alert rules
- Log aggregation

---

## 📚 Documentation

- [INSTALLATION.md](docs/INSTALLATION.md) - Detailed installation guide
- [CONFIGURATION.md](docs/CONFIGURATION.md) - Configuration reference
- [DATABASE.md](docs/DATABASE.md) - Database schema and management
- [API.md](docs/API.md) - API documentation
- [MONITORING.md](docs/MONITORING.md) - Monitoring and observability
- [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Common issues and solutions

---

## 🤝 Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

---

## 🙏 Acknowledgments

- [n8n](https://n8n.io/) - Workflow automation
- [Supabase](https://supabase.com/) - Open source Firebase alternative
- [Anthropic](https://www.anthropic.com/) - Claude AI models
- [pgvector](https://github.com/pgvector/pgvector) - Vector similarity search

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/cocounsel-n8n/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/cocounsel-n8n/discussions)

---

**Built with ❤️ for the legal community**
