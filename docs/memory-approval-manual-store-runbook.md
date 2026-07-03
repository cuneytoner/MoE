# Memory Approval Manual Store Runbook

## Purpose
This runbook outlines the process for manually storing approved candidates in the memory system. Real memory writes are optional and manual. Tests never run APPLY=1.

## Safety Boundaries# Memory Approval Manual Store Runbook

## Purpose
This runbook outlines the process for manually storing approved candidates in the memory system. Real memory writes are optional and manual. Tests never run APPLY=1.

## Safety Boundaries
- Only sanitized approved candidates may be stored.
- Raw prompts and raw model responses must not be stored.
- Duplicate candidates should be merged or rejected before approval.
- Dashboard is read-only.
- Runtime reports must not be committed.
- Memory writes are not automatically reversible.

## Preconditions
- Ensure the candidate is sanitized and approved.
- Verify that duplicate candidates are handled appropriately.
- Confirm that the dashboard is read-only.

## Candidate Review Steps
1. Review the candidate for accuracy and relevance.
2. Ensure the candidate does not contain raw prompts or raw model responses.
3. Check for any potential duplicates and handle them by merging or rejecting.

## Duplicate Review Steps
1. Identify any duplicate candidates.
2. Merge the duplicate candidates if appropriate.
3. Reject duplicate candidates if they are not needed.

## Approval File Creation Steps
1. Create an approval file for the candidate.
2. Ensure the approval file contains all necessary information.

## Dry-run Steps
1. Perform a dry-run of the memory store process to verify the steps.
2. Ensure that the dry-run does not affect the actual memory system.

## Dashboard Verification Steps
1. Verify that the dashboard reflects the candidate correctly.
2. Ensure that the dashboard is read-only.

## Final APPLY=1 Preflight Checklist
- Verify that the candidate is sanitized and approved.
- Ensure that the approval file is correctly created.
- Confirm that all necessary steps have been completed.

## Actual APPLY=1 Command
```bash
# Manual command to apply the candidate
# This command should be run manually after verifying all preconditions
APPLY=1 make memory-store-approved
```

## Post-Apply Verification Steps
1. Verify that the candidate has been successfully stored in the memory system.
2. Ensure that the dashboard reflects the changes correctly.

## Apply Log Verification
1. Check the apply log to ensure that the operation was successful.
2. Look for any errors or warnings in the log.

## What Not to Do
- Do not run APPLY=1 during tests.
- Do not store raw prompts or raw model responses.
- Do not commit runtime reports.
- Do not perform memory writes automatically.

## Troubleshooting
- If the candidate is not stored correctly, review the approval file and ensure all steps have been followed.
- If there are errors in the apply log, investigate and resolve the issues.

## Rollback Limitations
- Memory writes are not automatically reversible.
- Manual rollback procedures may be required in case of errors.

## Exact Commands
- `make memory-candidate-approval-helper-local`
- `make memory-candidate-list-local`
- `make memory-store-audit-local`
- `make memory-store-plan-local`
- `make memory-store-approved`
- `LOG_DRY_RUN=1 make memory-store-approved`
- `make memory-store-apply-log-status`
- `make memory-approval-dry-run-e2e-local`
- `USE_TEST_APPROVAL_FIXTURE=1 make memory-approval-dry-run-e2e-local`
- `curl -s http://localhost:8100/gateway/memory-approval/dashboard | jq`

## Real Project Paths
- Candidates: `/home/cuneyt/MoE/runtime/reports/memory-candidates/feedback-memory-candidates.json`
- Helper report: `/home/cuneyt/MoE/runtime/reports/memory-store/memory-candidate-approval-helper-report.json`
- Example approval file: `/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.example.json`
- Real approval file: `/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json`
- Store plan: `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-plan.json`
- Audit: `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-audit.json`
- Apply log: `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-log.jsonl`
- Apply summary: `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-summary.json`
- E2E dry-run report: `/home/cuneyt/MoE/runtime/reports/memory-store/memory-approval-dry-run-e2e-report.json`
- Dashboard endpoint: `GET /gateway/memory-approval/dashboard`
```
- Only sanitized approved candidates may be stored.
- Raw prompts and raw model responses must not be stored.
- Duplicate candidates should be merged or rejected before approval.
- Dashboard is read-only.
- Runtime reports must not be committed.
- Memory writes are not automatically reversible.

## Preconditions
- Ensure the candidate is sanitized and approved.
- Verify that duplicate candidates are handled appropriately.
- Confirm that the dashboard is read-only.

## Candidate Review Steps
1. Review the candidate for accuracy and relevance.
2. Ensure the candidate does not contain raw prompts or raw model responses.
3. Check for any potential duplicates and handle them by merging or rejecting.

## Duplicate Review Steps
1. Identify any duplicate candidates.
2. Merge the duplicate candidates if appropriate.
3. Reject duplicate candidates if they are not needed.

## Approval File Creation Steps
1. Create an approval file for the candidate.
2. Ensure the approval file contains all necessary information.

## Dry-run Steps
1. Perform a dry-run of the memory store process to verify the steps.
2. Ensure that the dry-run does not affect the actual memory system.

## Dashboard Verification Steps
1. Verify that the dashboard reflects the candidate correctly.
2. Ensure that the dashboard is read-only.

## Final APPLY=1 Preflight Checklist
- Verify that the candidate is sanitized and approved.
- Ensure that the approval file is correctly created.
- Confirm that all necessary steps have been completed.

## Actual APPLY=1 Command
