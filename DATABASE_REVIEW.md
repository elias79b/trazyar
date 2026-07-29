# Database Review

## Scope

This review compares the current initial schema design against the requested Multi-Tenant SaaS ERP architecture.

At review time, `migration.sql` was not present in the workspace. This review is based on the schema previously prepared in this thread with these tables:

- `users`
- `companies`
- `company_users`
- `plans`
- `subscriptions`
- `audit_logs`

No SQL is included in this document.

## 1. What Is Good In The Current Schema

- The schema uses UUID primary keys, which is appropriate for Supabase and multi-tenant SaaS systems.
- The `users` table is linked to Supabase Auth through `auth.users`, which is a good foundation for Supabase-based authentication.
- All core tables include `created_at` and `updated_at`, which supports auditing, synchronization, and operational debugging.
- Foreign keys are present between the main tenant, membership, subscription, and audit tables.
- `company_users` correctly models many-to-many membership between users and companies.
- `company_users` has a uniqueness constraint for each company and user pair, preventing duplicate memberships.
- `subscriptions` is tied to both `companies` and `plans`, which gives a clean tenant billing model.
- `audit_logs` includes company, actor, entity, old value, and new value fields, which is a good base for ERP auditability.
- RLS is enabled on the tables, which prepares the schema for Supabase security policies later.
- Indexes exist on important foreign keys and audit lookup fields.
- The `updated_at` trigger function provides a consistent timestamp update pattern.

## 2. What Is Missing

- `roles` is missing.
  The current schema stores role as plain text in `company_users`. That is too limited for an ERP because roles need to be managed, localized, extended, and scoped per company or system.

- `permissions` is missing.
  ERP modules need granular permissions such as viewing invoices, approving documents, managing users, closing periods, or viewing audit logs.

- `role_permissions` is missing.
  Without this table, there is no normalized way to assign permissions to roles.

- `consultant_profiles` is missing.
  The project has consultant-facing features, but the database has no dedicated profile for consultant metadata, verification, specialty, availability, or relationship to companies.

- `notifications` is missing.
  SaaS ERP needs tenant-scoped notifications for workflow events, approvals, tasks, billing, invitations, and system messages.

- `tasks` is missing.
  ERP workflows usually need assignable, trackable work items connected to companies, users, financial periods, documents, or modules.

- `financial_periods` is missing.
  This is critical for an ERP. Accounting and reporting workflows need company-scoped fiscal periods with open, closed, and locked states.

- There is no explicit tenant ownership model beyond `company_users`.
  A company owner can be inferred from a role value, but ownership should be modeled through normalized roles or explicit ownership metadata.

- There is no invitation or pending membership model.
  `company_users` only represents active user membership. SaaS onboarding often needs invited, pending, accepted, suspended, and removed states.

- There is no permission-ready module structure.
  Permissions will need stable keys grouped by ERP module, but the current schema has no way to represent that.

- There is no clear status lifecycle for companies.
  `is_active` is useful, but ERP tenants usually need states such as active, suspended, archived, or pending setup.

- There is no financial-period relationship in `audit_logs`, `tasks`, or future transaction tables.
  That will become important once accounting modules are added.

## 3. What Should Be Changed

- Replace the text-based `company_users.role` design with a normalized role model.
  `company_users` should reference a role table instead of storing a free role string. This makes RLS and permission checks cleaner later.

- Add a permission model before writing RLS policies.
  RLS policies should eventually depend on stable role and permission data, so the authorization tables should exist before policy design starts.

- Decide whether roles are global, company-scoped, or both.
  A SaaS ERP usually needs system roles for platform-level behavior and company roles for tenant-level access.

- Add `company_id` to operational tables that are tenant-owned.
  Tables such as notifications, tasks, consultant relationships, and financial periods should be tenant-scoped where appropriate.

- Strengthen subscription modeling.
  The current `subscriptions` table is a good start, but it should eventually support one active subscription per company, billing provider references, lifecycle transitions, and historical records.

- Reconsider `audit_logs.updated_at`.
  Audit logs are usually append-only. Keeping `created_at` is essential, but `updated_at` may be unnecessary unless audit log enrichment is planned.

- Add immutable or restricted behavior expectations for audit logs.
  Even before RLS policies are written, the design should assume audit records are append-only and not user-editable.

- Add status fields instead of only boolean flags where workflows need lifecycle states.
  `is_active` is simple, but ERP entities often need more descriptive states.

- Add financial-period constraints during the next schema pass.
  Each company should have non-overlapping financial periods, clear period dates, and a lifecycle state.

- Prepare notification and task tables for both user-level and company-level visibility.
  Some records should target one user, while others should target all users with a role or permission inside a company.

## 4. Which Tables Should Be Recreated

- `company_users`
  This table should be redesigned before approval because its role field is currently text-based. It should connect users, companies, membership status, and normalized roles in a way that supports RLS.

- `subscriptions`
  This table should be reviewed and likely recreated before approval if billing lifecycle accuracy is required from day one. It needs stronger rules around active subscriptions, provider identity, and subscription history.

- `audit_logs`
  This table can be kept conceptually, but should likely be recreated if the team wants strict append-only audit behavior, actor metadata consistency, and tenant/module references from the beginning.

- `users`
  This table may need recreation only if the team wants to separate Auth identity, public profile, and application profile more strictly. The current link to `auth.users` is good, but the table name may become confusing because Supabase already has `auth.users`.

## 5. Which Tables Can Stay Unchanged

- `companies`
  This table can mostly stay as the tenant root. It may need additional lifecycle fields later, but the current base structure is acceptable.

- `plans`
  This table can stay as the commercial plan catalog. It may need feature limits or entitlements later, but it is acceptable as an initial billing foundation.

- `users`
  If the team accepts this table as an application profile table linked one-to-one with Supabase Auth, it can stay mostly unchanged.

- `audit_logs`
  If append-only behavior and stricter audit design are deferred to a later migration, the current table can stay as an initial audit foundation.

## Approval Recommendation

Do not approve the schema as final yet.

The schema is a good first foundation, but the missing authorization, consultant, workflow, notification, and financial-period entities are important enough that the next migration design should be reviewed before any RLS policies are written.
