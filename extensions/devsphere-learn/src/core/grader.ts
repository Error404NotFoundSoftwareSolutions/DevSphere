// Capability: CAP-VERIFIED-GRADING (client side port). Rules: TRU-01, TRU-02, ARC-02. Tests: TC-LRN-41-02.
// Implemented here: the port the learn extension uses for Verified submission. The default adapter
// is honest: it says grading is not connected. A real adapter must call services/api over TLS and
// accept only server-signed results.

export type GraderOutcome =
  | { status: 'verified'; score: number; message: string }
  | { status: 'failed'; message: string }
  | { status: 'unavailable'; message: string };

export interface GraderClient {
  submit(labId: string): Promise<GraderOutcome>;
}

export class NotConfiguredGrader implements GraderClient {
  async submit(_labId: string): Promise<GraderOutcome> {
    return {
      status: 'unavailable',
      message: 'Verified grading is not connected yet. Your practice results are saved on this computer.',
    };
  }
}
