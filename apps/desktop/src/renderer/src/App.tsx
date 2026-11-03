// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-MAINT-005
// Implemented here: the shell of the app: which screen is shown. The lab view puts guide, workspace and tutor side by side (FR-WS-005)

import { useState } from "react";
import { SignInScreen } from "./features/auth/SignInScreen";
import { CatalogueScreen } from "./features/catalogue/CatalogueScreen";
import { LabView } from "./features/workspace/LabView";

type Screen = "sign-in" | "catalogue" | "lab";

export function App() {
  // Starter navigation. Replace with a router when more screens exist.
  const [screen, setScreen] = useState<Screen>("sign-in");
  return (
    <main className="p-4">
      {screen === "sign-in" && <SignInScreen onDone={() => setScreen("catalogue")} />}
      {screen === "catalogue" && <CatalogueScreen onOpen={() => setScreen("lab")} />}
      {screen === "lab" && <LabView />}
    </main>
  );
}
