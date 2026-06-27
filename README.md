# Project Memory System

## Directory Structure
```
.project/
  commit0/
  memory/
  prompts/
```

## Files
- **identity.json**: Project identity.
- **pcs.json**: Contains every development computer.
- **rules.json**: Permanent engineering rules.
- **preferences.json**: User preferences.
- **tools.json**: Installed developer tools.
- **learned_facts.json**: Persistent knowledge.
- **session_notes.json**: Temporary working memory.
- **decisions.json**: Stores engineering decisions.
- **README.md**: Explains the memory system, file purposes, update policy, and priority.

## File Purposes
- **identity.json**: Project identity. Never automatically modify. Contains project name, description, main language, framework, architecture, repository type.
- **pcs.json**: Each computer has name, hostname, operating system, distribution, shell, cpu, gpu, ram, python version, venv activation, workspace paths, cuda version, driver version, favorite editor. Anything here becomes permanent.
- **rules.json**: Permanent engineering rules. Examples include always using Python virtual environments, never installing packages globally, always activating venv first, always producing Linux commands for Linux PCs, never assuming Windows commands unless current PC is Windows, never deleting user files automatically, always ask before destructive operations. Anything here becomes permanent behavior.
- **preferences.json**: User preferences. Examples include preferred LLM, preferred quantization, preferred code style, preferred formatter, preferred branch strategy, preferred package manager, preferred docker settings, preferred commit style.
- **tools.json**: Installed developer tools. Examples include Python, Node, Docker, Cursor, Continue, llama.cpp, CUDA, git, cmake, clang, gcc, etc.
- **learned_facts.json**: Persistent knowledge. Every time the user says "remember this", "learn this", "save this", append only. Never overwrite existing facts.
- **session_notes.json**: Temporary working memory. May be cleared. Never use as permanent storage.
- **decisions.json**: Stores engineering decisions. Architecture decisions. Rejected approaches. Accepted designs. Reasons.
- **README.md**: Explains the memory system, file purposes, update policy, and priority.

## Memory Priority
1. commit0/
2. learned_facts.json
3. decisions.json
4. session_notes.json

## Update Policy
- Never overwrite.
- Merge.
- Append.
- Keep history.
- Timestamp every modification.

## Development Environment
- **VSCode + Continue extension**
- **Python virtual environment** created in `~/MoE`
- **llama.cpp based model servers**