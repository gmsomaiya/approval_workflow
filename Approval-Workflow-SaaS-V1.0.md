# Approval Workflow SaaS — Functional Specification v1.0

> **Purpose:** Multi-tenant SaaS platform for centralised organisational approval workflows.  
> **Status:** Pre-development review document

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [User Personas & Stakeholders](#2-user-personas--stakeholders)
3. [System Architecture Overview](#3-system-architecture-overview)
4. [Detailed Feature Specifications](#4-detailed-feature-specifications)
5. [UI Wireframes & Screen Mockups](#5-ui-wireframes--screen-mockups)
6. [Business Rules & Logic](#6-business-rules--logic)
7. [Integration Specifications](#7-integration-specifications)
8. [Technical Considerations](#8-technical-considerations)
9. [Implementation Roadmap](#9-implementation-roadmap)
10. [Success Metrics & KPIs](#10-success-metrics--kpis)
11. [Risk Assessment & Mitigation](#11-risk-assessment--mitigation)
12. [Database Schema](#12-database-schema)

---

## 1. Executive Summary

### Project Overview

The Approval Workflow SaaS application is a **multi-tenant cloud-based solution** designed to streamline organisational approval processes. The system enables organisations to:

- Create custom form templates
- Define complex approval workflows with rejection handling
- Manage the entire approval lifecycle with security, notifications, webhook integrations, and comprehensive tracking

### Key Value Propositions

| Capability | Description |
|---|---|
| Multi-tenant architecture | Subscription-based usage limits with complete data isolation |
| Flexible form builder | Reusable templates with dynamic field types |
| Dynamic workflow engine | Conditional routing and rejection handling |
| Role-based access control | Hierarchical team structures |
| Webhook integration | Real-time external system updates |
| Dashboard & reporting | Comprehensive tracking and usage monitoring |
| Scalable pricing | Usage-based subscription tiers |

---

## 2. User Personas & Stakeholders

### Primary Users

#### Super Administrator
- Manages the entire SaaS platform
- Creates and manages tenants with subscription limits
- System-level configurations and monitoring
- **Cannot** access tenant-specific data
- Configures pricing tiers and usage quotas

#### Tenant Administrator
- Manages their organisation's instance within subscription limits
- Creates and manages form templates
- User management and team hierarchy setup
- Workflow configuration with rejection paths
- Webhook setup per form template
- Can also function as a regular user

#### End Users (Approvers / Requesters)
- Submit requests using published form templates
- Review and approve/reject requests with comments and attachments
- Track status of submitted requests
- Receive notifications for pending actions and TAT reminders

---

## 3. System Architecture Overview

### Multi-Tenant Security Model

| Concern | Implementation |
|---|---|
| Authentication | Tenant ID + Secret Key for external integrations |
| Key management | Encrypted tenant keys with automatic rotation |
| Password security | One-way hashing (no decryption possible) |
| Key uniqueness | Minimum 1-year non-reuse policy |
| Data isolation | Complete segregation between tenants |

### Subscription-Based Usage Control

- Template creation limits per subscription tier
- Active user limits with overage handling
- Monthly form submission quotas
- Storage limits for attachments
- Rate limiting for webhook calls

---

## 4. Detailed Feature Specifications

### 4.1 Authentication & Authorization

#### Login System

Three distinct login endpoints:
1. **Super Admin Login** — platform management
2. **Tenant Admin Login** — organisational management
3. **User Login** — form submission and approval

#### User Identification Strategy

| Rule | Detail |
|---|---|
| Unique identifier | Email + Role + Tenant ID combination |
| Cross-tenant email | Same email allowed across multiple tenants |
| Role switching | Admin can act as user within same tenant |
| Group companies | Multi-tenant user participation supported |

#### Security Features

- Auto-generated tenant secret keys (encrypted)
- Key rotation mechanism for compromised keys
- One-way password hashing (irreversible)
- Session management with appropriate timeouts
- Super admin **cannot** view tenant admin passwords

---

### 4.2 Tenant Management & Subscription Limits

#### Super Admin Capabilities

- Create new tenants with initial admin setup
- Configure subscription-based usage limits per tenant
- Deactivate tenants when needed
- Manage super admin accounts
- Monitor system-wide metrics (without tenant data access)

#### Subscription Tiers

| Limit | Basic | Professional | Enterprise |
|---|---|---|---|
| Price | $29/mo | $99/mo | $299/mo |
| Templates | 5 | 20 | Unlimited |
| Active Users | 25 | 100 | 500 |
| Forms/month | 500 | 2,000 | 10,000 |
| Storage | — | 5 GB | — |
| Webhook Calls | — | 15,000/mo | — |

#### Usage Monitoring & Billing

**Real-time tracking:**
- Current active users vs. limit
- Form templates created vs. limit
- Monthly form submissions vs. limit
- Storage utilisation vs. quota
- Webhook calls per month vs. limit

**Additional:** Configurable overage handling; usage data export for billing systems.

#### Tenant Isolation

- Complete data segregation between tenants
- Tenant-specific configurations and customisations
- Independent user bases and hierarchies
- Resource quota enforcement

---

### 4.3 User & Team Management

#### Hierarchical Team Structure

- Multiple teams per tenant
- Users can belong to multiple teams
- Different hierarchy levels per team for the same user
- Department-based and cross-departmental team configurations

#### User Management Features

- Email-based user identification
- Role assignments (Admin, User, Custom roles)
- Team membership management
- Active/inactive user status control
- User count tracking against subscription limits

---

### 4.4 Dynamic Form Template Builder & Management

#### Form Template Lifecycle

```
Draft → Published → Active ↔ Inactive
```

| Rule | Detail |
|---|---|
| Creation limits | Subscription-based |
| Immutability | Once published and used, core structure cannot be modified |
| Versioning | New versions required for structural changes |
| Deactivation | Cannot deactivate if active requests exist |

#### Form Field Types

| Type | Notes |
|---|---|
| String | With character limits |
| Integer | — |
| Float | — |
| Boolean | — |
| Date / DateTime | — |
| Dropdown / Select | — |
| Multi-select | — |
| Text Area | — |

#### Attachment Management

- Optional or mandatory attachments per form template
- File type restrictions (pdf, doc, image, etc.)
- File size limitations per attachment and total per form
- Maximum number of attachments per form submission
- Configurable: enable/disable attachments **during the approval process**
- Storage quota tracked against tenant limits

#### Form Validation

- Required field validations
- Data type validations
- Custom validation rules
- Conditional field display logic

#### Webhook Configuration Per Template

| Setting | Detail |
|---|---|
| URL | Unique webhook URL per form template |
| Events | Submit, Approve, Reject, Complete, TAT Exceeded, Revision Required |
| Auth | Bearer token or API key |
| Payload | Customisable data payload |
| Retry | Automatic retries for failed calls |

---

### 4.5 Workflow Engine & Advanced Routing

#### Workflow Configuration

**Conditional routing logic:**
- Field value-based conditions
- User/department-based routing
- Hierarchical approval chains
- Parallel approval processes
- Exception handling paths

#### Approval Process Features

- Sequential approval stages
- Conditional branching based on form data
- Multi-level approval hierarchies
- Department and cross-department routing
- Mandatory/optional comments with file attachments per approval/rejection

#### Advanced Rejection Handling

**Rejection routing options:**
1. Return to submitter for revision
2. Route to alternative approver
3. Escalate to higher authority
4. End workflow with rejection

**Revision process:**
- Submitters can modify and resubmit rejected forms
- Configurable revision limits per form (default: 3)
- Option to reset approval chain on revision
- Full revision history tracked

**Rejection management:**
- Pre-defined rejection reasons/categories
- Custom rejection comments
- Notification to submitter with rejection details
- Guidance for resubmission

#### TAT (Turnaround Time) Management

- Configurable TAT per workflow stage
- Automated reminders before TAT expiry
- Escalation rules when TAT is exceeded
- Alternative routing options for missed TATs
- TAT tracking and reporting
- Business hours calculation (excludes weekends and holidays)

---

### 4.6 Notification System

#### Communication Channels

| Channel | Usage |
|---|---|
| Email | All key events |
| In-app | Real-time alerts |
| Dashboard | Visual indicators |
| Webhook | External system integration |

#### Notification Types

- New approval requests
- TAT reminder alerts
- Approval/rejection notifications
- Workflow completion updates
- TAT missed escalations
- Revision requests
- Template status changes
- Quota warnings (at 80% and 95%)

---

### 4.7 Dashboard & Reporting

#### User Dashboard

- Pending approvals queue with TAT information
- Submitted requests tracking with status
- Approval history and performance metrics
- Form template usage statistics
- Personal workload distribution

#### Admin Dashboard

- Tenant-wide workflow analytics
- User performance metrics
- Form template usage statistics
- Subscription usage monitoring
- System health monitoring
- Audit trail reporting
- Webhook delivery status

#### Subscription Usage Dashboard

- Real-time usage vs. limits visualisation
- Monthly trends and projections
- Cost optimisation recommendations
- Overage alerts and warnings

---

## 5. UI Wireframes & Screen Mockups

### 5.1 Super Admin Interface

```
┌─────────────────────────────────────────────────────┐
│  ApprovalFlow SaaS - Super Admin Portal             │
├─────────────────────────────────────────────────────┤
│  Dashboard | Tenants | Plans | System | Analytics   │
├─────────────────────────────────────────────────────┤
│  Tenant Management                                  │
│  ┌─────────────────────────────────────────────┐   │
│  │  Active Tenants: 24    Inactive: 3          │   │
│  │  [+ Create New Tenant]                      │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  Recent Tenant Activities                           │
│  ┌─────────────────────────────────────────────┐   │
│  │ Tenant Name   │Plan│Usage│Created│Actions   │   │
│  │ Company ABC   │Pro │ 84% │2024-01│View Edit │   │
│  │ Corp XYZ      │Ent │ 45% │2024-02│View Edit │   │
│  │ StartupCo     │Basic│120%│2024-03│View Alert│   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  System Metrics                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ Total Users: 1,247  │ Templates: 156        │   │
│  │ Monthly Forms: 45K  │ Webhooks: 89K         │   │
│  │ Storage Used: 2.4TB │ Revenue: $12,450      │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  Subscription Plans Management                      │
│  ┌─────────────────────────────────────────────┐   │
│  │ Basic: $29/mo   │ Pro: $99/mo  │ Ent: $299/mo│  │
│  │ 5 Templates     │ 20 Templates │ Unlimited   │  │
│  │ 25 Users        │ 100 Users    │ 500 Users   │  │
│  │ 500 Forms/mo    │ 2K Forms/mo  │ 10K Forms/mo│  │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### 5.2 Tenant Admin Dashboard

```
┌─────────────────────────────────────────────────────┐
│  [Company Logo] - Admin Portal      │ [Profile ▼]   │
├─────────────────────────────────────────────────────┤
│Dashboard│Users│Teams│Templates│Workflows│Usage│Settings│
├─────────────────────────────────────────────────────┤
│ Template Management                                 │
│ ┌─────────────────────────────────────────────┐   │
│ │ Templates: 5/10 Used    [+ Create Template] │   │
│ │ Active: 4   Inactive: 1                     │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ Template Library                                    │
│ ┌─────────────────────────────────────────────┐   │
│ │ Template Name     │Status │Created │Actions  │   │
│ │ Leave Request     │Active │Mar 15  │Edit View│   │
│ │ Purchase Order    │Active │Mar 20  │Edit View│   │
│ │ Travel Request    │Inactive│Apr 01 │Activate │   │
│ │ IT Support        │Active │Apr 10  │Edit View│   │
│ │ Training Request  │Draft  │May 20  │Complete │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ Subscription Usage                                  │
│ ┌─────────────────────────────────────────────┐   │
│ │ This Month: 234/500 Forms (47%)             │   │
│ │ Storage Used: 1.2GB/2GB (60%)               │   │
│ │ Active Users: 42/50 (84%)                   │   │
│ │ Webhook Calls: 8,945/10,000 (89%)           │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ API Configuration                                   │
│ ┌─────────────────────────────────────────────┐   │
│ │ Tenant ID: COMP_ABC_001                     │   │
│ │ Secret Key: [●●●●●●●●●●●●] [Rotate Key]     │   │
│ │ Last Rotated: 2024-03-15                    │   │
│ └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### 5.3 Form Template Builder Interface

```
┌─────────────────────────────────────────────────────┐
│  Form Template Builder - Leave Request Template     │
├─────────────────────────────────────────────────────┤
│ Properties │ Fields │ Workflow │ Webhooks │ Settings │
├─────────────────────────────────────────────────────┤
│ Template Configuration                              │
│ ┌─────────────────────────────────────────────┐   │
│ │ Template Name: [Leave Request Template    ] │   │
│ │ Description: [Employee leave application  ] │   │
│ │ Category: [HR Forms ▼]                     │   │
│ │ Status: ○ Draft ● Active ○ Inactive        │   │
│ │ ☑ Allow Attachments in Submissions         │   │
│ │ ☑ Allow Attachments in Approvals           │   │
│ │ Max Files: [3]  Size Limit: [5MB ▼]        │   │
│ │ Allowed Types: [PDF, DOC, JPG]             │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ Form Fields                                         │
│ ┌─────────────────────────────────────────────┐   │
│ │ [+ Add Field ▼]                             │   │
│ │ 1. Employee Name [Text] [Required] [Edit]   │   │
│ │ 2. Leave Type [Dropdown] [Required] [Edit]  │   │
│ │ 3. Start Date [Date] [Required] [Edit]      │   │
│ │ 4. End Date [Date] [Required] [Edit]        │   │
│ │ 5. Reason [TextArea] [Optional] [Edit]      │   │
│ │ 6. Emergency Contact [Text] [Optional][Edit]│   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ Webhook Configuration                               │
│ ┌─────────────────────────────────────────────┐   │
│ │ Webhook URL: [https://api.company.com/hook] │   │
│ │ Events: ☑Submit ☑Approve ☑Reject ☑Complete │   │
│ │         ☑TAT Exceeded ☑Revision Required   │   │
│ │ Auth Type: [Bearer Token ▼]                │   │
│ │ Retry Count: [3]  Timeout: [30s]            │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ [Save Draft] [Preview] [Publish Template]           │
└─────────────────────────────────────────────────────┘
```

### 5.4 Workflow Designer with Rejection Handling

```
┌─────────────────────────────────────────────────────┐
│  Workflow Designer - Leave Approval Process         │
├─────────────────────────────────────────────────────┤
│ Visual Designer │ Conditions │ Rejections │ TAT      │
├─────────────────────────────────────────────────────┤
│ Workflow Steps                                      │
│ ┌─────────────────────────────────────────────┐   │
│ │  [Start] → [Direct Manager] → [HR Review]   │   │
│ │     ↓             ↓              ↓          │   │
│ │  Submit    Approve/Reject    Final Approval  │   │
│ │              ↓    ↓    ↓                    │   │
│ │         [Approved][Rejected][Hold]           │   │
│ │                    ↓                        │   │
│ │              [Back to Submitter]             │   │
│ │                    ↓                        │   │
│ │              [Revision Process]             │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ Step Configuration - Direct Manager Approval        │
│ ┌─────────────────────────────────────────────┐   │
│ │ Approval Actions:                           │   │
│ │ ☑ Allow Comments (Required)                 │   │
│ │ ☑ Allow Attachments                         │   │
│ │ ☑ Enable Hold/Pending Status               │   │
│ │                                             │   │
│ │ Rejection: ● Back to Submitter             │   │
│ │            ○ Route to [Select User ▼]      │   │
│ │            ○ Escalate  ○ End Workflow      │   │
│ │                                             │   │
│ │ Max Revisions: [3]  ☑ Reset approval chain │   │
│ │                                             │   │
│ │ TAT: [2] Business Days                     │   │
│ │ Reminder: [4] Hours before expiry          │   │
│ │ On TAT Miss: ● Escalate to [HR ▼]         │   │
│ └─────────────────────────────────────────────┘   │
│ [Save Workflow] [Test Run] [Activate]               │
└─────────────────────────────────────────────────────┘
```

### 5.5 User Dashboard Interface

```
┌─────────────────────────────────────────────────────┐
│  Welcome, John Doe                   │ [Profile ▼]  │
├─────────────────────────────────────────────────────┤
│ My Dashboard │ Submit Request │ Reports │ Settings   │
├─────────────────────────────────────────────────────┤
│ Available Templates                                 │
│ [Leave Request] [Purchase Order] [Travel]           │
│ [IT Support] [Training Request] [Expense]           │
│                                                     │
│ Pending Actions (5)                                 │
│ ┌─────────────────────────────────────────────┐   │
│ │ Request Type   │ Submitter │ Due Date│Action │   │
│ │ Leave Request  │ Jane Doe  │ Today   │Review │   │
│ │ Purchase Order │ Bob Smith │ Tomorrow│Review │   │
│ │ Travel Request │ Alice J.  │ 2 days  │Review │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ My Submissions                                      │
│ ┌─────────────────────────────────────────────┐   │
│ │ Request Type   │ Status    │ Submitted│Action │   │
│ │ Leave Request  │ Approved  │ 2024-05-20│View  │   │
│ │ Training Req.  │ Pending   │ 2024-05-22│Track │   │
│ │ Equipment Req. │ Rejected  │ 2024-05-18│Revise│   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ Notifications (3)                                   │
│ ┌─────────────────────────────────────────────┐   │
│ │ • TAT reminder: Purchase Order due in 4hrs  │   │
│ │ • Revision required: Equipment Request      │   │
│ │ • New approval: Travel Request submitted    │   │
│ └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### 5.6 Enhanced Approval Review Interface

```
┌─────────────────────────────────────────────────────┐
│  Leave Request Review - REQ#LR-2024-001             │
├─────────────────────────────────────────────────────┤
│ Details │ History │ Comments │ Attachments │ Actions │
├─────────────────────────────────────────────────────┤
│ Request Information                                 │
│ ┌─────────────────────────────────────────────┐   │
│ │ Employee: Jane Doe (Engineering)            │   │
│ │ Leave Type: Annual  Duration: May 28–30     │   │
│ │ Total Days: 3   Balance after: 12 days      │   │
│ │ Attachments: [medical-cert.pdf]             │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ Approval History                                    │
│ ┌─────────────────────────────────────────────┐   │
│ │ Step 1: Direct Manager (Mike Johnson)       │   │
│ │ ✓ Approved — "Good coverage planned"        │   │
│ │                                             │   │
│ │ Step 2: HR Review (Current - You)           │   │
│ │ ⏳ Pending  Due: Today 5:00 PM  (4h 23m)   │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ Review Actions                                      │
│ ┌─────────────────────────────────────────────┐   │
│ │ Decision: ○ Approve  ○ Reject  ○ Hold       │   │
│ │ Comments: [Required — add review here...]   │   │
│ │ Attachments: [Browse Files] (Optional)      │   │
│ │                                             │   │
│ │ If Rejecting:                               │   │
│ │ ● Back to submitter for revision           │   │
│ │ ○ End workflow  ○ Route to [Select ▼]      │   │
│ │ Rejection Category: [Select Reason ▼]       │   │
│ │                                             │   │
│ │ [Submit Decision] [Save Draft] [Cancel]     │   │
│ └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### 5.7 Form Submission Interface

```
┌─────────────────────────────────────────────────────┐
│  Submit New Request - Leave Request Template         │
├─────────────────────────────────────────────────────┤
│ Form Details │ Attachments │ Review │ Submit         │
├─────────────────────────────────────────────────────┤
│ Template Info                                       │
│ Approval Process: Manager → HR Review               │
│ Estimated TAT: 2-3 business days                    │
│ Monthly Quota: 234/500 forms used                   │
│                                                     │
│ Request Details                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ Employee Name: [John Doe                 ]* │   │
│ │ Leave Type: [Annual Leave ▼              ]* │   │
│ │ Start Date: [06/01/2024                  ]* │   │
│ │ End Date: [06/03/2024                    ]* │   │
│ │ Total Days: 3 days (Auto-calculated)        │   │
│ │ Reason: [Optional text area...]             │   │
│ │ Emergency Contact: [+1-555-123-4567      ]  │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ Attachments (Optional)                              │
│ ┌─────────────────────────────────────────────┐   │
│ │ [Drop files here or browse]                │   │
│ │ Allowed: PDF, DOC, JPG (Max 5MB each, 3 max)│   │
│ │ [medical-certificate.pdf (2.3MB) [×]]       │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ [Save Draft] [Preview] [Submit Request]             │
└─────────────────────────────────────────────────────┘
```

### 5.8 Subscription & Usage Management Interface

```
┌─────────────────────────────────────────────────────┐
│  Subscription Management - Company ABC               │
├─────────────────────────────────────────────────────┤
│ Plan Details │ Usage │ Billing │ Limits │ Support    │
├─────────────────────────────────────────────────────┤
│ Current Plan: Professional ($99/month)              │
│                                                     │
│ Usage & Limits                                      │
│ ┌─────────────────────────────────────────────┐   │
│ │ Templates:    5/20    ████▓░░░░░░░░░░  25%  │   │
│ │ Active Users: 42/100  ████████▓░░░░░░  42%  │   │
│ │ Monthly Forms:1,234/2,000 ████████████  62%  │   │
│ │ Storage:      1.2/5GB ████▓░░░░░░░░░░  24%  │   │
│ │ Webhooks:     8,945/15,000 ███████████  60%  │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ Overage Alerts                                      │
│ ⚠ Webhook calls at 60% — monitor usage             │
│ ✓ All other limits within normal range              │
│                                                     │
│ Projected This Month:                               │
│ • Forms: 1,850/2,000 (92%)  • Storage: 1.8/5GB     │
└─────────────────────────────────────────────────────┘
```

### 5.9 Webhook Configuration & Monitoring Interface

```
┌─────────────────────────────────────────────────────┐
│  Webhook Management - Leave Request Template        │
├─────────────────────────────────────────────────────┤
│ Configuration │ Testing │ Logs │ Analytics │ Docs    │
├─────────────────────────────────────────────────────┤
│ Webhook Endpoints                                   │
│ Primary URL: [https://api.company.com/wh]           │
│ Backup URL:  [https://backup.company.com/wh]        │
│ Status: ● Active   Last Success: 2 minutes ago      │
│                                                     │
│ Event Configuration                                 │
│ ☑ Form Submitted    ☑ Approval Required             │
│ ☑ Step Approved     ☑ Step Rejected                 │
│ ☑ Workflow Complete ☑ TAT Warning / Exceeded        │
│ ☑ Revision Required ☑ Form Cancelled                │
│                                                     │
│ Auth & Security                                     │
│ Auth Type: Bearer Token   IP Whitelist: configured  │
│ Timeout: 30s   Retries: 3   Intervals: 1m, 5m, 15m │
│                                                     │
│ Recent Activity                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ Time     │ Event          │ Status │ Code    │   │
│ │ 14:32:15 │ Form Submitted │ ✅     │ 200 OK  │   │
│ │ 14:30:22 │ Step Approved  │ ✅     │ 200 OK  │   │
│ │ 14:25:11 │ TAT Warning    │ ❌     │ Timeout │   │
│ └─────────────────────────────────────────────┘   │
│ [Test Webhook] [View Full Logs] [Export Config]     │
└─────────────────────────────────────────────────────┘
```

### 5.10 Revision & Resubmission Interface

```
┌─────────────────────────────────────────────────────┐
│  Revise Request - Equipment Request REQ#EQ-2024-045 │
├─────────────────────────────────────────────────────┤
│ Original │ Rejection Details │ Revision │ Submit     │
├─────────────────────────────────────────────────────┤
│ Rejection Information                               │
│ Rejected By: Sarah Johnson (IT Manager)             │
│ Reason: Budget Constraints                          │
│ "The requested laptop exceeds budget. Please        │
│  revise to under $1,200 or add justification."      │
│                                                     │
│ Revision: #1 of 3 allowed                          │
│                                                     │
│ Revised Request                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ Model: [Dell Latitude 5520]                 │   │
│ │ Cost:  [$1,150]                             │   │
│ │ Justification: [Detailed business case...]  │   │
│ │                                             │   │
│ │ Changes Made:                               │   │
│ │ ☑ Reduced cost from $1,500 to $1,150       │   │
│ │ ☑ Added detailed business justification    │   │
│ │ ☑ Included manager pre-approval email      │   │
│ └─────────────────────────────────────────────┘   │
│ [Save Draft] [Preview Changes] [Submit Revision]    │
└─────────────────────────────────────────────────────┘
```

---

## 6. Business Rules & Logic

### 6.1 Template Management Rules

| Rule | Detail |
|---|---|
| Creation limits | Basic: 5 / Pro: 20 / Enterprise: Unlimited |
| Status workflow | Draft → Published → Active / Inactive |
| Immutability | Once published and used, core structure is locked |
| Versioning | Structural changes require a new version |
| Deactivation | Blocked if active requests exist |

### 6.2 Form Submission Rules

| Rule | Detail |
|---|---|
| Quota enforcement | Submissions blocked when monthly quota exceeded |
| Storage enforcement | File uploads blocked when storage quota reached |
| Template availability | Only Active templates can receive new submissions |
| Duplicate prevention | System checks for duplicates within a defined timeframe |
| Auto-numbering | Sequential request numbers per template (e.g. LR-2024-001) |

### 6.3 Workflow Execution Rules

| Rule | Detail |
|---|---|
| Sequential processing | Steps execute in order unless conditions trigger skips |
| Conditional routing | Field values determine next approver or skip |
| TAT calculation | Business hours only (excludes weekends and holidays) |
| Escalation | Automatic routing when TAT exceeded per configuration |
| Parallel approvals | Multiple approvers can review simultaneously when configured |

### 6.4 Rejection & Revision Rules

| Rule | Detail |
|---|---|
| Revision limits | Configurable max revisions per form (default: 3) |
| Revision tracking | Complete audit trail of all revisions and changes |
| Approval chain reset | Optional reset of chain on revision |
| Rejection categories | Predefined and custom reasons |
| Resubmission | Mandatory comments explaining changes made |

### 6.5 Notification Rules

| Trigger | Action |
|---|---|
| TAT approaching | Reminders at configured intervals before expiry |
| TAT escalation | Notifies both original approver and escalation target |
| Webhook failures | Admin notification after 3 consecutive failures |
| Quota warnings | Sent at 80% and 95% of monthly limits |
| Status changes | Automatic notifications to submitter on every change |

### 6.6 Security & Access Rules

| Rule | Detail |
|---|---|
| Tenant isolation | Complete data segregation — no cross-tenant access |
| Role-based permissions | Granular permissions per role |
| API rate limiting | Based on subscription tier |
| Key rotation | Mandatory after security incidents |
| Session management | Configurable timeouts based on security policies |

---

## 7. Integration Specifications

### 7.1 Webhook Integration

| Feature | Detail |
|---|---|
| Architecture | Event-driven, real-time notifications |
| Payload format | Standardised JSON across all webhooks |
| Retry mechanism | Exponential backoff for failed deliveries |
| Security | Signature verification + IP whitelisting |
| Monitoring | Comprehensive delivery tracking and failure alerting |

### 7.2 External System Integration

| System | Support |
|---|---|
| SSO | SAML and OAuth2 for enterprise authentication |
| Directory services | LDAP / Active Directory integration |
| Email | SMTP configuration for notification delivery |
| File storage | Cloud storage providers for large attachments |
| Reporting | Data export for external analytics tools |

### 7.3 Mobile Application Support

| Feature | Detail |
|---|---|
| Responsive design | Web interface optimised for mobile |
| Progressive Web App | Offline capability for form submissions |
| Push notifications | Mobile push for urgent approvals |
| Biometric auth | Fingerprint and face recognition support |

---

## 8. Technical Considerations

### 8.1 Performance Requirements

| Metric | Target |
|---|---|
| API response time | < 200ms for standard operations |
| Concurrent users | 1,000+ simultaneous per tenant |
| File handling | Attachments up to 10 MB |
| Caching | Redis-based for frequently accessed data |

### 8.2 Scalability Architecture

| Component | Approach |
|---|---|
| Services | Microservices — independently scalable |
| Load balancing | Horizontal scaling with automatic distribution |
| Database | Tenant-based sharding for performance |
| CDN | Global delivery for file attachments |
| Auto-scaling | Automatic resource allocation on demand |

### 8.3 Security Framework

| Layer | Implementation |
|---|---|
| Encryption | AES-256 at rest and in transit |
| Authentication | Multi-factor authentication support |
| Authorisation | RBAC with principle of least privilege |
| Audit logging | Comprehensive logging of all system activities |
| Compliance | GDPR, SOX, industry-specific |

### 8.4 Disaster Recovery

| Metric | Target |
|---|---|
| Backup | Automated daily with point-in-time recovery |
| Geographic redundancy | Multi-region deployment |
| RTO | < 1 hour |
| RPO | < 15 minutes |
| Failover | Automated with manual override |

---

## 9. Implementation Roadmap

### Phase 1 — Foundation (Weeks 1–6)

**Focus:** Core infrastructure

- Multi-tenant database architecture
- User authentication and authorisation system
- Basic tenant management functionality
- Super admin portal development
- Security framework implementation

**Deliverables:** Tenant creation & management, user registration & login, basic dashboards, security audit

---

### Phase 2 — Template Engine (Weeks 7–12)

**Focus:** Form template builder

- Dynamic form field creation
- Template lifecycle management
- Validation rule engine
- File attachment handling
- Template preview and testing

**Deliverables:** Complete form template builder, template library, form validation system, attachment processing

---

### Phase 3 — Workflow Engine (Weeks 13–18)

**Focus:** Advanced workflow management

- Visual workflow designer
- Conditional routing logic
- TAT management system
- Rejection handling workflow
- Approval interface development

**Deliverables:** Workflow designer, approval processing, TAT tracking/notifications, rejection & revision workflow

---

### Phase 4 — Integration & Webhooks (Weeks 19–22)

**Focus:** External system integration

- Webhook configuration system
- Real-time event processing
- External API integrations
- Enhanced notification system
- Mobile responsiveness

**Deliverables:** Webhook management, external connectors, enhanced notifications, mobile-optimised UI

---

### Phase 5 — Analytics & Optimisation (Weeks 23–26)

**Focus:** Reporting and analytics

- Usage analytics dashboard
- Performance monitoring
- Subscription management
- Billing integration
- System optimisation

**Deliverables:** Comprehensive reporting, usage monitoring dashboard, billing/subscription management, performance optimisation

---

### Phase 6 — Testing & Deployment (Weeks 27–30)

**Focus:** Quality assurance and launch

- Comprehensive system testing
- Security penetration testing
- Load testing and optimisation
- Documentation completion
- Production deployment

**Deliverables:** Production-ready system, complete documentation, training materials, go-live support

---

## 10. Success Metrics & KPIs

### 10.1 Business Metrics

| KPI | Target |
|---|---|
| User adoption | 85% of invited users active within 30 days |
| Process efficiency | 60% reduction in average approval cycle time |
| NPS | > 75 |
| Revenue growth | 25% MoM recurring revenue growth |
| Churn rate | < 5% monthly |

### 10.2 Technical Metrics

| KPI | Target |
|---|---|
| Uptime | 99.9% SLA |
| API response time | 95% of calls < 200ms |
| Error rate | < 0.1% system errors |
| Security | Zero breaches or data incidents |
| Scalability | Handle 10x traffic without degradation |

### 10.3 Usage Metrics

| KPI | Target |
|---|---|
| Templates per tenant | Average 8 |
| Approval steps per workflow | Average 3.5 |
| Forms with attachments | 65% |
| Mobile approvals | 40% |
| Webhook delivery success | 99.5% |

---

## 11. Risk Assessment & Mitigation

### 11.1 Technical Risks

| Risk | Impact | Probability | Mitigation |
|---|---|---|---|
| Data security breach | High | Low | Multi-layer security, encryption, regular audits |
| Performance degradation | Medium | Medium | Load testing, auto-scaling, monitoring |
| Integration failures | Medium | Medium | Retry mechanisms, fallback procedures, monitoring |

### 11.2 Business Risks

| Risk | Impact | Probability | Mitigation |
|---|---|---|---|
| Customer churn (complexity) | High | Medium | User-friendly design, training, support |
| Competitive pressure | Medium | High | Unique features, competitive pricing, customer focus |
| Regulatory non-compliance | High | Low | Compliance framework, legal review, audit procedures |

---

## 12. Database Schema

> **Reference only — subject to change.**  
> This schema is a starting point derived from the functional requirements. Table structures, column names, data types, and indexes will be revised as development progresses and implementation details are finalised. Do not treat this as a fixed contract.

### Design Principles

- **Multi-tenant isolation:** `tenant_id` on all tenant-specific tables
- **Audit trail:** `created_at`/`updated_at` + user tracking on all records
- **Soft deletes:** `is_deleted` flags where appropriate
- **Indexing:** Optimised for frequently queried columns
- **Data integrity:** Foreign key and check constraints

---

### 12.1 Super Admin Tables

#### `super_admins`

```sql
CREATE TABLE super_admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES super_admins(id)
);

CREATE INDEX idx_super_admins_email ON super_admins(email);
CREATE INDEX idx_super_admins_active ON super_admins(is_active);
```

#### `subscription_plans`

```sql
CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price_monthly DECIMAL(10,2) NOT NULL,
    price_yearly DECIMAL(10,2),
    max_templates INTEGER NOT NULL,
    max_users INTEGER NOT NULL,
    max_monthly_forms INTEGER NOT NULL,
    max_storage_gb INTEGER NOT NULL,
    max_webhook_calls INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_subscription_plans_active ON subscription_plans(is_active);
```

---

### 12.2 Tenant Management Tables

#### `tenants`

```sql
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id VARCHAR(50) UNIQUE NOT NULL,           -- e.g. COMP_ABC_001
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255),
    subscription_plan_id UUID REFERENCES subscription_plans(id),
    secret_key_hash VARCHAR(255) NOT NULL,
    secret_key_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    secret_key_expires_at TIMESTAMP,
    billing_cycle ENUM('monthly', 'yearly') DEFAULT 'monthly',
    subscription_start_date DATE,
    subscription_end_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES super_admins(id)
);

CREATE UNIQUE INDEX idx_tenants_tenant_id ON tenants(tenant_id);
CREATE INDEX idx_tenants_active ON tenants(is_active);
CREATE INDEX idx_tenants_domain ON tenants(domain);
```

#### `tenant_usage_limits`

```sql
CREATE TABLE tenant_usage_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    max_templates INTEGER NOT NULL,
    max_users INTEGER NOT NULL,
    max_monthly_forms INTEGER NOT NULL,
    max_storage_gb INTEGER NOT NULL,
    max_webhook_calls INTEGER NOT NULL,
    effective_from DATE NOT NULL,
    effective_until DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tenant_usage_limits_tenant ON tenant_usage_limits(tenant_id);
CREATE INDEX idx_tenant_usage_limits_effective ON tenant_usage_limits(effective_from, effective_until);
```

#### `tenant_key_rotation_history`

```sql
CREATE TABLE tenant_key_rotation_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    old_key_hash VARCHAR(255) NOT NULL,
    new_key_hash VARCHAR(255) NOT NULL,
    rotation_reason ENUM('scheduled', 'compromised', 'admin_request') NOT NULL,
    rotated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_key_disabled_at TIMESTAMP NOT NULL,
    rotated_by UUID
);

CREATE INDEX idx_tenant_key_rotation_tenant ON tenant_key_rotation_history(tenant_id);
CREATE INDEX idx_tenant_key_rotation_date ON tenant_key_rotation_history(rotated_at);
```

---

### 12.3 User Management Tables

#### `users`

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'user', 'approver') NOT NULL DEFAULT 'user',
    department VARCHAR(100),
    manager_id UUID REFERENCES users(id),
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP,
    password_changed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

CREATE UNIQUE INDEX idx_users_email_tenant_role ON users(email, tenant_id, role);
CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_users_active ON users(is_active);
CREATE INDEX idx_users_manager ON users(manager_id);
```

#### `teams`

```sql
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    department VARCHAR(100),
    parent_team_id UUID REFERENCES teams(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_teams_tenant ON teams(tenant_id);
CREATE INDEX idx_teams_parent ON teams(parent_team_id);
```

#### `team_members`

```sql
CREATE TABLE team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    hierarchy_level INTEGER DEFAULT 1,
    role_in_team VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

CREATE UNIQUE INDEX idx_team_members_team_user ON team_members(team_id, user_id) WHERE is_active = true;
CREATE INDEX idx_team_members_user ON team_members(user_id);
```

---

### 12.4 Form Template Tables

#### `form_templates`

```sql
CREATE TABLE form_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    version INTEGER DEFAULT 1,
    status ENUM('draft', 'published', 'active', 'inactive') DEFAULT 'draft',
    allow_attachments BOOLEAN DEFAULT false,
    max_attachments INTEGER DEFAULT 3,
    max_attachment_size_mb INTEGER DEFAULT 5,
    allowed_file_types JSON,                        -- ["pdf","doc","jpg"]
    allow_approval_attachments BOOLEAN DEFAULT false,
    monthly_usage_count INTEGER DEFAULT 0,
    total_usage_count INTEGER DEFAULT 0,
    is_deleted BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    published_at TIMESTAMP,
    published_by UUID REFERENCES users(id)
);

CREATE INDEX idx_form_templates_tenant ON form_templates(tenant_id);
CREATE INDEX idx_form_templates_status ON form_templates(status);
CREATE INDEX idx_form_templates_active ON form_templates(tenant_id, status) WHERE is_deleted = false;
```

#### `form_template_fields`

```sql
CREATE TABLE form_template_fields (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES form_templates(id) ON DELETE CASCADE,
    field_name VARCHAR(100) NOT NULL,
    field_label VARCHAR(255) NOT NULL,
    field_type ENUM('string','integer','float','boolean','date','datetime',
                    'dropdown','multiselect','textarea') NOT NULL,
    is_required BOOLEAN DEFAULT false,
    field_order INTEGER NOT NULL,
    max_length INTEGER,
    min_value NUMERIC,
    max_value NUMERIC,
    default_value TEXT,
    options JSON,                  -- ["opt1","opt2"] for dropdown/multiselect
    validation_rules JSON,
    conditional_logic JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_form_template_fields_template ON form_template_fields(template_id);
CREATE INDEX idx_form_template_fields_order ON form_template_fields(template_id, field_order);
```

#### `form_template_webhooks`

```sql
CREATE TABLE form_template_webhooks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES form_templates(id) ON DELETE CASCADE,
    webhook_url VARCHAR(500) NOT NULL,
    backup_url VARCHAR(500),
    auth_type ENUM('none','bearer_token','api_key','basic_auth') DEFAULT 'none',
    auth_credentials JSON,              -- Encrypted
    signing_secret VARCHAR(255),
    timeout_seconds INTEGER DEFAULT 30,
    retry_count INTEGER DEFAULT 3,
    retry_intervals JSON DEFAULT '[60, 300, 900]',  -- 1m, 5m, 15m
    enabled_events JSON NOT NULL,       -- ["submitted","approved","rejected",...]
    is_active BOOLEAN DEFAULT true,
    last_success_at TIMESTAMP,
    last_failure_at TIMESTAMP,
    failure_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_form_template_webhooks_template ON form_template_webhooks(template_id);
CREATE INDEX idx_form_template_webhooks_active ON form_template_webhooks(is_active);
```

---

### 12.5 Workflow Tables

#### `workflows`

```sql
CREATE TABLE workflows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    template_id UUID REFERENCES form_templates(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    version INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_workflows_tenant ON workflows(tenant_id);
CREATE INDEX idx_workflows_template ON workflows(template_id);
```

#### `workflow_steps`

```sql
CREATE TABLE workflow_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id UUID REFERENCES workflows(id) ON DELETE CASCADE,
    step_name VARCHAR(255) NOT NULL,
    step_order INTEGER NOT NULL,
    assignee_type ENUM('specific_user','role','hierarchy','team') NOT NULL,
    assignee_config JSON NOT NULL,
    tat_hours INTEGER,
    reminder_hours INTEGER,
    tat_miss_action ENUM('wait','escalate','auto_approve','auto_reject') DEFAULT 'wait',
    escalation_config JSON,
    require_comments BOOLEAN DEFAULT false,
    allow_attachments BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_workflow_steps_workflow ON workflow_steps(workflow_id);
CREATE INDEX idx_workflow_steps_order ON workflow_steps(workflow_id, step_order);
```

#### `workflow_step_conditions`

```sql
CREATE TABLE workflow_step_conditions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    step_id UUID REFERENCES workflow_steps(id) ON DELETE CASCADE,
    condition_type ENUM('field_value','user_role','team_membership','custom') NOT NULL,
    field_name VARCHAR(100),
    operator ENUM('equals','not_equals','greater_than','less_than',
                  'contains','in','not_in') NOT NULL,
    condition_value JSON NOT NULL,
    action ENUM('skip_step','goto_step','end_workflow','route_to_user') NOT NULL,
    action_config JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_workflow_step_conditions_step ON workflow_step_conditions(step_id);
```

#### `workflow_rejection_paths`

```sql
CREATE TABLE workflow_rejection_paths (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    step_id UUID REFERENCES workflow_steps(id) ON DELETE CASCADE,
    rejection_action ENUM('back_to_submitter','route_to_user',
                          'escalate','end_workflow') NOT NULL,
    route_to_user_id UUID REFERENCES users(id),
    route_to_step_id UUID REFERENCES workflow_steps(id),
    allow_revision BOOLEAN DEFAULT true,
    max_revisions INTEGER DEFAULT 3,
    reset_approval_chain BOOLEAN DEFAULT false,
    require_revision_comments BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_workflow_rejection_paths_step ON workflow_rejection_paths(step_id);
```

---

### 12.6 Form Submission Tables

#### `form_submissions`

```sql
CREATE TABLE form_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    template_id UUID REFERENCES form_templates(id),
    workflow_id UUID REFERENCES workflows(id),
    request_number VARCHAR(50) NOT NULL,            -- e.g. LR-2024-001
    submitter_id UUID REFERENCES users(id),
    form_data JSON NOT NULL,
    current_step_id UUID REFERENCES workflow_steps(id),
    current_assignee_id UUID REFERENCES users(id),
    status ENUM('draft','submitted','in_review','approved',
                'rejected','cancelled','completed') DEFAULT 'draft',
    priority ENUM('low','normal','high','urgent') DEFAULT 'normal',
    estimated_completion_date TIMESTAMP,
    actual_completion_date TIMESTAMP,
    revision_count INTEGER DEFAULT 0,
    is_revision BOOLEAN DEFAULT false,
    original_submission_id UUID REFERENCES form_submissions(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    submitted_at TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE UNIQUE INDEX idx_form_submissions_request_number ON form_submissions(tenant_id, request_number);
CREATE INDEX idx_form_submissions_tenant ON form_submissions(tenant_id);
CREATE INDEX idx_form_submissions_submitter ON form_submissions(submitter_id);
CREATE INDEX idx_form_submissions_assignee ON form_submissions(current_assignee_id);
CREATE INDEX idx_form_submissions_status ON form_submissions(status);
```

#### `form_submission_attachments`

```sql
CREATE TABLE form_submission_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID REFERENCES form_submissions(id) ON DELETE CASCADE,
    original_filename VARCHAR(255) NOT NULL,
    stored_filename VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_form_submission_attachments_submission ON form_submission_attachments(submission_id);
```

#### `form_submission_approvals`

```sql
CREATE TABLE form_submission_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID REFERENCES form_submissions(id) ON DELETE CASCADE,
    step_id UUID REFERENCES workflow_steps(id),
    assignee_id UUID REFERENCES users(id),
    decision ENUM('pending','approved','rejected','hold') DEFAULT 'pending',
    comments TEXT,
    decision_date TIMESTAMP,
    tat_due_date TIMESTAMP,
    tat_reminded_at TIMESTAMP,
    tat_escalated_at TIMESTAMP,
    escalated_to_id UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_form_submission_approvals_submission ON form_submission_approvals(submission_id);
CREATE INDEX idx_form_submission_approvals_assignee ON form_submission_approvals(assignee_id);
CREATE INDEX idx_form_submission_approvals_decision ON form_submission_approvals(decision);
CREATE INDEX idx_form_submission_approvals_tat_due ON form_submission_approvals(tat_due_date);
```

#### `approval_attachments`

```sql
CREATE TABLE approval_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    approval_id UUID REFERENCES form_submission_approvals(id) ON DELETE CASCADE,
    original_filename VARCHAR(255) NOT NULL,
    stored_filename VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_approval_attachments_approval ON approval_attachments(approval_id);
```

---

### 12.7 Usage Tracking Tables

#### `tenant_usage_tracking`

```sql
CREATE TABLE tenant_usage_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    usage_date DATE NOT NULL,
    active_users_count INTEGER DEFAULT 0,
    forms_submitted_count INTEGER DEFAULT 0,
    templates_created_count INTEGER DEFAULT 0,
    storage_used_bytes BIGINT DEFAULT 0,
    webhook_calls_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_tenant_usage_tracking_tenant_date ON tenant_usage_tracking(tenant_id, usage_date);
```

#### `webhook_delivery_logs`

```sql
CREATE TABLE webhook_delivery_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    template_id UUID REFERENCES form_templates(id),
    submission_id UUID REFERENCES form_submissions(id),
    webhook_url VARCHAR(500) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    payload JSON NOT NULL,
    http_status_code INTEGER,
    response_body TEXT,
    response_time_ms INTEGER,
    retry_count INTEGER DEFAULT 0,
    delivered_at TIMESTAMP,
    failed_at TIMESTAMP,
    next_retry_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_webhook_delivery_logs_tenant ON webhook_delivery_logs(tenant_id);
CREATE INDEX idx_webhook_delivery_logs_retry ON webhook_delivery_logs(next_retry_at) WHERE next_retry_at IS NOT NULL;
```

---

### 12.8 Audit & Notification Tables

#### `audit_logs`

```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    table_name VARCHAR(100) NOT NULL,
    record_id UUID NOT NULL,
    action ENUM('create','update','delete','login','logout') NOT NULL,
    old_values JSON,
    new_values JSON,
    user_id UUID,
    user_type ENUM('user','super_admin') NOT NULL,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_tenant ON audit_logs(tenant_id);
CREATE INDEX idx_audit_logs_table_record ON audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
```

#### `system_notifications`

```sql
CREATE TABLE system_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    notification_type ENUM('tat_reminder','approval_request','status_update',
                           'rejection','escalation','system_alert') NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_submission_id UUID REFERENCES form_submissions(id),
    is_read BOOLEAN DEFAULT false,
    sent_via_email BOOLEAN DEFAULT false,
    email_sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP
);

CREATE INDEX idx_system_notifications_user ON system_notifications(user_id);
CREATE INDEX idx_system_notifications_unread ON system_notifications(user_id, is_read);
```

---

### 12.9 System Configuration Tables

#### `system_settings`

```sql
CREATE TABLE system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    setting_key VARCHAR(100) NOT NULL,
    setting_value JSON NOT NULL,
    setting_type ENUM('string','integer','boolean','json','email','url') NOT NULL,
    description TEXT,
    is_encrypted BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(id)
);

CREATE UNIQUE INDEX idx_system_settings_tenant_key ON system_settings(tenant_id, setting_key);
```

#### `email_templates`

```sql
CREATE TABLE email_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    template_name VARCHAR(100) NOT NULL,
    template_type ENUM('approval_request','tat_reminder','status_update',
                       'rejection','completion') NOT NULL,
    subject VARCHAR(255) NOT NULL,
    body_html TEXT NOT NULL,
    body_text TEXT,
    variables JSON,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_email_templates_tenant ON email_templates(tenant_id);
CREATE INDEX idx_email_templates_type ON email_templates(template_type);
```

---

### 12.10 Useful Views

#### Active User Count per Tenant

```sql
CREATE VIEW tenant_active_users AS
SELECT
    t.id AS tenant_id,
    t.tenant_id AS tenant_code,
    t.name AS tenant_name,
    COUNT(u.id) AS active_user_count
FROM tenants t
LEFT JOIN users u ON t.id = u.tenant_id AND u.is_active = true
WHERE t.is_active = true
GROUP BY t.id, t.tenant_id, t.name;
```

#### Pending Approvals by User

```sql
CREATE VIEW user_pending_approvals AS
SELECT
    u.id AS user_id,
    u.email,
    u.tenant_id,
    COUNT(fsa.id) AS pending_count,
    COUNT(CASE WHEN fsa.tat_due_date < NOW() THEN 1 END) AS overdue_count,
    MIN(fsa.tat_due_date) AS earliest_due_date
FROM users u
LEFT JOIN form_submission_approvals fsa
    ON u.id = fsa.assignee_id AND fsa.decision = 'pending'
WHERE u.is_active = true
GROUP BY u.id, u.email, u.tenant_id;
```

#### Monthly Usage Summary

```sql
CREATE VIEW tenant_monthly_usage AS
SELECT
    t.id AS tenant_id,
    t.tenant_id AS tenant_code,
    DATE_TRUNC('month', CURRENT_DATE) AS usage_month,
    SUM(tut.forms_submitted_count) AS forms_submitted,
    SUM(tut.webhook_calls_count) AS webhook_calls,
    MAX(tut.storage_used_bytes) AS storage_used_bytes,
    MAX(tut.active_users_count) AS peak_active_users
FROM tenants t
LEFT JOIN tenant_usage_tracking tut
    ON t.id = tut.tenant_id
    AND tut.usage_date >= DATE_TRUNC('month', CURRENT_DATE)
WHERE t.is_active = true
GROUP BY t.id, t.tenant_id;
```

---

### 12.11 Audit Trigger Function

```sql
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (tenant_id, table_name, record_id, action, old_values, user_id, user_type)
        VALUES (COALESCE(OLD.tenant_id, NULL), TG_TABLE_NAME, OLD.id, 'delete', to_json(OLD),
                COALESCE(current_setting('app.current_user_id', true)::UUID, NULL),
                COALESCE(current_setting('app.current_user_type', true), 'user'));
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (tenant_id, table_name, record_id, action, old_values, new_values, user_id, user_type)
        VALUES (COALESCE(NEW.tenant_id, NULL), TG_TABLE_NAME, NEW.id, 'update', to_json(OLD), to_json(NEW),
                COALESCE(current_setting('app.current_user_id', true)::UUID, NULL),
                COALESCE(current_setting('app.current_user_type', true), 'user'));
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (tenant_id, table_name, record_id, action, new_values, user_id, user_type)
        VALUES (COALESCE(NEW.tenant_id, NULL), TG_TABLE_NAME, NEW.id, 'create', to_json(NEW),
                COALESCE(current_setting('app.current_user_id', true)::UUID, NULL),
                COALESCE(current_setting('app.current_user_type', true), 'user'));
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Apply to key tables
CREATE TRIGGER form_submissions_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON form_submissions
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER form_templates_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON form_templates
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER users_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER form_submission_approvals_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON form_submission_approvals
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
```

---

### 12.12 Data Retention Policies

```sql
-- Audit logs: keep 2 years
CREATE OR REPLACE FUNCTION cleanup_old_audit_logs() RETURNS INTEGER AS $$
DECLARE deleted_count INTEGER;
BEGIN
    DELETE FROM audit_logs WHERE created_at < NOW() - INTERVAL '2 years';
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END; $$ LANGUAGE plpgsql;

-- Webhook logs: keep 6 months (successful only)
CREATE OR REPLACE FUNCTION cleanup_old_webhook_logs() RETURNS INTEGER AS $$
DECLARE deleted_count INTEGER;
BEGIN
    DELETE FROM webhook_delivery_logs
    WHERE created_at < NOW() - INTERVAL '6 months'
    AND http_status_code BETWEEN 200 AND 299;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END; $$ LANGUAGE plpgsql;

-- Notifications: keep 1 year (read only)
CREATE OR REPLACE FUNCTION cleanup_old_notifications() RETURNS INTEGER AS $$
DECLARE deleted_count INTEGER;
BEGIN
    DELETE FROM system_notifications
    WHERE created_at < NOW() - INTERVAL '1 year' AND is_read = true;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END; $$ LANGUAGE plpgsql;

-- Suggested cron: run daily at 2 AM
-- 0 2 * * * psql -d approval_workflow -c "SELECT cleanup_old_audit_logs(), cleanup_old_webhook_logs(), cleanup_old_notifications();"
```

---

### 12.13 Performance Indexes

```sql
-- Common query patterns
CREATE INDEX idx_form_submissions_tenant_status_date
    ON form_submissions(tenant_id, status, submitted_at);

CREATE INDEX idx_form_submission_approvals_assignee_decision_date
    ON form_submission_approvals(assignee_id, decision, tat_due_date);

CREATE INDEX idx_users_tenant_active_role
    ON users(tenant_id, is_active, role);

CREATE INDEX idx_form_templates_tenant_status_category
    ON form_templates(tenant_id, status, category) WHERE is_deleted = false;

-- Webhook processing
CREATE INDEX idx_webhook_delivery_logs_next_retry
    ON webhook_delivery_logs(next_retry_at, retry_count)
    WHERE next_retry_at IS NOT NULL;

-- Audit and compliance
CREATE INDEX idx_audit_logs_tenant_table_date
    ON audit_logs(tenant_id, table_name, created_at);

CREATE INDEX idx_tenant_usage_tracking_tenant_month
    ON tenant_usage_tracking(tenant_id, DATE_TRUNC('month', usage_date));
```

---

*Document version: 1.0 — last updated April 2026*
