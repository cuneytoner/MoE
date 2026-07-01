type Props = {
  commands: Record<string, string[]>;
};

export function SafeCommandsPanel({ commands }: Props) {
  return (
    <section className="panel">
      <h2>Safe Command Hints</h2>
      <div className="stack">
        {Object.entries(commands).map(([group, values]) => (
          <div className="command-group" key={group}>
            <strong>{group}</strong>
            {values.map((command) => (
              <code key={command}>{command}</code>
            ))}
          </div>
        ))}
      </div>
    </section>
  );
}
