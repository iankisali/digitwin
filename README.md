# Digitwin - AI Digital Twin

An AI-powered digital twin application that creates an interactive, conversational representation of a professional profile. Visitors can chat with an AI agent trained on professional information, including LinkedIn profiles, career summaries, and personal communication style.

## What This Project Does

Digitwin is a full-stack web application that:

- **Frontend**: A modern Next.js chat interface where users can interact with the digital twin
- **Backend**: A FastAPI server running on AWS Lambda that processes chat messages
- **AI**: Uses AWS Bedrock (Amazon Nova Pro) to generate contextual responses based on professional data
- **Storage**: Maintains conversation history in S3 for session continuity
- **Infrastructure**: Fully serverless architecture deployed on AWS (Lambda, API Gateway, S3, CloudFront)

The digital twin answers questions about professional background, skills, experience, and career trajectory in a manner that reflects the individual's authentic voice.

## Prerequisites

Before setting up this project, ensure you have:

- **Node.js** 20+ and npm
- **Python** 3.12+ 
- **uv** (Python package manager) - [Installation guide](https://github.com/astral-sh/uv)
- **Docker** (for building Lambda packages)
- **AWS CLI** configured with appropriate credentials
- **Terraform** 1.5+ installed
- **AWS Account** with:
  - Bedrock access (Nova Pro model)
  - Permissions to create Lambda, API Gateway, S3, CloudFront, IAM resources
  - Route53 access (if using custom domain)

## Project Structure

```
digitwin/
├── backend/              # Python FastAPI backend
│   ├── server.py        # Main API server
│   ├── lambda_handler.py
│   ├── context.py       # AI prompt engineering
│   ├── resources.py     # Data loading
│   ├── data/           # Professional profile data
│   └── requirements.txt
├── frontend/            # Next.js frontend
│   ├── app/            # Next.js app router
│   ├── components/     # React components
│   └── public/        # Static assets
├── terraform/          # Infrastructure as code
├── scripts/            # Deployment scripts
└── memory/            # Local conversation storage (dev)ß
```

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/iankisali/digitwin.gitß
cd digitwin
```

### 2. Configure AWS Credentials

For local development, configure AWS CLI with a profile:

```bash
aws configure --profile ai
```

Or set environment variables:
```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1
```

### 3. Set Up Backend

```bash
cd backend

# Install dependencies using uv
uv sync

# Verify data files exist
ls -la data/
# Should see: facts.json, linkedin.pdf, summary.txt, style.txt
```

**Note**: Update the data files in `backend/data/` with your own professional information:
- `facts.json` - Structured professional facts
- `linkedin.pdf` - Your LinkedIn profile export
- `summary.txt` - Professional summary
- `style.txt` - Communication style guide

### 4. Set Up Frontend

```bash
cd ../frontend

# Install dependencies
npm install
```

### 5. Configure Environment Variables

**Backend** (create `backend/.env`):
```env
CORS_ORIGINS=http://localhost:3000
USE_S3=false
MEMORY_DIR=../memory
BEDROCK_MODEL_ID=amazon.nova-pro-v1:0
DEFAULT_AWS_REGION=us-east-1
```

**Frontend** (create `frontend/.env.local` for local dev):
```env
NEXT_PUBLIC_API_URL=http://localhost:8000
```

## Running Locally

### Start the Backend

```bash
cd backend
uv run uvicorn server:app --reload --port 8000
```

The API will be available at `http://localhost:8000`

**Test the backend**:
```bash
curl http://localhost:8000/health
```

### Start the Frontend

In a new terminal:

```bash
cd frontend
npm run dev
```

The frontend will be available at `http://localhost:3000`

### Verify Everything Works

1. Open `http://localhost:3000` in your browser
2. Type a message in the chat interface
3. You should receive a response from the AI digital twin

## Deployment to AWS

### Prerequisites for Deployment

1. **Terraform Backend**: An S3 bucket for Terraform state
   ```bash
   aws s3 mb s3://digitwin-terraform-state-$(aws sts get-caller-identity --query Account --output text)
   aws dynamodb create-table \
     --table-name digitwin-terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

2. **Bedrock Model Access**: Ensure you have access to the Bedrock model in your AWS account

### Deploy Using Script

The easiest way to deploy is using the provided script:

```bash
# Deploy to dev environment
./scripts/deploy.sh dev

# Deploy to production
./scripts/deploy.sh prod
```

The script will:
1. Build the Lambda package
2. Initialize and apply Terraform
3. Build and deploy the frontend
4. Output the CloudFront and API Gateway URLs

### Manual Deployment Steps

If you prefer to deploy manually:

#### 1. Build Lambda Package

```bash
cd backend
uv run deploy.py
```

This creates `lambda-deployment.zip` with all dependencies.

#### 2. Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init \
  -backend-config="bucket=digitwin-terraform-state-$(aws sts get-caller-identity --query Account --output text)" \
  -backend-config="key=dev/terraform.tfstate" \
  -backend-config="region=us-east-1"

# Create/select workspace
terraform workspace new dev  # or select existing
terraform workspace select dev

# Apply infrastructure
terraform apply -var="project_name=digitwin" -var="environment=dev"
```

#### 3. Build and Deploy Frontend

```bash
cd ../frontend

# Get API Gateway URL from Terraform
API_URL=$(terraform -chdir=../terraform output -raw api_gateway_url)
FRONTEND_BUCKET=$(terraform -chdir=../terraform output -raw s3_frontend_bucket)

# Create production env file
echo "NEXT_PUBLIC_API_URL=$API_URL" > .env.production

# Build and deploy
npm run build
aws s3 sync ./out "s3://$FRONTEND_BUCKET/" --delete
```

#### 4. Invalidate CloudFront Cache

```bash
DISTRIBUTION_ID=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?Origins.Items[?DomainName=='$FRONTEND_BUCKET.s3-website-us-east-1.amazonaws.com']].Id | [0]" \
  --output text)

aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*"
```

### Get Deployment URLs

After deployment, get your URLs:

```bash
cd terraform
terraform output cloudfront_url
terraform output api_gateway_url
```

## Configuration

### Terraform Variables

Edit `terraform/terraform.tfvars` or pass variables:

```hcl
project_name = "digitwin"
environment = "dev"
bedrock_model_id = "amazon.nova-pro-v1:0"
lambda_timeout = 60
use_custom_domain = false
root_domain = ""
```

### Custom Domain Setup

To use a custom domain:

1. Set `use_custom_domain = true` in Terraform variables
2. Set `root_domain = "yourdomain.com"`
3. Ensure Route53 hosted zone exists for the domain
4. Terraform will create ACM certificate and DNS records

## Development Workflow

### Making Changes

1. **Backend Changes**:
   - Edit files in `backend/`
   - Restart the uvicorn server (auto-reload enabled)
   - Test with curl or the frontend

2. **Frontend Changes**:
   - Edit files in `frontend/`
   - Changes hot-reload automatically
   - Test in browser

3. **Infrastructure Changes**:
   - Edit Terraform files
   - Run `terraform plan` to preview
   - Run `terraform apply` to deploy

### Testing

**Backend Health Check**:
```bash
curl http://localhost:8000/health
```

**Chat Endpoint**:
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Tell me about yourself"}'
```

**Frontend Linting**:
```bash
cd frontend
npm run lint
```

## Troubleshooting

### Backend Issues

**"Bedrock Access Denied"**:
- Verify IAM role has `AmazonBedrockFullAccess` policy
- Check model availability in your region
- Ensure model ID is correct

**"Module not found" errors**:
- Run `uv sync` in backend directory
- Check `requirements.txt` includes all dependencies

**Lambda timeout**:
- Increase `lambda_timeout` in Terraform variables
- Check CloudWatch logs for slow operations

### Frontend Issues

**CORS errors**:
- Verify `CORS_ORIGINS` in backend `.env` includes frontend URL
- Check API Gateway CORS configuration

**API connection failed**:
- Verify `NEXT_PUBLIC_API_URL` is set correctly
- Check backend is running
- Verify API Gateway is deployed

**Build errors**:
- Run `npm install` to ensure dependencies are installed
- Check for linting errors: `npm run lint`

### Infrastructure Issues

**Terraform state locked**:
- Check DynamoDB lock table
- Manually remove lock if stuck (use with caution)

**S3 bucket already exists**:
- Use a different project name or environment
- Or manually delete existing bucket

**CloudFront not updating**:
- Invalidate CloudFront cache
- Wait a few minutes for propagation

## CI/CD

The project includes GitHub Actions workflows:

- **Deploy** (`.github/workflows/deploy.yml`): Automatically deploys on push to `main`
- **Destroy** (`.github/workflows/destroy.yml`): Teardown infrastructure

Configure GitHub Secrets:
- `AWS_ROLE_ARN` - IAM role for GitHub Actions
- `AWS_ACCOUNT_ID` - AWS account ID
- `DEFAULT_AWS_REGION` - AWS region

## Additional Resources

- **AWS Bedrock**: [Documentation](https://docs.aws.amazon.com/bedrock/)
- **Next.js**: [Documentation](https://nextjs.org/docs)
- **FastAPI**: [Documentation](https://fastapi.tiangolo.com/)
- **Terraform**: [Documentation](https://www.terraform.io/docs)

## Support

For questions or issues:
- Check the troubleshooting section above
- Review the project documentation
- Open an issue in the repository

**Happy Coding! 🚀**
