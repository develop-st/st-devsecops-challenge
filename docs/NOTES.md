# NOTES

## Top Risks (Ranked by Severity)

1. **SQL Injection (Critical)** - Backend allowed arbitrary SQL execution
2. **Hardcoded Secrets (Critical)** - AWS keys and passwords in git
3. **Privileged Containers (Critical)** - K8s pods running as root with full privileges
4. **Open Security Group (High)** - PostgreSQL exposed to 0.0.0.0/0 (entire internet)
5. **Admin IAM Policy (High)** - CI user had `Action: *` on all resources
6. **Credential Leak in CI (High)** - Workflow printed env vars including secrets
7. **XSS Vulnerability (Medium)** - Frontend used dangerouslySetInnerHTML
8. **Outdated Dependencies (Medium)** - Logback had known CVE
9. **No Security Headers (Low)** - Missing X-Frame-Options, CSP, etc.

---

## What I Changed

### 1. Backend SQL Injection Fix (`backend/src/main/kotlin/com/light/App.kt`)
**Problem:** Direct string interpolation in SQL query
```kotlin
stmt.executeQuery("SELECT name FROM users WHERE id = ${id}")
```
**Fix:** Used PreparedStatement with parameterized query
**Reason:** Prevents attackers from injecting malicious SQL like `id=1 OR 1=1`

### 2. Frontend XSS Fix (`frontend/pages/index.tsx`)
**Problem:** Used `dangerouslySetInnerHTML={{ __html: sample }}`
**Fix:** Removed dangerouslySetInnerHTML, use safe React rendering
**Reason:** Prevents attackers from injecting `<script>` tags to steal cookies/data

### 3. CI/CD Security Fix (`.github/workflows/ci.yml`)
**Problem:** Workflow leaked secrets with `env | sort` command
**Fix:** 
- Removed the env dump command
- Switched to OIDC authentication (no static AWS keys)
- Added security scanning steps
**Reason:** Static credentials can be stolen; OIDC provides short-lived tokens

### 4. Terraform Security Group Fix (`infra/terraform/main.tf`)
**Problem:** PostgreSQL SG allowed `0.0.0.0/0` (open to internet)
**Fix:** Restricted to VPC CIDR only
**Reason:** Database should never be publicly accessible

### 5. Terraform IAM Fix (`infra/terraform/main.tf`)
**Problem:** IAM policy with `Action: "*"` and `Resource: "*"`
**Fix:** 
- Replaced IAM user with OIDC role for GitHub Actions
- Applied least-privilege (only ECR and EKS permissions)
**Reason:** Least privilege principle - only grant what's needed

### 6. Terraform Secrets Output Fix (`infra/terraform/main.tf`)
**Problem:** Secret access key output had `sensitive = false`
**Fix:** Removed static credentials, use OIDC role ARN instead
**Reason:** Secrets would appear in logs and state files

### 7. Kubernetes Deployment Security (`deploy/tanka/environments/dev/main.jsonnet`)
**Problem:** Container ran as privileged root
**Fix:**
- `privileged: false`
- `runAsNonRoot: true`
- `readOnlyRootFilesystem: true`
- Added resource limits
- Added health probes
- Use secrets from K8s Secret, not plaintext
**Reason:** Compromised container shouldn't have host access

### 8. Kubernetes Service Fix (`deploy/tanka/environments/dev/service.jsonnet`)
**Problem:** LoadBalancer type exposed service to internet
**Fix:** Changed to ClusterIP
**Reason:** Use ClusterIP + Ingress for controlled access

### 9. Kubernetes Secrets Fix (`deploy/tanka/environments/dev/secret.jsonnet`)
**Problem:** Plaintext secrets in git
**Fix:** Replaced with ExternalSecret pattern (AWS Secrets Manager)
**Reason:** Secrets should never be in version control

### 10. Backend Dockerfile Security (`backend/Dockerfile`)
**Problem:** Ran as root, no healthcheck
**Fix:**
- Added non-root user (appuser:1000)
- Added HEALTHCHECK instruction
- Used Alpine for smaller attack surface
**Reason:** Non-root limits damage if container is compromised

### 11. Frontend Dockerfile Security (`frontend/Dockerfile`)
**Problem:** Single-stage build, ran as root
**Fix:**
- Multi-stage build (smaller image)
- Non-root user (nextjs:1001)
- Added healthcheck
**Reason:** Smaller image = fewer vulnerabilities

### 12. Next.js Config Security (`frontend/next.config.js`)
**Problem:** `reactStrictMode: false`, `poweredByHeader: true`
**Fix:**
- Enabled strict mode
- Disabled powered-by header
- Added security headers (X-Frame-Options, etc.)
**Reason:** Headers prevent clickjacking and info leakage

### 13. TypeScript Strict Mode (`frontend/tsconfig.json`)
**Problem:** `strict: false` allows unsafe type coercion
**Fix:** Enabled `strict: true`
**Reason:** Catches type errors at compile time

### 14. Gitignore Secrets (`/.gitignore`)
**Problem:** Secret files could be committed
**Fix:** Added patterns for .env, .tfstate, .pem, etc.
**Reason:** Defense in depth - even if mistake happens, git won't track

### 15. Secrets Folder (`secrets/dev.env`)
**Problem:** Real AWS credentials in git
**Fix:** Replaced with placeholder values
**Reason:** Credentials should come from secrets manager

---

## What I Did Not Change

- Did not add full Terraform modules (VPC, EKS) - out of scope
- Did not implement full External Secrets Operator setup
- Did not add SOPS encryption config
- Did not create Ingress resource (would need domain/cert)
- Did not add rate limiting middleware

---

## Next 30 Days Plan

**Week 1: Foundation**
- [ ] Set up External Secrets Operator in K8s
- [ ] Configure SOPS for encrypted secrets in git
- [ ] Implement GitHub OIDC for AWS

**Week 2: Observability**
- [ ] Add Datadog APM to backend
- [ ] Set up CloudWatch alarms
- [ ] Create dashboards for key metrics

**Week 3: Security Hardening**
- [ ] Add network policies in K8s
- [ ] Implement Pod Security Standards
- [ ] Set up container image scanning in CI

**Week 4: Reliability**
- [ ] Add PodDisruptionBudgets
- [ ] Configure HorizontalPodAutoscaler
- [ ] Set up disaster recovery testing

---

## Observability Checklist

### What to Monitor
- [ ] Request latency (p50, p95, p99)
- [ ] Error rates (4xx, 5xx)
- [ ] Database connection pool usage
- [ ] CPU/Memory utilization
- [ ] Pod restart counts

### Alerts to Set Up
- [ ] Error rate > 1% for 5 minutes
- [ ] Latency p99 > 500ms
- [ ] Pod restarts > 3 in 10 minutes
- [ ] Database connections > 80% pool
- [ ] Certificate expiry < 30 days

### Logs to Ensure Exist
- [ ] All HTTP requests with trace ID
- [ ] Authentication events
- [ ] Database query errors (not full queries - PII risk)
- [ ] Deployment events
