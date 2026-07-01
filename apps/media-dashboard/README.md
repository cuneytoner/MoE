# Media Dashboard

Source-only static dashboard for Milestone 26.5.

The dashboard reads:

```text
http://127.0.0.1:8100/gateway/media/dashboard
```

It does not start services, stop services, trigger real generation, call Docker, or write runtime data.

Optional local development uses repo-external package caches as configured by your shell:

```bash
cd apps/media-dashboard
npm install
npm run dev
```

Do not commit `node_modules`, build output, runtime media, or generated assets.
