# Dashboard UI

Read-only Dashboard UI MVP for Milestone 26.8.

The UI reads Gateway's media dashboard model:

```text
http://127.0.0.1:8100/gateway/media/dashboard
```

It does not start or stop services, call Docker, suspend machines, trigger real generation, or modify runtime media.

Local development:

```bash
cd apps/dashboard-ui
npm install
npm run dev
```

Docker:

```bash
make dashboard-ui-up
make dashboard-ui-health
make dashboard-ui-open
```

Do not commit `node_modules`, build output, generated media, logs, or runtime data.
