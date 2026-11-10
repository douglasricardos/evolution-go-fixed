# Evolution Go (Patched 405 Fix)

Container build for Evolution Go v0.7.2 applying the `store.SetWAVersion` patch from PR #227 to resolve the WhatsApp HTTP 405 Client Outdated handshake block.

## Status ack fix (0.7.2-fix405-statusack)

Also bumps `go.mau.fi/whatsmeow` to `a2381054887e` (first commit that acks top-level `<status>` nodes), the same change as upstream PR evolution-foundation/evolution-go#220.
Without it, WhatsApp closes the stream about every 50 minutes with `<stream:error><ack class="status" type="media"/>` and the instance reconnects in a loop (upstream issue #211).
