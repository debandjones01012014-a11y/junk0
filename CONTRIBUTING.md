# Contributing

Thanks for helping! Junk0 is a personal side project that has only been tested properly on one Mac, so **test reports are the most valuable contribution** — use the [Test report form](../../issues/new/choose), even for "it worked fine".

If you change code, a few rules keep Junk0 trustworthy:

1. **Safety first.** A new cleaning rule must target files that are either regenerated automatically
   (then it may be deleted) or that the user reviews one by one (then it must go to the Trash).
2. **Document it.** Every new path goes into `docs/SAFETY.md`.
3. **Respect open apps and exclusions.** Use `safe()`, `underExcluded()` and `RunningApps` from `Engine.swift`.
4. **No network, no analytics, no admin rights.**
5. Test with `--scan-report` before testing a real clean, and describe what you tested in the pull request.

Bug reports: please include your macOS version, the app version, and the `--scan-report` output.
