# patches/

Patches applied to the upstream [whatsapp-mcp](https://github.com/lharries/whatsapp-mcp)
clone by `setup.sh`. Every `*.patch` here is applied (in filename order) right
after the pinned checkout; they touch disjoint regions of `main.go`, so order
doesn't matter.

## whatsmeow-context-fix.patch

Upstream [PR #193](https://github.com/lharries/whatsapp-mcp/pull/193).

**Problem it fixes:** upstream `main` pins an old `whatsmeow` and uses its
pre-`context.Context` API. When you build the bridge with a current Go toolchain,
it pulls a newer `whatsmeow` whose API now requires a `context.Context` first
argument, and the build fails with `not enough arguments in call to ...`.

**The fix (6 lines):** threads `context.Background()` through the 5 call sites
that need it (`Download`, `sqlstore.New`, `GetFirstDevice`, `GetGroupInfo`,
`GetContact`). It also bumps `whatsmeow` in `go.mod`, but that line is only a
**baseline** — see below.

## qr-fullblock.patch

Makes the pairing QR code reliably scannable.

**Problem it fixes:** the bridge prints the QR with
`qrterminal.GenerateHalfBlock(..., qrterminal.L, ...)` — half-block characters
with **low** error-correction. Half-block glyphs render with small vertical gaps
in many terminals/fonts, distorting the code so WhatsApp rejects it as
*"Código QR no válido" / "Invalid QR code."*

**The fix (1 line):** switch to `qrterminal.Generate(..., qrterminal.M, ...)` —
full-block characters with **medium** error-correction. The QR is taller (zoom the
terminal out so it fits without wrapping), but scans far more reliably.

## Two different "pins" — don't conflate them

1. **Upstream source pin (fixed).** `setup.sh` checks the clone out to a fixed
   upstream commit (`7d6a06d…`) before applying this patch, so `git apply` is
   always clean no matter how far upstream `main` has drifted. To move to a newer
   upstream: re-pin to a new commit, regenerate the patch against it, re-test.

2. **The `whatsmeow` dependency version (NOT pinned).** `setup.sh` runs
   `go get go.mau.fi/whatsmeow@latest` after applying the patch, so every install
   gets the current library. This is deliberate: WhatsApp periodically raises its
   minimum client version and rejects older `whatsmeow` builds at connect time
   with **`Client outdated (405)`**. A fixed pin would work today and 405 in a few
   months. The `go.mod` version the patch writes is just a starting point that
   `go get @latest` overrides.
