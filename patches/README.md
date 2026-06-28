# patches/

Patches applied to the upstream [whatsapp-mcp](https://github.com/lharries/whatsapp-mcp)
clone by `setup.sh`.

## whatsmeow-context-fix.patch

Upstream [PR #193](https://github.com/lharries/whatsapp-mcp/pull/193).

**Problem it fixes:** upstream `main` pins an old `whatsmeow` and uses its
pre-`context.Context` API. When you build the bridge with a current Go toolchain,
it pulls a newer `whatsmeow` whose API now requires a `context.Context` first
argument, and the build fails with `not enough arguments in call to ...`.

**The fix (6 lines):** bumps `whatsmeow` in `go.mod` to a known-good version and
threads `context.Background()` through the 5 call sites that need it
(`Download`, `sqlstore.New`, `GetFirstDevice`, `GetGroupInfo`, `GetContact`).

## Why we pin the clone

`setup.sh` checks the clone out to a fixed upstream commit
(`7d6a06d…`) before applying this patch, so `git apply` is always clean
regardless of how far upstream `main` has drifted. To move to a newer upstream:
re-pin to a new commit, regenerate the patch against it, and re-test the build.
