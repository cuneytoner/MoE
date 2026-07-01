import { useEffect, useMemo, useState } from "react";
import { fetchDashboard, gatewayBaseUrl } from "./api";
import { GatesPanel } from "./components/GatesPanel";
import { LatestImagesPanel } from "./components/LatestImagesPanel";
import { ModeHintsPanel } from "./components/ModeHintsPanel";
import { SafeCommandsPanel } from "./components/SafeCommandsPanel";
import { ServicesPanel } from "./components/ServicesPanel";
import { StatusCard } from "./components/StatusCard";
import type { DashboardModel } from "./types";

export function App() {
  const [dashboard, setDashboard] = useState<DashboardModel | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [lastRefresh, setLastRefresh] = useState<string>("never");

  async function refresh() {
    setLoading(true);
    setError("");
    try {
      const next = await fetchDashboard();
      setDashboard(next);
      setLastRefresh(new Date().toLocaleString());
    } catch (err) {
      setError(err instanceof Error ? err.message : "unknown error");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void refresh();
  }, []);

  const safetyUnsafe = useMemo(() => {
    if (!dashboard) {
      return false;
    }
    return (
      dashboard.safety.read_only !== true ||
      dashboard.safety.starts_services !== false ||
      dashboard.safety.stops_services !== false ||
      dashboard.safety.real_generation_trigger !== false ||
      dashboard.safety.arbitrary_shell !== false
    );
  }, [dashboard]);

  return (
    <main className="app">
      <header className="header">
        <div>
          <p className="eyebrow">AI Brain OS</p>
          <h1>MoE Dashboard</h1>
        </div>
        <div className="header-actions">
          <span className="badge">Read-only MVP</span>
          <span className="refresh-time">Last refresh: {lastRefresh}</span>
          <button type="button" onClick={refresh} disabled={loading}>
            {loading ? "Refreshing" : "Refresh"}
          </button>
        </div>
      </header>

      {error ? (
        <section className="banner danger">
          Gateway unavailable from {gatewayBaseUrl()}: {error}
        </section>
      ) : null}

      <section className={safetyUnsafe ? "banner danger" : "banner safe"}>
        <strong>Safety:</strong>{" "}
        {dashboard
          ? safetyUnsafe
            ? "Unsafe dashboard flags detected. Do not use this UI for operations."
            : "Read-only. No service control, shell execution, suspend, or real generation trigger."
          : "Waiting for Gateway dashboard data."}
      </section>

      <section className="status-grid">
        <StatusCard label="Gateway model" value={dashboard?.status ?? "unknown"} />
        <StatusCard
          label="Real generation"
          value={dashboard?.gates.gateway_real_allowed ? "unlocked" : "locked"}
          tone={dashboard?.gates.gateway_real_allowed ? "warn" : "good"}
        />
        <StatusCard
          label="Latest images"
          value={String(dashboard?.latest_images.length ?? 0)}
        />
        <StatusCard
          label="PC roles"
          value="PC-1 GPU / PC-2 helper"
        />
      </section>

      {dashboard ? (
        <>
          <section className="layout-two">
            <ServicesPanel services={dashboard.services} />
            <GatesPanel gates={dashboard.gates} />
          </section>
          <LatestImagesPanel images={dashboard.latest_images} />
          <section className="layout-two">
            <SafeCommandsPanel commands={dashboard.safe_commands} />
            <ModeHintsPanel hints={dashboard.mode_hints} />
          </section>
          <section className="panel">
            <h2>PC1 / PC2 Roles</h2>
            <div className="role-grid">
              <div>
                <strong>PC-1</strong>
                <p>Main workstation, Gateway, coding model runtime, ComfyUI, Media API, Media Worker, GPU generation host.</p>
              </div>
              <div>
                <strong>PC-2</strong>
                <p>Helper node for Prompt Interpreter, learning, research, feedback, reports, and future background jobs.</p>
              </div>
            </div>
          </section>
          {dashboard.warnings.length ? (
            <section className="panel">
              <h2>Warnings</h2>
              <div className="stack">
                {dashboard.warnings.map((warning) => (
                  <p className="warning" key={warning}>
                    {warning}
                  </p>
                ))}
              </div>
            </section>
          ) : null}
        </>
      ) : null}

      <footer className="footer">M26.8 Dashboard UI MVP. Read-only. No service control.</footer>
    </main>
  );
}
