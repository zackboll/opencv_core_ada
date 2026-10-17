# CORE-GEOMETRY-DOC-XLINK-R1

## Demonstrated cause

Reproduced using the actual generated Core `dace47d` and Geometry `a01f457`
sites with Playwright 1.64.1 / Chromium 156.0.8078.4, including the original
Geometry click, reload, Sparse, Back, Back to Geometry, Forward sequence.
The failure is intermittent and is not limited to the mobile viewport.

One captured desktop failure had the correct outer `OpenCV.Rect` bookmark,
correct iframe URL and fragment, correct target declaration, no browser errors,
iframe `scrollY = 0`, target `top = 8124.546875`, and viewport height `900`.
The target remained offscreen at iframe load, iframe pageshow, outer pageshow,
and their animation-frame callbacks. The screenshot showed the package summary,
not the declaration. Native fragment scrolling therefore does not establish
the visual destination reliably during cross-document history traversal.

Core's router previously restored only the iframe URL. An already-matching
URL was a no-op; iframe load only updated the bookmark and click handler, and
there was no pageshow restoration. This left native persisted scroll handling
in control even though the outer symbol bookmark specifies a declaration.
This is a Core navigation lifecycle defect exposed by Chromium history
restoration, not an assertion synchronization defect.

## Correction and regression

The router reveals the source-verified symbol anchor after iframe load and
already-matching restore, and restores on pageshow as well as popstate.
One animation-frame callback runs after native traversal scroll handling;
it rechecks the current requested symbol, exact frame URL, and completed
document before scrolling. There is no timer, retry loop, extra history entry,
global manual-scroll policy, or generated filename/anchor construction.
Package-only browsing and unsupported foreign frames remain unchanged.

The Core regression serves the real generated browser at two distinct origins
and covers Rect, Angle_Unit and Mat at 1280 and 390 pixels, reload, Sparse,
cross-origin Back/Forward, stale persisted offsets, fresh tabs, and a separate
deterministic persisted-pageshow lifecycle check. That last check fails with
the old router and passes with the correction; actual history traversal is
also exercised independently. All declaration viewport assertions are retained.
Geometry separately qualifies actual cross-repository links and records
screenshots and URL/anchor/rectangle/scroll/history/error diagnostics on failure.

Core PR #85 was already merged before this correction began. The repair is
therefore reviewed independently in a follow-up PR from Core main. Geometry
must pin the newly qualified corrective HEAD, not a moving branch or main.
Neither review gate authorizes merging, tagging, deployment, or auto-merge.