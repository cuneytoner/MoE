import React, { useState, useEffect } from 'react';

export default function App() {
  const [clusterStatus, setClusterStatus] = useState({ 
    status: "loading", 
    available_checkpoints: [], 
    download_progress: 0,
    pc1_telemetry: { cpu: 0, ram: 0, gpu: 0, vram: 0 },
    pc2_telemetry: { cpu: 0, ram: 0, gpu: 0, vram: 0 }
  });
  // Fixed state defaults to the absolute raw binary repository source on HuggingFace
  const [downloadRepo, setDownloadRepo] = useState("comfyanonymous/flux_text_encoders");
  const [downloadFile, setDownloadFile] = useState("t5xxl_fp8_e4m3fn.safetensors");

  const [contextSize, setContextSize] = useState(131072);
  const [gpuLayers, setGpuLayers] = useState(48);

  useEffect(() => {
    fetchStatus();
    const interval = setInterval(fetchStatus, 2000); // 2 seconds high-performance poll
    return () => clearInterval(interval);
  }, []);

  const fetchStatus = async () => {
    try {
      const res = await fetch(`http://localhost:8050/api/status?t=${new Date().getTime()}`);
      const data = await res.json();
      setClusterStatus(data);
    } catch (err) {
      setClusterStatus(prev => ({ ...prev, status: "offline" }));
    }
  };

  const triggerDownload = async () => {
    try {
      await fetch('http://localhost:8050/api/download', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ repo_id: downloadRepo, filename: downloadFile })
      });
      alert(`Asset retrieval queued for: ${downloadFile}`);
    } catch (err) { alert("Backend interface connection error."); }
  };

  const switchModel = async (modelName) => {
    try {
      await fetch('http://localhost:8050/api/switch', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model_name: modelName, context_size: contextSize, gpu_layers: gpuLayers })
      });
      alert(`Parametric weight swap initiated for: ${modelName}`);
    } catch (err) { alert("Backend interface connection error."); }
  };

  const styles = {
    wrapper: { backgroundColor: '#020617', color: '#f8fafc', minHeight: '100vh', padding: '32px', fontFamily: 'monospace' },
    header: { borderBottom: '1px solid #164e63', paddingBottom: '20px', marginBottom: '32px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#0f172a', padding: '20px', borderRadius: '12px', border: '1px solid #1e293b' },
    title: { color: '#22d3ee', fontSize: '24px', fontWeight: 'bold', margin: 0, letterSpacing: '2px' },
    subtitle: { color: '#64748b', fontSize: '11px', textTransform: 'uppercase', marginTop: '4px', letterSpacing: '1px' },
    badgeHealthy: { backgroundColor: '#064e3b', color: '#34d399', padding: '8px 16px', borderRadius: '8px', fontSize: '12px', fontWeight: 'bold', border: '1px solid #047857' },
    badgeOffline: { backgroundColor: '#4c0519', color: '#f43f5e', padding: '8px 16px', borderRadius: '8px', fontSize: '12px', fontWeight: 'bold', border: '1px solid #be123c' },
    grid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '32px' },
    card: { backgroundColor: '#0f172a', border: '1px solid #1e293b', borderRadius: '12px', padding: '24px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' },
    cardTitle: { color: '#22d3ee', fontSize: '16px', fontWeight: 'bold', marginBottom: '20px', borderBottom: '1px solid #1e293b', paddingBottom: '10px', textTransform: 'uppercase' },
    label: { display: 'block', fontSize: '11px', color: '#94a3b8', marginBottom: '6px', textTransform: 'uppercase', fontWeight: 'bold' },
    input: { width: '100%', backgroundColor: '#020617', border: '1px solid #334155', borderRadius: '6px', padding: '10px', color: '#e2e8f0', fontSize: '12px', marginBottom: '16px', boxSizing: 'border-box' },
    buttonCyan: { width: '100%', backgroundColor: '#06b6d4', color: '#020617', fontWeight: 'bold', padding: '12px', borderRadius: '6px', border: 'none', cursor: 'pointer', textTransform: 'uppercase', fontSize: '12px', letterSpacing: '1px', marginBottom: '12px' },
    buttonEmerald: { backgroundColor: '#064e3b', border: '1px solid #059669', color: '#34d399', padding: '6px 12px', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold', fontSize: '11px', textTransform: 'uppercase' },
    itemRow: { backgroundColor: '#020617', border: '1px solid #1e293b', padding: '12px', borderRadius: '8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' },
    scrollArea: { maxHeight: '240px', overflowY: 'auto' },
    footerNote: { fontSize: '10px', color: '#475569', marginTop: '16px', borderTop: '1px solid #1e293b', paddingTop: '12px' },
    tRow: { marginBottom: '12px' },
    tBarOuter: { width: '100%', backgroundColor: '#020617', height: '8px', borderRadius: '4px', overflow: 'hidden', border: '1px solid #334155', marginTop: '4px' },
    tLabelGroup: { display: 'flex', justifyContent: 'space-between', fontSize: '11px', fontWeight: 'bold' }
  };

  const renderTelemetryBlock = (nodeName, telemetry, barColor) => (
    <div style={{ backgroundColor: '#020617', border: '1px solid #1e293b', padding: '14px', borderRadius: '8px', marginBottom: '16px' }}>
      <div style={{ color: '#f8fafc', fontSize: '12px', fontWeight: 'bold', marginBottom: '10px', display: 'flex', alignItems: 'center', gap: '6px' }}>
        <span style={{ color: barColor }}>●</span> {nodeName} CLUSTER STATE
      </div>
      {[['CPU UTIL', telemetry.cpu], ['RAM UTIL', telemetry.ram], ['GPU CORE', telemetry.gpu], ['VRAM LOCK', telemetry.vram]].map(([lbl, val]) => (
        <div key={lbl} style={styles.tRow}>
          <div style={styles.tLabelGroup}>
            <span style={{ color: '#64748b' }}>{lbl}</span>
            <span style={{ color: barColor }}>{val || 0}%</span>
          </div>
          <div style={styles.tBarOuter}>
            <div style={{ width: `${val || 0}%`, backgroundColor: barColor, height: '100%', transition: 'width 0.5s ease' }}></div>
          </div>
        </div>
      ))}
    </div>
  );

  return (
    <div style={styles.wrapper}>
      {/* Header */}
      <div style={styles.header}>
        <div>
          <h1 style={styles.title}>⚡ MoE CLUSTER ORCHESTRATOR</h1>
          <div style={styles.subtitle}>Multi-Node Personal AI OS Operations Control Center</div>
        </div>
        <div style={clusterStatus.status === 'healthy' ? styles.badgeHealthy : styles.badgeOffline}>
          System Status: {clusterStatus.status}
        </div>
      </div>

      {/* Grid */}
      <div style={styles.grid}>
        {/* Panel 1 */}
        <div style={styles.card}>
          <div>
            <div style={styles.cardTitle}>📥 Dynamic Asset Ingestion</div>
            <label style={styles.label}>Hugging Face Repository ID</label>
            <input type="text" style={styles.input} value={downloadRepo} onChange={(e) => setDownloadRepo(e.target.value)} />
            <label style={styles.label}>Target Filename (.gguf / .safetensors)</label>
            <input type="text" style={styles.input} value={downloadFile} onChange={(e) => setDownloadFile(e.target.value)} />
          </div>
          <div>
            <button onClick={triggerDownload} style={styles.buttonCyan}>Inject Asset Pipeline</button>
            {clusterStatus.download_progress > 0 && clusterStatus.download_progress < 100 && (
              <div style={{ marginTop: '12px', backgroundColor: '#020617', padding: '12px', borderRadius: '6px', border: '1px solid #164e63' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '10px', color: '#22d3ee', fontWeight: 'bold', marginBottom: '6px' }}>
                  <span>📥 STREAMING BINARY...</span>
                  <span>{clusterStatus.download_progress}%</span>
                </div>
                <div style={{ width: '100%', backgroundColor: '#1e293b', height: '6px', borderRadius: '3px', overflow: 'hidden' }}>
                  <div style={{ width: `${clusterStatus.download_progress}%`, backgroundColor: '#22d3ee', height: '100%' }}></div>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Panel 2: Live Telemetry Matrix Override */}
        <div style={styles.card}>
          <div>
            <div style={styles.cardTitle}>📊 Real-Time Telemetry Matrix</div>
            {renderTelemetryBlock("PC-1 (PRIMARY)", clusterStatus.pc1_telemetry || {cpu:0,ram:0,gpu:0,vram:0}, "#22d3ee")}
            {renderTelemetryBlock("PC-2 (WORKER)", clusterStatus.pc2_telemetry || {cpu:0,ram:0,gpu:0,vram:0}, "#a855f7")}
          </div>
        </div>

        {/* Panel 3 */}
        <div style={styles.card}>
          <div>
            <div style={styles.cardTitle}>💾 Locked Local Weights Cache</div>
            <div style={styles.scrollArea}>
              {clusterStatus.available_checkpoints.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '20px', color: '#475569', fontStyle: 'italic' }}>No weight signatures discovered.</div>
              ) : (
                clusterStatus.available_checkpoints.map((model, idx) => (
                  <div key={idx} style={styles.itemRow}>
                    <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: '180px', fontSize: '12px', fontWeight: 'bold' }}>{model}</span>
                    <button onClick={() => switchModel(model)} style={styles.buttonEmerald}>Activate</button>
                  </div>
                ))
              )}
            </div>
          </div>
          <div style={styles.footerNote}>Path Matrix: /home/cuneyt/MoE/models/checkpoints/</div>
        </div>
      </div>
    </div>
  );
}
