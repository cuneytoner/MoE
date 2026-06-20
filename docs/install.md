# Installation & Orchestration Guide

## Prerequisites
Ensure keyless SSH authorization is fully established from PC-1 to PC-2:
```bash
ssh-copy-id cuneyt@192.168.50.2
```

## Step-by-Step Initial Deployment
1. Clone or pull code repositories exclusively into the development directory on PC-1: `~/DiskD/Projects/MoE/`.
2. Configure the initial environment variable parameters inside the configuration manifest file: `.env`.
3. Trigger the dynamic distribution pipeline script to populate regional clusters:
```bash
cd ~/DiskD/Projects/MoE/
./deploy.sh
```
4. Verify deployment integrity across localized terminals by running the resource monitor panel:
```bash
~/MoE/scripts/watch.sh
```
