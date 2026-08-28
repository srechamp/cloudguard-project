<h1 align="center">The Cloud Guard Project</h1>
<h2 align='center'>A Cloud Self-Service & Governance Platform</h2>

A working project built to emulate a cloud platform providing self-service capabilities and metrics to drive desired behaviors around financial operations, security posture, and overall good hygiene for cloud-based applications.

## What it does

CloudGuard is a FastAPI microservice that gives application teams self-service cloud governance:

1. **Self-service provisioning requests**: teams submit resource requests via REST API; policy checks (tagging, region, SKU allow-list) run automatically before approval.
2. **FinOps metrics**: cost-by-team endpoints, budget burn-rate, and idle-resource detection to drive financial-operations hygiene.
3. **Security posture scoring**: per-application hygiene score (encryption, public exposure, patch age, Key Vault usage).
4. **GenAI advisor (LangChain)**: an LLM endpoint that summarizes a team's posture + spend and recommends remediations; falls back to rule-based output when no LLM key is configured.

## Tech stack

| Requiremets | Where it lives here |
|---|---|
| Python, FastAPI, ASGI | `app/` (FastAPI + uvicorn) |
| Secure REST APIs | API-key auth dependency, input validation via Pydantic, rate-limit-ready middleware |
| Microservices / distributed systems | Stateless service, 12-factor config, health/readiness probes |
| Azure: AKS | `k8s/` manifests (deployment, service, HPA, probes) |
| Azure: Key Vault | `app/core/secrets.py` DefaultAzureCredential + SecretClient pattern with env fallback |
| Azure: Azure SQL | SQLAlchemy engine with `mssql+pyodbc` connection pattern (SQLite fallback for local dev) |
| Azure: API Management | Designed to sit behind APIM versioned routes (`/api/v1`), OpenAPI schema auto-generated |
| CI/CD (Azure DevOps or similar) | `.github/workflows/ci.yml` **and** `pipelines/azure-pipelines.yml` |
| Docker / Kubernetes | `Dockerfile` (multi-stage, non-root), `k8s/` |
| Generative AI (LangChain) | `app/services/advisor.py` |
| FinOps / security posture | `app/services/finops.py`, `app/services/posture.py` |

## Run it locally

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
pytest
```

## Deploy

```bash
docker build -t cloudguard:latest .
kubectl apply -f k8s/
```

## The Architect Pitch

- **Why this architecture**: stateless API behind APIM -> horizontal scaling on AKS with HPA; secrets never in code or env-committed files (Key Vault via managed identity); DB access through SQLAlchemy so Azure SQL vs local SQLite is a config change, not a code change.
- **Security**: non-root container, read-only root FS, API-key dependency (swap for Azure AD/Entra JWT validation in prod via APIM policy), Pydantic validation rejects malformed input at the edge.
- **The OCI -> Azure transfer**: landing zones ≈ Azure management groups + policy; OCI IAM federation ≈ Entra ID; OCI Alarms ≈ Azure Monitor alerts; tenancy provisioning ≈ subscription vending. Same control plane concepts, different names.
- **GenAI**: LangChain chain with structured prompt + graceful degradation the pattern for platform intelligence
