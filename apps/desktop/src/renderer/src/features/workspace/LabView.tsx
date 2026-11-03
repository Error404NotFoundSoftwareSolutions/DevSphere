// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-MAINT-005
// Implemented here: guide, editor, terminal and tutor stay visible together (FR-WS-005)

import { GuidePanel } from "../guide/GuidePanel";
import { TutorPanel } from "../tutor/TutorPanel";
import { WorkspaceView } from "./WorkspaceView";
import { TaskBar } from "./TaskBar";

export function LabView() {
  return (
    <div className="grid grid-cols-[1fr_2fr_1fr] gap-4">
      <GuidePanel />
      <div>
        <WorkspaceView />
        <TaskBar />
      </div>
      <TutorPanel />
    </div>
  );
}
