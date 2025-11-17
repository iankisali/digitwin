# Digitwin - AI Digital Twin Project

## Project Overview

**Digitwin** is an AI-powered digital twin application that creates an interactive, conversational representation of a professional profile. The project enables visitors to a personal website to engage in natural language conversations with an AI agent that has been trained on professional information, including LinkedIn profiles, career summaries, and personal communication style.

The digital twin acts as a 24/7 representative, answering questions about professional background, skills, experience, and career trajectory in a manner that reflects the individual's authentic voice and communication style.

## Architecture

The project follows a serverless, cloud-native architecture deployed entirely on AWS:

```
┌─────────────────────────────────────────────────────────────┐
│                        CloudFront CDN                        │
│              (Static Frontend + SSL Termination)             │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    S3 Bucket (Frontend)                      │
│              Next.js Static Site (HTML/CSS/JS)               │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            │ API Calls
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  API Gateway (HTTP API)                      │
│              CORS-enabled RESTful Endpoints                  │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Lambda Function                           │
│         FastAPI Application (Python 3.13)                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  • Chat Endpoint (/chat)                              │  │
│  │  • Health Check (/health)                              │  │
│  │  • Conversation History (/conversation/{session_id})  │  │
│  └──────────────────────────────────────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
        ▼                                       ▼
┌───────────────────┐              ┌──────────────────────┐
│  AWS Bedrock      │              │  S3 Bucket (Memory)    │
│  (Nova Pro v1)    │              │  Conversation Storage │
│  LLM Inference    │              │  (Session-based)      │
└───────────────────┘              └──────────────────────┘
```

## Technology Stack

### Frontend
- **Framework**: Next.js 15.5.4 (React-based)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **UI Components**: 
  - Lucide React (icons)
  - Next.js Image optimization
- **Build**: Static Site Generation (SSG) for optimal performance
- **Deployment**: S3 + CloudFront

### Backend
- **Framework**: FastAPI (Python)
- **Runtime**: AWS Lambda (Python 3.13)
- **AI/ML**: AWS Bedrock (Amazon Nova Pro v1:0)
- **Storage**: 
  - S3 for conversation memory (production)
  - Local file system (development)
- **API Gateway**: AWS API Gateway HTTP API
- **Dependencies**:
  - `boto3` - AWS SDK
  - `mangum` - ASGI adapter for Lambda
  - `pypdf` - PDF parsing for LinkedIn data
  - `python-dotenv` - Environment configuration

### Infrastructure as Code
- **Terraform**: Infrastructure provisioning and management
- **State Management**: S3 backend with DynamoDB locking
- **Workspaces**: Multi-environment support (dev, test, prod)
- **CI/CD**: GitHub Actions

## Project Structure

```
digitwin/
├── backend/                    # Python FastAPI backend
│   ├── server.py              # Main FastAPI application
│   ├── lambda_handler.py      # Lambda entry point
│   ├── context.py             # AI prompt engineering
│   ├── resources.py        # Data loading (LinkedIn, facts, style)
│   ├── deploy.py              # Lambda package builder
│   ├── requirements.txt       # Python dependencies
│   ├── pyproject.toml         # Python project config
│   └── data/                  # Professional profile data
│       ├── facts.json         # Structured professional facts
│       ├── linkedin.pdf       # LinkedIn profile export
│       ├── summary.txt        # Professional summary
│       └── style.txt         # Communication style guide
│
├── frontend/                   # Next.js frontend
│   ├── app/                   # Next.js App Router
│   │   ├── page.tsx           # Main landing page
│   │   ├── layout.tsx         # Root layout
│   │   └── globals.css        # Global styles
│   ├── components/
│   │   └── twin.tsx           # Chat interface component
│   ├── public/                # Static assets
│   │   └── profile.png        # Avatar image
│   └── out/                   # Build output (SSG)
│
├── terraform/                  # Infrastructure definitions
│   ├── main.tf                # Primary resources
│   ├── variables.tf           # Input variables
│   ├── outputs.tf             # Output values
│   ├── backend.tf             # State backend config
│   └── terraform.tfvars       # Variable values
│
├── scripts/                    # Deployment automation
│   ├── deploy.sh              # Full deployment script
│   └── destroy.sh             # Teardown script
│
├── memory/                     # Local conversation storage (dev)
│   └── {session_id}.json      # Session-based conversations
│
└── .github/workflows/          # CI/CD pipelines
    ├── deploy.yml              # Deployment workflow
    └── destroy.yml             # Teardown workflow
```

## Key Components

### 1. Frontend (`frontend/`)

**Main Page** (`app/page.tsx`):
- Landing page with project branding
- Container for the chat interface
- Responsive design with Tailwind CSS
- Footer with contact information

**Chat Component** (`components/twin.tsx`):
- Real-time chat interface
- Session management
- Message history with timestamps
- Loading states and error handling
- Avatar support (profile.png)
- Auto-scrolling message view
- Keyboard shortcuts (Enter to send)

**Features**:
- Client-side session ID generation
- API integration with backend
- Optimized image loading (Next.js Image)
- Responsive UI for mobile and desktop

### 2. Backend (`backend/`)

**FastAPI Server** (`server.py`):
- RESTful API endpoints:
  - `GET /` - Service information
  - `GET /health` - Health check
  - `POST /chat` - Chat endpoint (main interaction)
  - `GET /conversation/{session_id}` - Retrieve conversation history
  - `GET /suggested-prompts` - Get suggested questions
- CORS configuration for frontend integration
- Session-based conversation management
- AWS Bedrock integration for AI responses

**Context Engineering** (`context.py`):
- Dynamic prompt generation
- Incorporates multiple data sources:
  - Professional facts (JSON)
  - LinkedIn profile (PDF)
  - Professional summary
  - Communication style guide
- Current date/time injection
- Safety rules and guardrails

**Resource Loading** (`resources.py`):
- PDF parsing for LinkedIn data
- JSON parsing for structured facts
- Text file loading for summaries and style
- Error handling for missing files

**Lambda Handler** (`lambda_handler.py`):
- ASGI adapter using Mangum
- Enables FastAPI to run on AWS Lambda

**Deployment Script** (`deploy.py`):
- Docker-based dependency installation
- Lambda-compatible package creation
- Architecture-specific builds (x86_64)
- ZIP packaging for Lambda deployment

### 3. Infrastructure (`terraform/`)

**Core Resources**:
- **S3 Buckets**:
  - Frontend bucket (public, website hosting)
  - Memory bucket (private, conversation storage)
- **Lambda Function**:
  - Python 3.13 runtime
  - Environment variables for configuration
  - IAM roles with Bedrock and S3 permissions
- **API Gateway**:
  - HTTP API (v2)
  - CORS configuration
  - Throttling and rate limiting
  - Lambda integration
- **CloudFront Distribution**:
  - CDN for frontend
  - SSL/TLS termination
  - Custom domain support (optional)
  - SPA routing (404 → index.html)
- **Route53** (optional):
  - Custom domain management
  - DNS records for CloudFront
- **ACM Certificate** (optional):
  - SSL certificate for custom domain
  - DNS validation

**Multi-Environment Support**:
- Terraform workspaces (dev, test, prod)
- Environment-specific configurations
- Variable-based customization

## Data Sources

The AI digital twin is trained on multiple data sources:

1. **facts.json**: Structured professional information
   - Full name, current role, location
   - Contact information
   - Specialties and skills
   - Years of experience
   - Education background

2. **linkedin.pdf**: Complete LinkedIn profile export
   - Career history
   - Skills and endorsements
   - Recommendations
   - Professional network context

3. **summary.txt**: Professional summary
   - Career overview
   - Key achievements
   - Professional philosophy

4. **style.txt**: Communication style guide
   - Tone and voice preferences
   - Communication patterns
   - Professional demeanor

## AI Prompt Engineering

The system prompt (`context.py`) is carefully crafted to:
- Establish the AI's role as a digital twin
- Provide comprehensive context from all data sources
- Enforce professional boundaries
- Prevent hallucination (only use provided context)
- Maintain conversation quality and authenticity
- Include safety guardrails against jailbreaking

The prompt includes:
- Role definition
- Context injection (facts, LinkedIn, summary, style)
- Current date/time for temporal awareness
- Task instructions
- Critical rules (no hallucination, no jailbreaking, maintain professionalism)

## Conversation Management

**Session-Based Storage**:
- Each conversation session has a unique UUID
- Conversations are stored per session
- Supports conversation history retrieval
- Context window management (last 20 messages)

**Storage Backends**:
- **Production**: S3 bucket (persistent, scalable)
- **Development**: Local file system (`memory/` directory)

**Memory Format**:
```json
[
  {
    "role": "user",
    "content": "What is your experience with Kubernetes?",
    "timestamp": "2025-01-XX..."
  },
  {
    "role": "assistant",
    "content": "I have extensive experience...",
    "timestamp": "2025-01-XX..."
  }
]
```

## Deployment Process

### Automated Deployment (GitHub Actions)

**Workflow** (`.github/workflows/deploy.yml`):
1. **Trigger**: Push to `main` branch or manual workflow dispatch
2. **Environment Selection**: dev, test, or prod
3. **Steps**:
   - Checkout code
   - Configure AWS credentials (OIDC)
   - Set up Python (uv package manager)
   - Set up Terraform
   - Set up Node.js
   - Run deployment script
   - Get deployment outputs
   - Invalidate CloudFront cache
   - Display deployment summary

### Manual Deployment (`scripts/deploy.sh`)

The deployment script orchestrates:

1. **Lambda Package Build**:
   ```bash
   cd backend && uv run deploy.py
   ```
   - Uses Docker to build Lambda-compatible dependencies
   - Creates `lambda-deployment.zip`

2. **Terraform Apply**:
   - Initializes Terraform backend (S3)
   - Selects/creates workspace
   - Applies infrastructure changes
   - Outputs resource URLs

3. **Frontend Build & Deploy**:
   ```bash
   cd frontend
   npm install
   npm run build
   aws s3 sync ./out s3://{bucket}/
   ```
   - Builds Next.js static site
   - Syncs to S3 bucket
   - Creates `.env.production` with API URL

4. **CloudFront Invalidation**:
   - Clears CDN cache for fresh content

### Environment Configuration

**Terraform Variables**:
- `project_name`: Resource naming prefix
- `environment`: Deployment environment (dev/test/prod)
- `bedrock_model_id`: AWS Bedrock model identifier
- `lambda_timeout`: Function timeout (seconds)
- `api_throttle_*`: Rate limiting configuration
- `use_custom_domain`: Enable custom domain
- `root_domain`: Custom domain name

**Environment Variables (Lambda)**:
- `CORS_ORIGINS`: Allowed frontend origins
- `S3_BUCKET`: Memory storage bucket
- `USE_S3`: Enable S3 storage (true/false)
- `BEDROCK_MODEL_ID`: AI model identifier
- `DEFAULT_AWS_REGION`: AWS region

## Development Workflow

### Local Development

**Backend**:
```bash
cd backend
uv run uvicorn server:app --reload --port 8000
```

**Frontend**:
```bash
cd frontend
npm run dev
```

**Environment Setup**:
- Create `.env` file in backend with AWS credentials
- Set `USE_S3=false` for local file storage
- Configure `CORS_ORIGINS` to include `http://localhost:3000`

### Testing

**Health Check**:
```bash
curl http://localhost:8000/health
```

**Chat Endpoint**:
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Tell me about yourself"}'
```

### Linting & Code Quality

**Frontend**:
- ESLint configuration
- Next.js built-in linting
- TypeScript type checking

**Backend**:
- Python type hints
- Pydantic models for validation

## Security Considerations

1. **IAM Roles**: Least privilege access (Bedrock, S3)
2. **CORS**: Restricted origins
3. **API Throttling**: Rate limiting on API Gateway
4. **S3 Bucket Policies**: Private memory bucket, public frontend bucket
5. **SSL/TLS**: CloudFront HTTPS enforcement
6. **Input Validation**: Pydantic models for request validation
7. **Prompt Injection Protection**: Guardrails in system prompt

## Cost Optimization

1. **Serverless Architecture**: Pay-per-use (Lambda, API Gateway)
2. **Static Frontend**: S3 + CloudFront (low cost)
3. **Bedrock**: Pay-per-token pricing
4. **S3 Storage**: Minimal storage costs for conversations
5. **CloudFront**: CDN caching reduces origin requests

## Monitoring & Observability

**Available Endpoints**:
- `/health` - Service health check
- `/` - Service information

**Lambda Logs**:
- CloudWatch Logs for debugging
- Error tracking and monitoring

**API Gateway**:
- Request/response logging
- Throttling metrics

## Future Enhancements

Potential improvements:
- [ ] CloudWatch dashboards and alarms
- [ ] Conversation analytics
- [ ] Multi-language support
- [ ] Voice interface integration
- [ ] Enhanced memory management (vector databases)
- [ ] Fine-tuning on personal data
- [ ] Integration with calendar/availability
- [ ] Multi-modal support (images, documents)

## Troubleshooting

**Common Issues**:

1. **Lambda Timeout**:
   - Increase `lambda_timeout` in Terraform
   - Optimize Bedrock response handling

2. **CORS Errors**:
   - Verify `CORS_ORIGINS` includes frontend URL
   - Check API Gateway CORS configuration

3. **Bedrock Access Denied**:
   - Verify IAM role has Bedrock permissions
   - Check model availability in region

4. **Frontend Not Updating**:
   - Invalidate CloudFront cache
   - Verify S3 sync completed

5. **Conversation Not Persisting**:
   - Check S3 bucket permissions
   - Verify `USE_S3` environment variable

## Contributing

This is a personal project, but contributions and suggestions are welcome. Key areas for contribution:
- UI/UX improvements
- Prompt engineering enhancements
- Performance optimizations
- Documentation improvements

## License

[Specify license if applicable]

## Contact

For questions or inquiries about this project:
- Email: iankisali@gmail.com
- LinkedIn: linkedin.com/in/iankisali

---

**Last Updated**: January 2025
**Version**: 1.0
**Maintainer**: Ian Kisali

