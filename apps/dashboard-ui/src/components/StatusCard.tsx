type Props = {
  label: string;
  value: string;
  tone?: "default" | "good" | "warn";
};

export function StatusCard({ label, value, tone = "default" }: Props) {
  return (
    <div className={`status-card ${tone}`}>
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}
