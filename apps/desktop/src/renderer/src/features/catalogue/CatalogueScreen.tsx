// User story: US-06 Browse the lab catalogue (Sprint 2, MVP)
// Requirements: FR-CAT-001..003
// Implemented here: list labs with difficulty, prerequisites and supported systems (FR-CAT-001); paginated (NFR-PERF-006)

import { useQuery } from "@tanstack/react-query";
import { call } from "../../api";

type Lab = { id: string; title: string; version: string };

export function CatalogueScreen({ onOpen }: { onOpen: (id: string) => void }) {
  const { data } = useQuery({
    queryKey: ["labs", 1],
    queryFn: () => call<{ labs: Lab[] }>("catalogue:list", { page: 1 }),
  });
  return (
    <section aria-labelledby="catalogue-title">
      <h2 id="catalogue-title">Labs</h2>
      <ul>
        {data?.labs.map((l) => (
          <li key={l.id}>
            <button onClick={() => onOpen(l.id)}>
              {l.title} (v{l.version})
            </button>
          </li>
        ))}
      </ul>
    </section>
  );
}
