import React, { useState, useEffect } from 'react';

// ==============================================================================
// Component: App.jsx
// Description: Siber-aesthetic management dashboard for local AI clusters.
//              Controls parametric models, download triggers, and telemetry hooks.
// ==============================================================================

export default function App() {
  const [clusterStatus, setClusterStatus] = useState({ status: "loading", available_checkpoints: [] });
  const [downloadRepo, setDownloadRepo] = useState("Qwen/Qwen2.5-Coder-32B-Instruct-GGUF");
  const [downloadFile, setDownloadFile] = useState("qwen2.5-coder-32b-instruct-q4_k_m.gguf");
  const [contextSize, setContextSize] = useState(131072);
  const [gpuLayers, setGpuLayers] = useState(48);

  const fetchStatus = async () => {
    try {
      const res = await fetch('http://localhost:8050/api/status');
      const data = await res.json();
      setClusterStatus(data);
    } catch (err) {
      setClusterStatus({ status: "offline", available_checkpoints: [] });
    }
  };

  useEffect(() => { fetchStatus(); const interval = setInterval(fetchStatus, 5000); return () => clearInterval(interval); }, []);

  const triggerDownload = async () => {
    await fetch('http://localhost:8050/api/download', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ repo_id: downloadRepo, filename: downloadFile })
    });
    alert(`Asset retrieval queued for: ${downloadFile}`);
  };

  const switchModel = async (modelName) => {
    await fetch('http://localhost:8050/api/switch', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ model_name: modelName, context_size: contextSize, gpu_layers: gpuLayers })
    });
    alert(`Parametric weight swap initiated for: ${modelName}`);
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 p-8 font-mono">
      {/* Header Matrix */}
      <div className="border-b border-slate-800 pb-4 mb-8 flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold tracking-wider text-cyan-400">⚡ MoE CLUSTER ORCHESTRATOR</h1>
          <p className="text-xs text-slate-400">Multi-Node Personal AI OS Tier Layer</p>
        </div>
        <div className={`px-3 py-1 rounded text-xs uppercase font-bold ${clusterStatus.status === 'healthy' ? 'bg-emerald-950 text-emerald-400 border border-emerald-800' : 'bg-rose-950 text-rose-400 border border-rose-800'}`}>
          System Cluster: {clusterStatus.status}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Panel 1: Parametric Model Downloader Engine */}
        <div className="bg-slate-900 border border-slate-800 rounded-lg p-6">
          <h2 className="text-lg font-bold mb-4 text-cyan-400 border-b border-slate-800 pb-2">📥 Dynamic Asset Ingestion</h2>
          <div className="space-y-4 text-sm">
            <div>
              <label className="block text-xs text-slate-400 mb-1">Hugging Face Repository ID</label>
              <input type="text" className="w-full bg-slate-950 border border-slate-800 rounded p-2 text-slate-200" value={downloadRepo} onChange={(e) => setDownloadRepo(e.target.value)} />
            </div>
            <div>
              <label className="block text-xs text-slate-400 mb-1">Target Filename (.gguf / .safetensors)</label>
              <input type="text" className="w-full bg-slate-950 border border-slate-800 rounded p-2 text-slate-200" value={downloadFile} onChange={(e) => setDownloadFile(e.target.value)} />
            </div>
            <button onClick={triggerDownload} className="w-full bg-cyan-600 hover:bg-cyan-500 text-slate-950 font-bold p-2.5 rounded transition">Inject Asset Pipeline</button>
          </div>
        </div>

        {/* Panel 2: Model Weights & Parametric Runtime Settings */}
        <div className="bg-slate-900 border border-slate-800 rounded-lg p-6">
          <h2 className="text-lg font-bold mb-4 text-cyan-400 border-b border-slate-800 pb-2">⚙️ Parametric Tuning Overrides</h2>
          <div className="space-y-4 text-sm">
            <div>
              <label className="block text-xs text-slate-400 mb-1">Context Window (num_ctx)</label>
              <select className="w-full bg-slate-950 border border-slate-800 rounded p-2 text-slate-200" value={contextSize} onChange={(e) => setContextSize(Number(e.target.value))}>
                <option value={8192}>8,192 (Fast Code)</option>
                <option value={65536}>65,536 (Mid Repository)</option>
                <option value={131072}>131,072 (Full Codebase Split)</option>
              </select>
            </div>
            <div>
              <label className="block text-xs text-slate-400 mb-1">GPU Layer Allocation (n_gpu_layers)</label>
              <input type="number" className="w-full bg-slate-950 border border-slate-800 rounded p-2 text-slate-200" value={gpuLayers} onChange={(e) => setGpuLayers(Number(e.target.value))} />
            </div>
          </div>
        </div>

        {/* Panel 3: Active Persistent Checkpoints Memory */}
        <div className="bg-slate-900 border border-slate-800 rounded-lg p-6">
          <h2 className="text-lg font-bold mb-4 text-cyan-400 border-b border-slate-800 pb-2">💾 Locked Local Weights Cache</h2>
          <div className="space-y-2 max-h-64 overflow-y-auto pr-2">
            {clusterStatus.available_checkpoints.length === 0 ? (
              <p className="text-xs text-slate-500">No binary weights cached in persistence path.</p>
            ) : (
              clusterStatus.available_checkpoints.map((model, idx) => (
                <div key={idx} className="bg-slate-950 border border-slate-800 p-3 rounded flex justify-between items-center text-xs">
                  <span className="truncate mr-4 text-slate-300 font-bold">{model}</span>
                  <button onClick={() => switchModel(model)} className="bg-emerald-950 border border-emerald-800 hover:bg-emerald-900 text-emerald-400 px-3 py-1.5 rounded font-bold transition">Activate</button>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
