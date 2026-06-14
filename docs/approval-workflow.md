# docs/approval-workflow.md
# Manual Approval Workflow - Production Only

## Overview

This document describes the manual approval workflow for **PRODUCTION ONLY** deployments in the terraform-infra repository. The workflow ensures that all production infrastructure changes are thoroughly reviewed, approved by the appropriate teams, and comply with FISERV's security and regulatory requirements.

**⚠️ IMPORTANT: Manual approval is ONLY required for PRODUCTION environments. Non-prod deployments are automatic after merge.**

## Approval Process

### 1. Change Initiation

Changes to production infrastructure are initiated through GitLab merge requests (MRs). The process begins with:

1. **Code Changes**: Developer creates a feature branch and makes infrastructure changes
2. **Code Review**: Peer review of the changes
3. **Terraform Validation**: GitLab validates Terraform formatting and syntax
4. **Compliance Check**: GitLab validates baseline platform controls
5. **TFE Run Trigger**: GitLab triggers the production Terraform Enterprise workspace

### 2. Planning Phase

After the merge request is merged and GitLab pre-flight checks pass:

1. **TFE Run Creation**: GitLab creates a run in the production TFE workspace
2. **Terraform Plan Generation**: TFE checks out the GitLab repo and generates an execution plan
3. **Impact Assessment**: Review the impact of changes on production systems
4. **Risk Analysis**: Identify potential risks and mitigation strategies
5. **Documentation**: Update relevant documentation

### 3. Approval Phase

The production deployment requires approval from three teams:

#### Security Team
- **Responsibility**: Review security implications, ensure compliance with security policies
- **Checklist**:
  - Verify all security controls are in place
  - Check for any security vulnerabilities
  - Ensure compliance with PCI DSS, SOX, GDPR, HIPAA, SOC 2
  - Review network security configurations
  - Validate access control mechanisms

#### Platform Team
- **Responsibility**: Validate technical changes, ensure operational excellence
- **Checklist**:
  - Review Terraform configuration for best practices
  - Validate resource quotas and limits
  - Check for performance implications
  - Ensure proper tagging and documentation
  - Validate monitoring and alerting setup

#### Compliance Team
- **Responsibility**: Ensure regulatory compliance, validate business impact
- **Checklist**:
  - Verify compliance with all relevant regulations
  - Review data residency requirements
  - Validate audit trail and logging
  - Ensure change management procedures are followed
  - Review business continuity and disaster recovery

### 4. Approval Workflow

```
GitLab MR → Merge to Main → GitLab Validate/Compliance → Trigger TFE Prod Workspace →
TFE Plan → Manual Approval → TFE Apply → Monitoring & Logging
```

**⚠️ NOTE: This approval workflow is ONLY for PRODUCTION environments. Non-prod deployments are automatic after merge.**

### 5. Approval Process Details (Production Only)

#### Security Team Approval
- **Deadline**: 2 hours from plan generation
- **Required**: Security review, compliance validation
- **Output**: Approval or rejection with comments

#### Platform Team Approval
- **Deadline**: 2 hours from security approval
- **Required**: Technical validation, risk assessment
- **Output**: Approval or rejection with comments

#### Compliance Team Approval
- **Deadline**: 2 hours from platform approval
- **Required**: Regulatory compliance, business impact analysis
- **Output**: Approval or rejection with comments

**⚠️ IMPORTANT: These approvals are ONLY required for PRODUCTION deployments. Non-prod deployments are automatic after merge.**

### 6. Deployment Phase

After all three teams approve:

1. **Terraform Apply**: Terraform Enterprise applies the approved plan
2. **Real-time Monitoring**: Monitor deployment progress
3. **Post-Deployment Validation**: Validate successful deployment
4. **Documentation Update**: Update relevant documentation
5. **Team Notification**: Notify all teams of successful deployment

### 7. Rollback Procedures

If any team rejects the approval or if the deployment fails:

#### Automated Rollback
- **Trigger**: Deployment failure detected
- **Action**: Automatically rollback to previous state
- **Time**: Within 5 minutes of failure detection

#### Manual Rollback
- **Trigger**: Critical issues requiring immediate action
- **Action**: Manual intervention to rollback changes
- **Time**: Within 30 minutes of issue detection

### 8. Post-Deployment Activities

After successful deployment:

1. **Health Checks**: Verify system health and functionality
2. **Performance Testing**: Validate performance under load
3. **Security Audit**: Review security posture
4. **Compliance Reporting**: Generate compliance reports
5. **Documentation Update**: Update runbooks and documentation

## Approval Request Template

```json
{
  "run_id": "run-123456",
  "workspace_id": "workspace-789",
  "environment": "production",
  "approvers": [
    "security-admin@fintech.com",
    "platform-admin@fintech.com",
    "compliance-admin@fintech.com"
  ],
  "deadline": "2024-01-15T14:00:00Z",
  "validation_results": {
    "infrastructure_changes": "validated",
    "security_compliance": "compliant",
    "resource_quotas": "within_limits",
    "business_impact": "low"
  },
  "rollback_plan": {
    "strategy": "blue-green",
    "estimated_time": "4 hours",
    "risk_level": "medium"
  }
}
```

## Escalation Procedures

### Level 1: Team Lead
- **Contact**: team-lead@fintech.com
- **Time**: Within 15 minutes of approval deadline
- **Action**: Request extension or override approval

### Level 2: Department Manager
- **Contact**: dept-manager@fintech.com
- **Time**: Within 30 minutes of team lead escalation
- **Action**: Review and approve with additional documentation

### Level 3: Executive Sponsor
- **Contact**: executive-sponsor@fintech.com
- **Time**: Within 1 hour of department manager escalation
- **Action**: Final approval with full risk disclosure

## Audit Trail

All approval actions are logged and audited:

1. **Approval Actions**: Who approved, when, and what they approved
2. **Rejection Reasons**: Why approvals were rejected
3. **Escalation Actions**: Who escalated and why
4. **Rollbacks**: When and why rollbacks were performed
5. **Compliance Violations**: Any compliance violations detected

## Training and Documentation

### Team Training
- **Security Team**: Security best practices, compliance requirements
- **Platform Team**: Terraform best practices, operational excellence
- **Compliance Team**: Regulatory requirements, audit procedures

### Documentation
- **Approval Workflow**: This document
- **Runbooks**: Step-by-step procedures for common operations
- **Troubleshooting**: Common issues and solutions
- **Compliance Reports**: Regular compliance reports and audits

## Contact Information

### Support Channels
- **Security Team**: security-team@fintech.com
- **Platform Team**: platform-team@fintech.com
- **Compliance Team**: compliance-team@fintech.com
- **Terraform Enterprise**: tfe-support@fintech.com

### Emergency Contacts
- **On-Call Security**: security-oncall@fintech.com
- **On-Call Platform**: platform-oncall@fintech.com
- **On-Call Compliance**: compliance-oncall@fintech.com

## Version Control

This document is version-controlled and reviewed quarterly to ensure it remains current with FISERV's security and compliance requirements.

Last Updated: 2024-01-14
Version: 1.2
