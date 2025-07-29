# Variables Directory - DEPRECATED

⚠️ **This directory is deprecated and will be removed in future versions.**

## Migration Notice

All variables have been consolidated into the main `variables.tf` file in the parent directory.

### Old Structure (Deprecated)
```
variables/
├── variables.tf                   # Basic variables
├── config-server-variables.tf    # Config server specific
└── mongodb-cluster-variables.tf  # Cluster specific
```

### New Structure (Current)
```
variables.tf                      # All variables consolidated
```

## What to Do

**If you're using old variable files:**
1. Use the main `variables.tf` file instead
2. All variable definitions are now in one place
3. No need to reference multiple variable files

**For new deployments:**
- Simply use `terraform.tfvars.example` as your starting point
- All required variables are defined in the main `variables.tf`

This consolidation provides:
- ✅ Simpler structure
- ✅ Easier maintenance
- ✅ No duplicate variable definitions
- ✅ Single source of truth for all variables