# Agent Notes (Repo-wide)

## Cost / Spend Safety (GCP)

This repository includes infrastructure for deploying MLflow on GCP (see `infra/terraform`).

When making changes or providing commands:

- Prefer the smallest/cheapest GCP resources that satisfy requirements.
- Default to conservative scaling (e.g. low `max_instances`, min instances `0`).
- Avoid enabling/creating expensive managed services unless explicitly requested.
- Call out any resource likely to incur significant recurring cost (e.g. Cloud SQL tiers, load balancers, NAT gateways).
- Prefer alerts/guardrails (budgets/thresholds) and make it clear that GCP budgets do not hard-stop spend.
