type Props = {
  gates: Record<string, boolean>;
};

export function GatesPanel({ gates }: Props) {
  const realUnlocked = gates.gateway_real_allowed && gates.media_real_generation_enabled;
  const dryRunAvailable = gates.gateway_media_enabled;

  return (
    <section className="panel">
      <h2>Generation Gates</h2>
      <div className="summary-lines">
        <p><strong>Real generation:</strong> {realUnlocked ? "unlocked" : "locked"}</p>
        <p><strong>Media dry-run:</strong> {dryRunAvailable ? "available" : "unavailable"}</p>
        <p><strong>ComfyUI bridge:</strong> {gates.comfyui_external_bridge_required_for_docker ? "required for Docker" : "not required"}</p>
      </div>
      <div className="rows">
        {Object.entries(gates).map(([name, value]) => (
          <div className="row" key={name}>
            <span>{name}</span>
            <code className={value ? "good" : "muted"}>{String(value)}</code>
          </div>
        ))}
      </div>
    </section>
  );
}
