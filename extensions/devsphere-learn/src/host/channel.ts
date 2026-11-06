// Capability: CAP-APP-EXT-CHANNEL (ADR-022). Rules: SEC-21, SEC-26. Threat T19. Tests: TC-CMP-11-xx
// Implemented here: the channel client. Connects to the worker's private socket, says hello, waits for
// welcome, then relays only valid events and sends only valid requests. It holds no credentials.
import net from 'node:net';
import { FrameDecoder, ProtocolError, checkRequest, encodeFrame, parseEvent, requests, type ExtRequest, type WorkerEvent } from '../core/protocol';
import type { SessionInfo } from './session';

export class ChannelClient {
  private socket: net.Socket | undefined;
  private ready = false;
  private eventCbs: ((e: WorkerEvent) => void)[] = [];
  private closeCbs: (() => void)[] = [];

  constructor(
    private readonly session: SessionInfo,
    private readonly extVersion: string,
    private readonly opts: { handshakeTimeoutMs?: number } = {},
  ) {}

  onEvent(cb: (e: WorkerEvent) => void): void { this.eventCbs.push(cb); }
  onClose(cb: () => void): void { this.closeCbs.push(cb); }

  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      const decoder = new FrameDecoder();
      const socket = net.createConnection({ path: this.session.socketPath });
      this.socket = socket;
      let settled = false;
      const fail = (message: string): void => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        socket.destroy();
        reject(new Error(message));
      };
      const timer = setTimeout(() => fail('DevPilot did not answer. Open this lab again from the DevPilot app.'), this.opts.handshakeTimeoutMs ?? 5000);
      socket.on('connect', () => socket.write(encodeFrame(requests.hello(this.session.sessionId, this.extVersion))));
      socket.on('error', () => fail('Could not connect to the DevPilot app. Open this lab again from DevPilot.'));
      socket.on('data', (chunk) => {
        let raws: unknown[];
        try {
          raws = decoder.push(chunk);
        } catch (e) {
          if (e instanceof ProtocolError) {
            if (settled) socket.destroy();
            else fail('DevPilot sent a message this guide does not understand.');
          }
          return;
        }
        for (const raw of raws) {
          const event = parseEvent(raw);
          if (!event) continue; // drop anything that is not a valid event
          if (!this.ready) {
            if (event.type === 'welcome') {
              if (event.labId !== this.session.labId) { fail('DevPilot answered for a different lab.'); return; }
              this.ready = true;
              settled = true;
              clearTimeout(timer);
              resolve();
            } else if (event.type === 'error') {
              fail(event.message);
              return;
            }
            continue;
          }
          for (const cb of this.eventCbs) cb(event);
        }
      });
      socket.on('close', () => {
        const wasReady = this.ready;
        this.ready = false;
        if (wasReady) for (const cb of this.closeCbs) cb();
        fail('The DevPilot app closed the connection.');
      });
    });
  }

  send(request: ExtRequest): void {
    if (!this.socket || !this.ready) throw new Error('Not connected to the DevPilot app.');
    this.socket.write(encodeFrame(checkRequest(request)));
  }

  close(): void {
    this.socket?.destroy();
    this.socket = undefined;
    this.ready = false;
  }
}
