// Capability: CAP-COURSE-PLAYER. Rules: SEC-06, SEC-24 (no secrets here). Tests: TC-LRN-40-07..08.
// Implemented here: progress persistence. Atomic write (temp file + rename). The file can be edited
// by the learner or by other software, so it is validated on every read and backed up if invalid.
import fs from 'node:fs';
import path from 'node:path';
import { emptyProgress, parseProgress, type Progress } from '../core/progress';

const FILE = 'progress.json';
const MAX_BYTES = 512 * 1024;

export class ProgressStore {
  constructor(private readonly dir: string) {}

  load(): Progress {
    const file = path.join(this.dir, FILE);
    let text: string;
    try {
      if (fs.statSync(file).size > MAX_BYTES) return this.quarantine(file);
      text = fs.readFileSync(file, 'utf8');
    } catch {
      return emptyProgress();
    }
    try {
      const parsed: unknown = JSON.parse(text);
      const progress = parseProgress(parsed);
      // parseProgress resets to empty on invalid data; distinguish "valid but empty" from "rejected".
      if (progress.version === 1 && Object.keys(progress.labs).length === 0 && JSON.stringify(parsed) !== JSON.stringify(emptyProgress())) {
        return this.quarantine(file);
      }
      return progress;
    } catch {
      return this.quarantine(file);
    }
  }

  save(progress: Progress): void {
    fs.mkdirSync(this.dir, { recursive: true });
    const file = path.join(this.dir, FILE);
    const tmp = `${file}.${process.pid}.tmp`;
    fs.writeFileSync(tmp, JSON.stringify(progress), { mode: 0o600 });
    fs.renameSync(tmp, file);
  }

  private quarantine(file: string): Progress {
    try {
      fs.renameSync(file, `${file}.corrupt-${Date.now()}`);
    } catch {
      /* nothing more we can do; continue with empty progress */
    }
    return emptyProgress();
  }
}
