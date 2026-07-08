# Dashboard Output Cards UI

## What Was Added

M34.6 adds the first read-only Dashboard UI section for media output cards.

The dashboard now fetches:

```text
GET /gateway/media/output-cards
```

and displays generated image and SVG drawing cards in the main dashboard.

After M34.7, drawing cards may show metadata instead of no metadata when matching sidecar JSON exists.

M34.8 plans future reference-board selection from output cards.

## API Used

```text
/gateway/media/output-cards
```

The UI uses the same Gateway base URL as the existing dashboard API client.

## Component Added

```text
apps/dashboard-ui/src/components/OutputCards.tsx
```

The component is mounted in the main Dashboard UI below the latest images section.

## Fields Displayed

- name
- type
- safety label
- modified time
- file size
- source
- relative runtime path
- metadata availability
- tags

## Safety Constraints

The section is display-only. It does not control services, execute shell commands, browse arbitrary paths, or trigger generation.

## No Destructive Actions

The UI does not include:

- delete button
- move button
- rename button
- service start/stop button
- shell button

## No Generation Buttons

The UI does not include generation buttons or rerun controls.

## How To Run Dashboard

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api dashboard-ui
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/output-cards | jq '.status, .service, (.cards | length), .cards[0]'
```

### Open in browser
```text
http://127.0.0.1:8500
```

## How To Inspect UI

Open the dashboard and look for:

- `Media Output Cards` section
- card count
- image and SVG drawing cards when outputs exist
- visible safety labels
- relative runtime paths
- metadata availability chips

## Known Limitations

- No thumbnail file serving is implemented in this milestone.
- Image cards use an icon placeholder for preview.
- SVG drawings use a drawing/file placeholder.
- Only the first 12 cards are shown.
- Full metadata detail drawer remains planned.

## Next Steps

- Add output card preview serving plan.
- Add metadata sidecar implementation.
- Add dashboard detail drawer.
- Plan reference-board selection on top of output cards.
