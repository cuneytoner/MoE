import type { ServiceStatus } from "../types";

type Props = {
  services: Record<string, ServiceStatus>;
};

export function ServicesPanel({ services }: Props) {
  return (
    <section className="panel">
      <h2>Services</h2>
      <div className="service-grid">
        {Object.entries(services).map(([key, service]) => (
          <article className="service-card" key={key}>
            <div>
              <strong>{service.service}</strong>
              <span>{service.url}</span>
            </div>
            <code className={service.reachable === false ? "bad" : "good"}>
              {service.status}
            </code>
            {service.detail ? <p>{service.detail}</p> : null}
          </article>
        ))}
      </div>
    </section>
  );
}
