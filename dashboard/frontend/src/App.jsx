import React, { useState, useEffect } from 'react';

// ==============================================================================
// Component: App.jsx
// Description: Fixed, unified Inline-Styled Cyber Aesthetic Dashboard Matrix.
//              Houses the integrated native download progress tracker under the
//              correct layout column smoothly.
// ==============================================================================

export default function App() {
  const [clusterStatus, setClusterStatus] = useState({ status: "loading", available_checkpoints: [] });
  // Fixed state defaults to the official 5B model listed explicitly on your screen
  const [downloadRepo, setDownloadRepo] = useState("Kijai/CogVideoX_GGUF");
  const [downloadFile, setDownloadFile] = useState("CogVideoX_5b_I2V_GGUF_Q4_0.safetensors");
  const [contextSize, setContextSize] = useState(131072);
  const [gpuLayers, setGpuLayers] = useState(48);

  useEffect(() => {
    fetchStatus();
    const interval = setInterval(fetchStatus, 5000);
    return () => clearInterval(interval);
  }, []);

  const fetchStatus = async () => {
    try {
      const res = await fetch('http://localhost:8050/api/status');
      const data = await res.json();
      setClusterStatus(data);
    } catch (err) {
      setClusterStatus({ status: "offline", available_checkpoints: [] });
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
    } catch (err) {
      alert("Backend interface connection error.");
    }
  };

  const switchModel = async (modelName) => {
    try {
      await fetch('http://localhost:8050/api/switch', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model_name: modelName, context_size: contextSize, gpu_layers: gpuLayers })
      });
      alert(`Parametric weight swap initiated for: ${modelName}`);
    } catch (err) {
      alert("Backend interface connection error.");
    }
  };

  const styles = {
    wrapper: { backgroundColor: '#020617', color: '#f8fafc', minHeight: '100vh', padding: '32px', fontFamily: 'monospace' },
    header: { borderBottom: '1px solid #164e63', paddingBottom: '20px', marginBottom: '32px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#0f172a', padding: '20px', borderRadius: '12px' },
    title: { color: '#22d3ee', fontSize: '24px', fontWeight: 'bold', margin: 0, letterSpacing: '2px' },
    subtitle: { color: '#64748b', fontSize: '11px', textTransform: 'uppercase', marginTop: '4px', letterSpacing: '1px' },
    badgeHealthy: { backgroundColor: '#064e3b', color: '#34d399', padding: '8px 16px', borderRadius: '8px', fontSize: '12px', fontWeight: 'bold', border: '1px solid #047857' },
    badgeOffline: { backgroundColor: '#4c0519', color: '#f43f5e', padding: '8px 16px', borderRadius: '8px', fontSize: '12px', fontWeight: 'bold', border: '1px solid #be123c' },
    grid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '32px' },
    card: { backgroundColor: '#0f172a', border: '1px solid #1e293b', borderRadius: '12px', padding: '24px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' },
    cardTitle: { color: '#22d3ee', fontSize: '16px', fontWeight: 'bold', marginBottom: '20px', borderBottom: '1px solid #1e293b', paddingBottom: '10px', textTransform: 'uppercase' },
    label: { display: 'block', fontSize: '11px', color: '#94a3b8', marginBottom: '8px', textTransform: 'uppercase', fontWeight: 'bold' },
    input: { width: '100%', backgroundColor: '#020617', border: '1px solid #334155', borderRadius: '6px', padding: '10px', color: '#e2e8f0', fontSize: '12px', marginBottom: '16px', boxSizing: 'border-box' },
    buttonCyan: { width: '100%', backgroundColor: '#06b6d4', color: '#020617', fontWeight: 'bold', padding: '12px', borderRadius: '6px', border: 'none', cursor: 'pointer', textTransform: 'uppercase', fontSize: '12px', letterSpacing: '1px', marginBottom: '12px' },
    buttonEmerald: { backgroundColor: '#064e3b', border: '1px solid #059669', color: '#34d399', padding: '6px 12px', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold', fontSize: '11px', textTransform: 'uppercase' },
    itemRow: { backgroundColor: '#020617', border: '1px solid #1e293b', padding: '12px', borderRadius: '8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' },
    scrollArea: { maxHeight: '240px', overflowY: 'auto' },
    footerNote: { fontSize: '10px', color: '#475569', marginTop: '16px', borderTop: '1px solid #1e293b', paddingTop: '12px' },
    progressContainer: { marginTop: '16px', backgroundColor: '#020617', padding: '12px', borderRadius: '6px', border: '1px solid #164e63' },
    progressMeta: { display: 'flex', justifyContent: 'space-between', fontSize: '10px', color: '#22d3ee', fontWeight: 'bold', marginBottom: '6px' },
    progressBarOuter: { width: '100%', backgroundColor: '#1e293b', height: '6px', borderRadius: '3px', overflow: 'hidden' }
  };

  return (
    <div style={styles.wrapper}>
      
      {/* Upper Monitor Matrix */}
      <div style={styles.header}>
        <div>
          <h1 style={styles.title}>⚡ MoE CLUSTER ORCHESTRATOR</h1>
          <div style={styles.subtitle}>Multi-Node Personal AI OS Operations Control Center</div>
        </div>
        <div style={clusterStatus.status === 'healthy' ? styles.badgeHealthy : styles.badgeOffline}>
          System Status: {clusterStatus.status}
        </div>
      </div>

      {/* Main Cluster Grid */}
      <div style={styles.grid}>
        
        {/* Panel 1: Asset Ingestion Pipe */}
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
            
            {/* CLEAN INTEGRATED PROGRESS BAR SYSTEM */}
            {clusterStatus.download_progress > 0 && clusterStatus.download_progress < 100 && (
              <div style={styles.progressContainer}>
                <div style={styles.progressMeta}>
                  <span>📥 DOWNLOADING ASSET...</span>
                  <span>{clusterStatus.download_progress}%</span>
                </div>
                <div style={styles.progressBarOuter}>
                  <div style={{ width: `${clusterStatus.download_progress}%`, backgroundColor: '#22d3ee', height: '100%', transition: 'width 0.3s ease' }}></div>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Panel 2: Tuning Override Controls */}
        <div style={styles.card}>
          <div style={styles.cardTitle}>⚙️ Parametric Tuning Overrides</div>
          <label style={styles.label}>Context Window Boundary (num_ctx)</label>
          <select style={styles.input} value={contextSize} onChange={(e) => setContextSize(Number(e.target.value))}>
            <option value={8192}>8,192 Tokens (Fast Vibe Code)</option>
            <option value={32768}>32,768 Tokens (Optimized Repo)</option>
            <option value={65536}>65,536 Tokens (Mid Architecture)</option>
            <option value={131072}>131,072 Tokens (Full Split Window)</option>
          </select>
          
          <label style={styles.label}>GPU Layers Allocated (n_gpu_layers)</label>
          <input type="number" style={styles.input} value={gpuLayers} onChange={(e) => setGpuLayers(Number(e.target.value))} />
          <div style={{fontSize: '10px', color: '#475569', fontStyle: 'italic'}}>
            Note: 48 layers for MoE / 28 layers for dense 32B models to lock VRAM safety profiles.
          </div>
        </div>

        {/* Panel 3: Active Cache Index */}
        <div style={styles.card}>
          <div>
            <div style={styles.cardTitle}>💾 Locked Local Weights Cache</div>
            <div style={styles.scrollArea}>
              {clusterStatus.available_checkpoints.length === 0 ? (
                <div style={{textAlign: 'center', padding: '20px', color: '#475569', fontStyle: 'italic', fontSize: '12px'}}>
                  No weight signatures discovered in path.
                </div>
              ) : (
                clusterStatus.available_checkpoints.map((model, idx) => (
                  <div key={idx} style={styles.itemRow}>
                    <span style={{whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: '180px', fontSize: '12px', fontWeight: 'bold'}}>{model}</span>
                    <button onClick={() => switchModel(model)} style={styles.buttonEmerald}>Activate</button>
                  </div>
                ))
              )}
            </div>
          </div>
          <div style={styles.footerNote}>
            Path Matrix: /home/cuneyt/MoE/models/checkpoints/
          </div>
        </div>

      </div>
    </div>
  );
}
