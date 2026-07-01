type Props = {
  hints: Record<string, string>;
};

export function ModeHintsPanel({ hints }: Props) {
  return (
    <section className="panel">
      <h2>Mode Hints</h2>
      <div className="stack">
        {Object.entries(hints).map(([mode, hint]) => (
          <div className="hint" key={mode}>
            <strong>{mode}</strong>
            <p>{hint}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
