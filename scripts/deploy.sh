#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}          # dev | test | prod
PROJECT_NAME=${2:-digitwin}

echo "🚀 Deploying ${PROJECT_NAME} to ${ENVIRONMENT}..."

# 1. Build Lambda package
cd "$(dirname "$0")/.."        # project root
echo "📦 Building Lambda package..."
(cd backend && uv run deploy.py)

# 2. Terraform workspace & apply
cd terraform
#terraform init -input=false
#aws configure --profile ai

# Detect if running in CI (GitHub Actions)
if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
  # In CI, use default credentials from environment variables
  AWS_PROFILE_ARG=""
  AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  export AWS_PROFILE=""
else
  # Local development, use 'ai' profile
  AWS_PROFILE_ARG="--profile ai"
  AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --profile ai)
  export AWS_PROFILE=ai
fi

AWS_REGION=${DEFAULT_AWS_REGION:-us-east-1}

# Remove .terraform directory if it exists to force fresh initialization
if [ -d ".terraform" ]; then
  echo "🧹 Cleaning existing .terraform directory..."
  rm -rf .terraform
fi

terraform init -input=false -migrate-state -force-copy \
  -backend-config="bucket=digitwin-terraform-state-${AWS_ACCOUNT_ID}" \
  -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="use_lockfile=true" \
  -backend-config="dynamodb_table=digitwin-terraform-locks" \
  -backend-config="encrypt=true"

if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
  terraform workspace new "$ENVIRONMENT"
else
  terraform workspace select "$ENVIRONMENT"
fi

# Use prod.tfvars for production environment
if [ "$ENVIRONMENT" = "prod" ]; then
  TF_APPLY_CMD=(terraform apply -var-file=prod.tfvars -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve)
else
  TF_APPLY_CMD=(terraform apply -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve)
fi

echo "🎯 Applying Terraform..."
"${TF_APPLY_CMD[@]}"

API_URL=$(terraform output -raw api_gateway_url)
FRONTEND_BUCKET=$(terraform output -raw s3_frontend_bucket)
CUSTOM_URL=$(terraform output -raw custom_domain_url 2>/dev/null || true)

# 3. Build + deploy frontend
cd ../frontend

# Create production environment file with API URL
echo "📝 Setting API URL for production..."
echo "NEXT_PUBLIC_API_URL=$API_URL" > .env.production

echo "📝 npm install and build..."
npm install
npm run build
aws s3 sync ./out "s3://$FRONTEND_BUCKET/" --delete $AWS_PROFILE_ARG
cd ..

# 4. Final messages
echo -e "\n✅ Deployment complete!"
echo "🌐 CloudFront URL : $(terraform -chdir=terraform output -raw cloudfront_url)"
if [ -n "$CUSTOM_URL" ]; then
  echo "🔗 Custom domain  : $CUSTOM_URL"
fi
echo "📡 API Gateway    : $API_URL"