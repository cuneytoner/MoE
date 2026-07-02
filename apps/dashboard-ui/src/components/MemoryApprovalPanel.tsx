import FactCheckOutlinedIcon from "@mui/icons-material/FactCheckOutlined";
import { Alert, Box, Card, CardContent, CardHeader, Chip, Stack, Table, TableBody, TableCell, TableHead, TableRow, Typography } from "@mui/material";
import type { MemoryApprovalDashboardModel } from "../types";
import { StatusChip } from "./StatusChip";

type Props = {
  memoryApproval: MemoryApprovalDashboardModel | null;
  error: string;
};

export function MemoryApprovalPanel({ memoryApproval, error }: Props) {
  if (error) {
    return (
      <Alert id="memory-approval" severity="warning" variant="outlined">
        Memory Approval dashboard unavailable: {error}
      </Alert>
    );
  }

  if (!memoryApproval) {
    return (
      <Card id="memory-approval">
        <CardHeader avatar={<FactCheckOutlinedIcon color="primary" />} title="Memory Approval" />
        <CardContent>
          <Typography color="text.secondary" variant="body2">
            Waiting for read-only memory approval report data.
          </Typography>
        </CardContent>
      </Card>
    );
  }

  const safe =
    memoryApproval.read_only === true &&
    memoryApproval.apply_supported === false &&
    memoryApproval.approval_supported === false &&
    memoryApproval.memory_write_supported === false;

  return (
    <Stack id="memory-approval" spacing={2}>
      <Stack direction={{ xs: "column", sm: "row" }} justifyContent="space-between" spacing={1}>
        <Typography variant="h6">Memory Approval</Typography>
        <Stack direction="row" flexWrap="wrap" gap={1}>
          <StatusChip label="read-only" tone={safe ? "ok" : "error"} />
          <StatusChip label="no writes" tone={memoryApproval.memory_write_supported ? "error" : "ok"} />
          <StatusChip label="human review" tone={memoryApproval.human_review_required ? "warning" : "error"} />
        </Stack>
      </Stack>

      <Box sx={{ display: "grid", gap: 2, gridTemplateColumns: { xs: "1fr", md: "repeat(4, minmax(0, 1fr))" } }}>
        <MetricCard label="Candidates" value={memoryApproval.summary.total_candidates} />
        <MetricCard label="Approved / Blocked" value={`${memoryApproval.summary.approved_count} / ${memoryApproval.summary.blocked_count}`} />
        <MetricCard label="Duplicate Groups" value={memoryApproval.summary.duplicate_group_count} />
        <MetricCard label="Dry-Run Attempts" value={memoryApproval.summary.dry_run_attempt_count} />
        <MetricCard label="Stored / Failed" value={`${memoryApproval.summary.stored_count} / ${memoryApproval.summary.failed_count}`} />
        <MetricCard label="Skipped" value={memoryApproval.summary.skipped_count} />
        <MetricCard label="E2E Status" value={memoryApproval.e2e.e2e_status || "unknown"} />
        <MetricCard label="Approval File" value={memoryApproval.approval.real_approval_file_exists ? "present" : "absent"} />
      </Box>

      <Box sx={{ display: "grid", gap: 2, gridTemplateColumns: { xs: "1fr", xl: "1.1fr 0.9fr" } }}>
        <Card>
          <CardHeader title="Candidate Review" />
          <CardContent sx={{ overflowX: "auto" }}>
            {memoryApproval.candidates.length ? (
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>ID</TableCell>
                    <TableCell>Category</TableCell>
                    <TableCell>Risk</TableCell>
                    <TableCell>Status</TableCell>
                    <TableCell>Duplicate</TableCell>
                    <TableCell>Title</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {memoryApproval.candidates.map((candidate) => (
                    <TableRow key={candidate.id}>
                      <TableCell>{candidate.id}</TableCell>
                      <TableCell>{candidate.category}</TableCell>
                      <TableCell>
                        <Chip label={candidate.risk || "unknown"} size="small" variant="outlined" />
                      </TableCell>
                      <TableCell>{candidate.current_status || "unknown"}</TableCell>
                      <TableCell>{candidate.duplicate_group_id || "no"}</TableCell>
                      <TableCell>
                        <Stack spacing={0.5}>
                          <Typography fontWeight={700} variant="body2">
                            {candidate.title}
                          </Typography>
                          <Typography color="text.secondary" variant="caption">
                            {candidate.review_hint}
                          </Typography>
                        </Stack>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <Typography color="text.secondary" variant="body2">
                No memory approval candidates are available.
              </Typography>
            )}
          </CardContent>
        </Card>

        <Stack spacing={2}>
          <Card>
            <CardHeader title="Apply Log" />
            <CardContent>
              <Stack spacing={1}>
                <SmallLine label="Log" value={memoryApproval.apply_log.log_exists ? "present" : "missing"} />
                <SmallLine label="Summary" value={memoryApproval.apply_log.summary_exists ? "present" : "missing"} />
                <SmallLine label="Stored / Failed / Skipped" value={`${memoryApproval.apply_log.stored_count} / ${memoryApproval.apply_log.failed_count} / ${memoryApproval.apply_log.skipped_count}`} />
                <SmallLine label="Latest Attempt" value={formatDate(memoryApproval.apply_log.latest_attempt_at)} />
              </Stack>
            </CardContent>
          </Card>

          <Card>
            <CardHeader title="Duplicate Groups" />
            <CardContent>
              <Stack spacing={1.5}>
                {memoryApproval.duplicates.length ? (
                  memoryApproval.duplicates.slice(0, 6).map((group) => (
                    <Box key={group.group_id} sx={{ borderBottom: "1px solid", borderColor: "divider", pb: 1 }}>
                      <Typography fontWeight={800} variant="body2">
                        {group.group_id || "duplicate group"} · {group.count}
                      </Typography>
                      <Typography color="text.secondary" variant="caption">
                        {group.category} · {group.recommended_action}
                      </Typography>
                      <Typography color="text.secondary" display="block" variant="caption">
                        {group.candidate_ids.join(", ")}
                      </Typography>
                    </Box>
                  ))
                ) : (
                  <Typography color="text.secondary" variant="body2">
                    No duplicate groups reported.
                  </Typography>
                )}
              </Stack>
            </CardContent>
          </Card>
        </Stack>
      </Box>

      {memoryApproval.warnings.length ? (
        <Alert severity="warning" variant="outlined">
          <Stack spacing={0.5}>
            {memoryApproval.warnings.map((warning) => (
              <Typography key={warning} variant="body2">
                {warning}
              </Typography>
            ))}
          </Stack>
        </Alert>
      ) : null}
    </Stack>
  );
}

function MetricCard({ label, value }: { label: string; value: number | string }) {
  return (
    <Card>
      <CardContent>
        <Typography color="text.secondary" fontSize={12} fontWeight={800} textTransform="uppercase">
          {label}
        </Typography>
        <Typography sx={{ mt: 0.75, overflowWrap: "anywhere" }} variant="h6">
          {value}
        </Typography>
      </CardContent>
    </Card>
  );
}

function SmallLine({ label, value }: { label: string; value: string }) {
  return (
    <Stack direction="row" justifyContent="space-between" spacing={2}>
      <Typography color="text.secondary" variant="body2">
        {label}
      </Typography>
      <Typography fontWeight={800} textAlign="right" variant="body2">
        {value}
      </Typography>
    </Stack>
  );
}

function formatDate(value?: string | null) {
  if (!value) {
    return "none";
  }
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? value : date.toLocaleString();
}
