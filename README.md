# MoE / AI-Brain-OS

Clean source code repository for the local multi-PC MoE system.

## Repository rule

This folder is source code only.

Runtime files, database volumes, logs, model caches, temporary files, and generated artifacts must not be written into this repository.

## Paths

PC1 source code:
```text
/home/cuneyt/DiskD/Projects/MoE/codebase

PC1 runtime:

/home/cuneyt/MoE

PC2 runtime:

/home/cuneyt/MoE
Network

PC1:

192.168.50.1

PC2:

192.168.50.2

Deploy user:

cuneyt

Passwordless SSH is expected between PC1 and PC2.

Milestone 0

Goal: clean repository, clean source/runtime separation, no old runtime pollution inside codebase.


