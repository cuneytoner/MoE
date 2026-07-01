import { useEffect, useMemo, useState } from "react";

type ServiceStatus = {
  status: string;
  service: string;
  url: string;
  reachable?: boolean;
  http_status?: number;
  detail?: string;
};

type ImageInfo = {
  path: string;
  name: string;
  modified: string;
  size_bytes: number;
};

type Dashboard = {
  status: string;
  service: string;
  safety: Record<string, boolean>;
  services: Record<string, ServiceStatus>;
  gates: Record<string, boolean>;
  latest_images: ImageInfo[];
  mode_hints: Record<string, string>;
  safe_commands: Record<string, string[]>;
  warnings: string[];
};

const endpoint = "http://127.0.0.1:8100/gateway/media/dashboard";

export function App() {
  const [dashboard, setDashboard] = useState<Dashboard | null>(null);
  const [error, setError] = useState<string>("");
  const [loading, setLoading] = useState(false);

  async function refresh() {
    setLoading(true);
    setError("");
    try {
      const response = await fetch(endpoint);
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      setDashboard(await response.json());
    } catch (err) {
      setError(err instanceof Error ? err.message : "unknown error");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void refresh();
  }, []);

  const services = useMemo(
    () => Object.entries(dashboard?.services ?? {}),
    [dashboard],
  );
  const gates = useMemo(() => Object.entries(dashboard?.gates ?? {}), [dashboard]);

  return (
    <main className="shell">
      <header className="topbar">
        <div>
          <p className="eyebrow">MoE Media Lab</p>
          <h1>Media Dashboard</h1>
        </div>
        <button type="button" onClick={refresh} disabled={loading}>
          {loading ? "Refreshing" : "Refresh"}
        </button>
      </header>

      {error ? <p className="alert">Gateway dashboard unavailable: {error}</p> : null}

      <section className="summary">
        <div>
          <span className="label">Status</span>
          <strong>{dashboard?.status ?? "unknown"}</strong>
        </div>
        <div>
          <span className="label">Read Only</span>
          <strong>{dashboard?.safety?.read_only ? "true" : "false"}</strong>
        </div>
        <div>
          <span className="label">Real Trigger</span>
          <strong>{dashboard?.safety?.real_generation_trigger ? "true" : "false"}</strong>
        </div>
      </section>

      <section className="grid">
        <div className="panel">
          <h2>Services</h2>
          <div className="rows">
            {services.map(([key, service]) => (
              <div className="row" key={key}>
                <div>
                  <strong>{service.service}</strong>
                  <span>{service.url}</span>
                </div>
                <code className={service.reachable === false ? "bad" : "good"}>
                  {service.status}
                </code>
              </div>
            ))}
          </div>
        </div>

        <div className="panel">
          <h2>Gates</h2>
          <div className="rows">
            {gates.map(([key, value]) => (
              <div className="row" key={key}>
                <strong>{key}</strong>
                <code className={value ? "good" : "muted"}>{String(value)}</code>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="panel full">
        <h2>Latest Images</h2>
        <div className="rows">
          {(dashboard?.latest_images ?? []).map((image) => (
            <div className="row" key={image.path}>
              <div>
                <strong>{image.name}</strong>
                <span>{image.path}</span>
              </div>
              <code>{formatBytes(image.size_bytes)}</code>
            </div>
          ))}
          {dashboard && dashboard.latest_images.length === 0 ? (
            <p className="empty">No runtime image outputs found.</p>
          ) : null}
        </div>
      </section>

      <section className="grid">
        <div className="panel">
          <h2>Mode Hints</h2>
          <div className="rows">
            {Object.entries(dashboard?.mode_hints ?? {}).map(([mode, hint]) => (
              <div className="stacked" key={mode}>
                <strong>{mode}</strong>
                <span>{hint}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="panel">
          <h2>Safe Commands</h2>
          <div className="rows">
            {Object.entries(dashboard?.safe_commands ?? {}).map(([group, commands]) => (
              <div className="stacked" key={group}>
                <strong>{group}</strong>
                {commands.map((command) => (
                  <code key={command}>{command}</code>
                ))}
              </div>
            ))}
          </div>
        </div>
      </section>

      {dashboard?.warnings?.length ? (
        <section className="panel full">
          <h2>Warnings</h2>
          <div className="rows">
            {dashboard.warnings.map((warning) => (
              <p className="warning" key={warning}>
                {warning}
              </p>
            ))}
          </div>
        </section>
      ) : null}
    </main>
  );
}

function formatBytes(value: number) {
  if (value < 1024) {
    return `${value} B`;
  }
  if (value < 1024 * 1024) {
    return `${(value / 1024).toFixed(1)} KB`;
  }
  return `${(value / 1024 / 1024).toFixed(1)} MB`;
}
