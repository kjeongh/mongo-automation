#!/bin/bash
set -euo pipefail

# MongoDB Config Servers GCP Deployment Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✅${NC} $*"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️${NC} $*"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install terraform first."
        exit 1
    fi
    
    # Check if gcloud is installed and authenticated
    if ! command -v gcloud &> /dev/null; then
        log_error "Google Cloud SDK is not installed. Please install gcloud first."
        exit 1
    fi
    
    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 &> /dev/null; then
        log_error "Please authenticate with Google Cloud: gcloud auth login"
        exit 1
    fi
    
    # Check if terraform.tfvars exists
    if [[ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]]; then
        log_error "terraform.tfvars not found. Please copy and configure terraform.tfvars.example"
        log "cp $TERRAFORM_DIR/terraform.tfvars.example $TERRAFORM_DIR/terraform.tfvars"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Initialize terraform
init_terraform() {
    log "Initializing Terraform..."
    cd "$TERRAFORM_DIR"
    
    if terraform init; then
        log_success "Terraform initialized successfully"
    else
        log_error "Failed to initialize Terraform"
        exit 1
    fi
}

# Plan terraform deployment
plan_terraform() {
    log "Creating Terraform plan..."
    cd "$TERRAFORM_DIR"
    
    if terraform plan -var-file="terraform.tfvars" -out=tfplan; then
        log_success "Terraform plan created successfully"
        log "Review the plan above. Config servers will be created in the same zone."
        
        echo
        read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Deployment cancelled by user"
            exit 0
        fi
    else
        log_error "Failed to create Terraform plan"
        exit 1
    fi
}

# Apply terraform configuration
apply_terraform() {
    log "Applying Terraform configuration..."
    cd "$TERRAFORM_DIR"
    
    if terraform apply tfplan; then
        log_success "Infrastructure deployed successfully"
    else
        log_error "Failed to deploy infrastructure"
        exit 1
    fi
}

# Display deployment information
show_deployment_info() {
    log "Retrieving deployment information..."
    cd "$TERRAFORM_DIR"
    
    # Get config server IPs
    EXTERNAL_IPS=($(terraform output -json config_server_external_ips | jq -r '.[]'))
    INTERNAL_IPS=($(terraform output -json config_server_internal_ips | jq -r '.[]'))
    ZONE=$(terraform output -raw config_server_zone)
    SUBNET=$(terraform output -raw config_server_subnet)
    CONNECTION_STRING=$(terraform output -raw config_server_connection_string)
    
    echo
    log_success "Config Server deployment completed!"
    echo
    echo "📋 Deployment Summary:"
    echo "  Zone: $ZONE"
    echo "  Subnet: $SUBNET"
    echo
    echo "🖥️  Config Server Instances:"
    for i in "${!EXTERNAL_IPS[@]}"; do
        echo "  config-server-$((i+1)):"
        echo "    External IP: ${EXTERNAL_IPS[$i]}"
        echo "    Internal IP: ${INTERNAL_IPS[$i]}"
        echo "    SSH: ssh ubuntu@${EXTERNAL_IPS[$i]}"
        echo
    done
    
    echo "🔗 Connection String:"
    echo "  $CONNECTION_STRING"
    echo
    echo "📝 Next Steps:"
    echo "  1. Wait for instances to be ready (2-3 minutes)"
    echo "  2. Run Ansible playbook to deploy MongoDB Config Servers"
    echo "  3. Initialize Config Server Replica Set"
    echo
    echo "🔍 Useful Commands:"
    echo "  # Check instance status"
    echo "  gcloud compute instances list --filter='name~config-server'"
    echo
    echo "  # SSH to config-server-1"
    echo "  ssh ubuntu@${EXTERNAL_IPS[0]}"
    echo
    echo "  # Destroy infrastructure (when needed)"
    echo "  terraform destroy -var-file=terraform.tfvars"
}

# Cleanup function
cleanup() {
    if [[ -f "$TERRAFORM_DIR/tfplan" ]]; then
        rm -f "$TERRAFORM_DIR/tfplan"
    fi
}

# Main function
main() {
    log "🚀 Starting MongoDB Config Servers GCP deployment..."
    echo
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Run deployment steps
    check_prerequisites
    init_terraform
    plan_terraform
    apply_terraform
    show_deployment_info
    
    log_success "🎉 Config Server infrastructure deployment completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    --destroy)
        log "🗑️  Destroying Config Server infrastructure..."
        cd "$TERRAFORM_DIR"
        terraform destroy -var-file="terraform.tfvars" -auto-approve
        log_success "Infrastructure destroyed"
        exit 0
        ;;
    --plan-only)
        check_prerequisites
        init_terraform
        cd "$TERRAFORM_DIR"
        terraform plan -var-file="terraform.tfvars"
        exit 0
        ;;
    --help|-h)
        echo "Usage: $0 [OPTION]"
        echo
        echo "Deploy MongoDB Config Servers to GCP"
        echo
        echo "Options:"
        echo "  --destroy     Destroy the infrastructure"
        echo "  --plan-only   Show terraform plan without applying"
        echo "  --help, -h    Show this help message"
        echo
        exit 0
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac