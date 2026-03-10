# AWS Standards

Tier 2 reference for AWS service usage at Dafiti. All infrastructure follows least-privilege, encryption-at-rest, and cost-visibility principles.

## IAM — Least-Privilege Policies

Never use `*` for actions. Scope resources to the narrowest ARN possible.

```hcl
# Service role for a Lambda that reads from S3 and writes to DynamoDB
resource "aws_iam_role" "order_processor" {
  name = "${local.prefix}-order-processor"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "order_processor" {
  name = "${local.prefix}-order-processor"
  role = aws_iam_role.order_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadOrdersBucket"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.orders.arn,
          "${aws_s3_bucket.orders.arn}/*"
        ]
      },
      {
        Sid      = "WriteDynamoDB"
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:UpdateItem"]
        Resource = aws_dynamodb_table.orders.arn
      },
      {
        Sid      = "CloudWatchLogs"
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}
```

## S3 — Secure Bucket Configuration

Every bucket MUST have encryption, versioning, public access block, and lifecycle rules.

```hcl
resource "aws_s3_bucket" "data" {
  bucket = "${local.prefix}-data"
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 365
      storage_class = "GLACIER"
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
```

## VPC Layout

Standard three-tier VPC: public, private (application), and isolated (database) subnets across two AZs.

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnets = ["10.0.20.0/24", "10.0.21.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "prod"
  one_nat_gateway_per_az = var.environment == "prod"

  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = false

  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Application security group
resource "aws_security_group" "app" {
  name_prefix = "${local.prefix}-app-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Database security group — only allows app tier
resource "aws_security_group" "db" {
  name_prefix = "${local.prefix}-db-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## Secrets Manager

Store all secrets in Secrets Manager — never in environment variables, SSM plaintext, or code.

```hcl
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${local.prefix}/db-credentials"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "app_user"
    password = random_password.db.result
    host     = aws_db_instance.main.address
    port     = 5432
    dbname   = "dafiti"
  })
}
```

Application code reads secrets at startup:

```typescript
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

async function getDbConfig(): Promise<DbConfig> {
  const client = new SecretsManagerClient({ region: 'us-east-1' });
  const response = await client.send(
    new GetSecretValueCommand({ SecretId: `${serviceName}-${env}/db-credentials` }),
  );
  return JSON.parse(response.SecretString!);
}
```

## CloudWatch — Alarms and Dashboards

```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.prefix}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "${local.prefix}-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 10

  metric_query {
    id          = "error_rate"
    expression  = "(errors / requests) * 100"
    label       = "5xx Error Rate"
    return_data = true
  }

  metric_query {
    id = "errors"
    metric {
      metric_name = "HTTPCode_Target_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "Sum"
      dimensions  = { LoadBalancer = aws_lb.main.arn_suffix }
    }
  }

  metric_query {
    id = "requests"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "Sum"
      dimensions  = { LoadBalancer = aws_lb.main.arn_suffix }
    }
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

## Cost Allocation Tags

The following tags are mandatory on all resources for cost tracking.

```hcl
locals {
  required_tags = {
    CostCenter  = var.cost_center     # e.g. "engineering", "data"
    Service     = var.service_name
    Environment = var.environment
    Team        = var.team
  }
}
```

Enable these in the AWS Billing console under Cost Allocation Tags.

## ALB Configuration

```hcl
resource "aws_lb" "main" {
  name               = "${local.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets

  drop_invalid_header_fields = true
  enable_deletion_protection = var.environment == "prod"
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${local.prefix}-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }

  deregistration_delay = 30
}
```

## Key Rules

- Every IAM policy must follow least privilege — no `Action: "*"` or `Resource: "*"`.
- All S3 buckets must block public access and enable encryption.
- Production VPCs use one NAT gateway per AZ for resilience.
- Secrets go in Secrets Manager, never in env vars or SSM plaintext.
- All resources must carry the four mandatory cost-allocation tags.
