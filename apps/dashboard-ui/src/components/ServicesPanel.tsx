import type { ServiceStatus } from "../types";
import { ServiceStatusGrid } from "./ServiceStatusGrid";

type Props = {
  services: Record<string, ServiceStatus>;
};

export function ServicesPanel({ services }: Props) {
  return <ServiceStatusGrid services={services} />;
}
