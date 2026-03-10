# Terraform Standards

Tier 2 reference for infrastructure-as-code at Dafiti. All cloud resources MUST be provisioned through Terraform.

## Module Structure

Every Terraform module follows this layout:

```
modules/
  service-name/
    main.tf          # Resources
    variables.tf     # Input variables
    outputs.tf       # Output values
    versions.tf      # Provider and Terraform version constraints
    data.tf          # Data sources (optional, can inline in main.tf)
    locals.tf        # Local values (optional)
```

## versions.tf

```hcl
terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## variables.tf — Types, Descriptions, Validation

Every variable MUST have a `description` and an explicit `type`.

```hcl
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the service"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = can(regex("^t3\\.", var.instance_type))
    error_message = "Only t3 instance family is allowed."
  }
}

variable "enable_monitoring" {
  description = "Enable enhanced CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "allowed_cidrs" {
  description = "List of CIDR blocks allowed to access the service"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
```

## Remote State — S3 + DynamoDB Locking

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "dafiti-terraform-state"
    key            = "services/my-service/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "dafiti-terraform-locks"
  }
}
```

The lock table must exist before first init:

```hcl
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "dafiti-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

## Tagging — default_tags

Use provider-level `default_tags` so every resource is tagged automatically.

```hcl
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = var.environment
      Team        = "platform"
      ManagedBy   = "terraform"
      Service     = var.service_name
      CostCenter  = var.cost_center
    }
  }
}
```

Resource-specific tags merge with defaults:

```hcl
resource "aws_instance" "app" {
  # ...
  tags = {
    Name = "${var.service_name}-${var.environment}"
    Role = "application"
  }
}
```

## Data Sources

Use data sources to reference existing infrastructure — never hard-code IDs.

```hcl
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["dafiti-${var.environment}-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
```

## Resource Naming Convention

All resources follow: `{service}-{environment}-{resource-purpose}`

```hcl
locals {
  prefix = "${var.service_name}-${var.environment}"
}

resource "aws_s3_bucket" "assets" {
  bucket = "${local.prefix}-assets"
}

resource "aws_sqs_queue" "orders" {
  name = "${local.prefix}-orders"
}
```

## outputs.tf

```hcl
output "bucket_arn" {
  description = "ARN of the assets S3 bucket"
  value       = aws_s3_bucket.assets.arn
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "private_ip" {
  description = "Private IP of the instance"
  value       = aws_instance.app.private_ip
  sensitive   = true
}
```

## Lifecycle Rules

```hcl
resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  lifecycle {
    create_before_destroy = true            # zero-downtime replacement
    prevent_destroy       = true            # guard production resources
    ignore_changes        = [ami, tags]     # avoid drift from external changes
  }
}

resource "aws_db_instance" "main" {
  # ...
  lifecycle {
    prevent_destroy = true      # databases must never be accidentally deleted
  }
}
```

## Workspaces

Use workspaces to manage multiple environments from a single configuration.

```bash
# Create and switch
terraform workspace new staging
terraform workspace select prod

# Reference in config
terraform workspace show
```

```hcl
locals {
  env_config = {
    dev = {
      instance_type = "t3.small"
      min_size      = 1
      max_size      = 2
    }
    staging = {
      instance_type = "t3.medium"
      min_size      = 2
      max_size      = 4
    }
    prod = {
      instance_type = "t3.large"
      min_size      = 3
      max_size      = 10
    }
  }

  config = local.env_config[terraform.workspace]
}

resource "aws_instance" "app" {
  instance_type = local.config.instance_type
}
```

## Key Rules

- Never commit `.tfstate` files — always use remote state.
- Pin provider versions with `~>` constraints.
- Run `terraform fmt` and `terraform validate` in CI.
- Use `terraform plan` output as a PR comment before applying.
- Sensitive outputs must be marked `sensitive = true`.
- All variables must have `description` and `type`.
