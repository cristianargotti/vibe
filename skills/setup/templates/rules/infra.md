# Infrastructure Rules

Always use multi-stage Docker builds. Always pin image versions with SHA digests.
Never run containers as root. Always create and use a non-root user.
Always add HEALTHCHECK to every Dockerfile.
Always use one Terraform module per service. Always tag every resource.
Always store Terraform state remotely (S3 + DynamoDB lock).
Always mark sensitive Terraform variables with `sensitive = true`.
Always use IAM least privilege. Never use inline IAM policies.
Always encrypt S3 buckets (SSE-S3 or SSE-KMS). Always block public access by default.
Always use private subnets for compute resources. Public subnets only for ALB/NLB.
Always use CloudFormation change sets before applying stack updates.
Always set resource limits (CPU/memory) on all containers.
