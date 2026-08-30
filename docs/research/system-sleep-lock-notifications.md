# macOS notifications for display sleep, lock, screensaver, and system sleep

Resolves [#87](https://github.com/gsong/eyebreak/issues/87), part of the
[#85](https://github.com/gsong/eyebreak/issues/85) map. Researched 2026-08-30
against macOS 26.6 SDK headers and Apple documentation.

Each claim carries a tag:

- **[Apple]** — stated in Apple documentation, an SDK header, or by an Apple
  DTS engineer on the Apple Developer Forums.
- **[Local]** — verified on this Mac (macOS 26.6.2, MacOSX26.5.sdk).
- **[3P]** — a third-party source or an inference. Treat as unconfirmed.

## Summary

1. **Display sleep** posts `NSWorkspace.screensDidSleepNotification` and
   `screensDidWakeNotification`. Apple ties them to screen power only, not to
   lock or system sleep. Delivery to background agents is unreliable.
2. **`com.apple.screenIsLocked`** is undocumented. Third-party reports say it
   fires as soon as the screensaver starts or the display sleeps whenever
   "Require password after sleep or screen saver begins" is on, even before the
   configured delay has passed. Lid close reaches the same path through sleep.
3. **Order** is not documented by Apple. Best reconstruction: idle sleep is
   `screensDidSleep` (and `screenIsLocked` at about the same time) → later
   `willSleep`. Lid close collapses these into the same instant. Wake is
   `didWake` / `screensDidWake` → an unbounded human delay → `screenIsUnlocked`.
4. **Frontmost is irrelevant.** All of these reach any process in the GUI login
   session, including an `LSUIElement` menu-bar app. Clamshell behavior is not
   documented anywhere.
5. **Caveats:** the distributed names are private strings; distributed delivery
   is best-effort and can drop; a `Timer` that fell due during sleep fires once
   on the first run-loop pass after `didWake`, before `screenIsUnlocked`.

The rows of any cause table must allow display sleep, lock, screensaver, and
system sleep to overlap. On a lid close with "Require password" on, all four
happen together.

## 1. Display sleep: `screensDidSleepNotification` / `screensDidWakeNotification`

**[Apple]** "A notification that the workspace posts when the device's screen
goes to sleep" / "when the device's screens wake." The object is the shared
`NSWorkspace`; there is no `userInfo`. Apple adds: "Not many apps use this
notification, but it can be useful for certain hardware-based drawing
decisions." You must register on `NSWorkspace.shared.notificationCenter`; "If
you use a different notification center to register, you won't receive the
notification."
— <https://developer.apple.com/documentation/appkit/nsworkspace/screensdidsleepnotification>,
<https://developer.apple.com/documentation/appkit/nsworkspace/screensdidwakenotification>

**[Apple]** Available since macOS 10.6, declared under `/* Power notifications
*/` in `NSWorkspace.h` with no further comment.
— <https://github.com/phracker/MacOSX-SDKs/blob/master/MacOSX10.9.sdk/System/Library/Frameworks/AppKit.framework/Versions/C/Headers/NSWorkspace.h>

**[Apple]** These describe screen power, not system power. `willSleep` is worded
"before the device goes to sleep"; `screensDidSleep` is "the screen goes to
sleep." Apple says nothing about the lock setting. **[3P]** Because the docs
tie the notification to drawing hardware, it fires whether or not the screen
locks.

**[Apple]** Reliability. Apple DTS (Kevin Elliott) confirmed a report that some
MacBooks miss `screensDidWake`, some miss `didWake`, and some miss `willSleep`:
"Yes, that's basically what I'd expect to find." Power management "isn't fixed
logic," and an app can miss a notification because "the system chose not to
run your app's main runloop (to deliver the notification), not because the
notification itself didn't occur." DTS points to IOKit (QA1340) for a firmer
signal.
— <https://developer.apple.com/forums/thread/796109>

**[3P]** The `neoki` LaunchAgent received `willSleep`/`didWake` and the lock
notifications but never received `screensDidSleep`/`screensDidWake`, so its
author dropped display events.
— <https://github.com/kawarimidoll/neoki>

## 2. Lock: `com.apple.screenIsLocked` / `com.apple.screenIsUnlocked`

**[Local]** Not declared in any header of MacOSX26.5.sdk and not on any Apple
doc page. The strings do exist in the `loginwindow` binary on macOS 26.6.2,
along with `com.apple.screensaver.didlaunch`, `.didstart`, `.didstop`,
`.willstop`, `.previewdidstop`, and `.action`. `loginwindow` is the poster.

**[Apple]** DTS on undocumented distributed names: "the only supported strings
are those documented by Apple ... Observing some random string may work today,
but it's not something that we consider API and thus it may stop working in
the future."
— <https://developer.apple.com/forums/thread/686011>

**When does `screenIsLocked` fire?** Apple says nothing. Three third-party
sources agree:

- **[3P]** Radar 26264008 (OS X 10.11.4): `screenIsLocked` "fires when the
  screensaver or screen sleeps, regardless of what is set for 'require password
  after sleep or screensaver begins' ... so long as the checkbox next to that
  setting is checked." It fires "even though the user is not required to enter
  a password" yet, that is, before the configured delay.
  — <https://github.com/lionheart/openradar-mirror/issues/14685>
- **[3P]** Tony Finch: it "gets triggered as soon as the screensaver starts or
  the screen sleeps, without any delay."
  — <https://dotat.at/@/2016-01-02-hammerspoon-hooks-for-better-screen-lock-security-on-mac-os-x.html>
- **[3P]** `neoki` README: with "Require password" on, sleep and lock "fire at
  about the same time"; `unlock` "fires when you authenticate to unlock —
  whenever that is, not a fixed delay after wake."
  — <https://github.com/kawarimidoll/neoki>

So, with "Require password" on, display sleep implies `screenIsLocked`. With it
off, the display can sleep without any lock notification at all.

**Lid close.** No source states it directly. **[3P]** Lid close is a forced
system sleep, which powers the display down, so `screenIsLocked` fires by the
same path when "Require password" is on.

**[3P]** Screensaver names are also unreliable. Aerial issue 1339 (Sonoma 14.1)
found the OS "simply not sending the com.apple.screensaver.willstop
notification" under rapid start/stop.
— <https://github.com/JohnCoates/Aerial/issues/1339>

## 3. Order and overlap

### What Apple documents (IOKit only)

**[Apple]** `IOPMLib.h` lifecycle: `kIOMessageCanSystemSleep` ("the system is
pondering an idle sleep"; apps may veto; followed within 30 s by
`kIOMessageSystemWillSleep` or `kIOMessageSystemWillNotSleep`) →
`kIOMessageSystemWillSleep` (non-abortable; "Callers MUST acknowledge this
event by calling IOAllowPowerChange"; otherwise "the sleep will continue anyway
after a 30 second timeout") → `kIOMessageSystemWillPowerOn` (early, before
most hardware) → `kIOMessageSystemHasPoweredOn` ("Expect this event 1-5 or more
seconds after initiating system wakeup").
— <https://developer.apple.com/documentation/iokit/kiomessagecansystemsleep>,
<https://developer.apple.com/documentation/iokit/kiomessagesystemwillsleep>,
<https://developer.apple.com/documentation/iokit/kiomessagesystemhaspoweredon>

**[Apple]** QA1340: `kIOMessageCanSystemSleep` "will not be sent for forced
sleep." Forced sleep is lid close, the Apple menu, or an emergency; "it is not
possible to prevent forced sleep, only delay it." NSWorkspace notifications
"are filed on NSWorkspace's notification center, not the default notification
center."
— <https://developer.apple.com/library/archive/qa/qa1340/_index.html>

**[Apple]** `NSWorkspace.willSleepNotification`: "An observer of this message
can delay sleep for up to 30 seconds while handling this notification." There
is no acknowledgement API at the NSWorkspace level; blocking the handler is the
only delay.
— <https://developer.apple.com/documentation/appkit/nsworkspace/willsleepnotification>

**[Apple]** `didWakeNotification` "posts when the device wakes from sleep." No
ordering against `screensDidWake` is given.
— <https://developer.apple.com/documentation/appkit/nsworkspace/didwakenotification>

### Dark wake / Power Nap

**[Apple]** DTS: "`kIOMessageSystemHasPoweredOn` wasn't delivered ... because
Dark Wake isn't considered 'On'"; `NSWorkspaceDidWakeNotification` "basically
means ... the system is 'fully awake' and apps should operate normally"; "we
don't have any API for detecting DarkWake." So `didWake` does not fire on
maintenance wakes, and there is no supported way to observe them.
— <https://developer.apple.com/forums/thread/770517>

### Reconstructed order (not documented by Apple)

No Apple source and no third-party source publishes a timestamped trace. The
following is assembled from the sources above and is **[3P]** throughout.

Idle to sleep, "Require password" on:

1. Display timer expires: `screensDidSleep`, and `screenIsLocked` at about the
   same moment (radar 26264008, Finch). If the screensaver timer is shorter,
   `com.apple.screensaver.didstart` and `screenIsLocked` come first instead.
2. System timer expires, possibly minutes later: `willSleep`.

Lid close (forced sleep):

1. No `kIOMessageCanSystemSleep`. `screensDidSleep`, `screenIsLocked`, and
   `willSleep` arrive within the same short window. Relative order among the
   three is unknown and may differ by device (DTS, thread 796109).

Wake:

1. `didWake` and `screensDidWake` (relative order unknown; either may be
   missing on some MacBooks).
2. User authenticates: `screenIsUnlocked`. The gap is a human interval, not a
   fixed delay. If "Require password" is off, no unlock notification comes;
   `screensDidWake` (or `screensaver.didstop`) is the only resume signal.

Idle sleep with "Require password" off: `screensDidSleep` → `willSleep`; wake:
`didWake` / `screensDidWake` only.

## 4. Non-frontmost apps and clamshell mode

**[Apple]** DTS describes `NSWorkspaceDidWakeNotification` as "LaunchAgent only"
— it needs a process in the GUI login session, not a daemon. Frontmost status
is never mentioned as a condition.
— <https://developer.apple.com/forums/thread/770517>

**[Apple]** Delivery does depend on the main run loop being scheduled (thread
796109, above). A menu-bar app that keeps its main run loop free receives them.

**[Apple]** Apple's recommended pattern for lock/logout detection is an agent in
the GUI context, which is what EyeBreak already is.
— <https://developer.apple.com/forums/thread/686011>

**[3P]** No source restricts distributed-notification observation to frontmost
apps; `neoki` and Hammerspoon receive them as background agents.

**Clamshell / no display attached: not found in any Apple source.** The only
Apple statement is DTS acknowledging that lid-close behavior with and without
external displays is inconsistent across MacBooks (thread 796109). Whether
`screensDidSleep` fires when the internal panel is closed but an external
display stays lit is unknown.

## 5. Caveats

**Private names.** See section 2. `com.apple.screenIsLocked`,
`com.apple.screenIsUnlocked`, and `com.apple.screensaver.*` may stop working
in any release.

**Best-effort delivery.** **[Apple]** `DistributedNotificationCenter`: "The
latency between posting the notification and the notification's arrival in
another task is unbounded. In fact, when too many notifications are posted and
the server's queue fills up, notifications may be dropped."
— <https://developer.apple.com/documentation/foundation/distributednotificationcenter>

**App Sandbox.** **[Apple]** Posting: "If the sending application is in an App
Sandbox, userInfo must be nil." Nothing is said about observing.
— <https://developer.apple.com/documentation/foundation/distributednotificationcenter/postnotificationname(_:object:userinfo:options:)>
**[3P]** Registering for all notifications (nil name) is "thwarted by
sandboxing," but registering by a specific name works.
— <https://objective-see.org/blog/blog_0x39.html>

**Timers across sleep.** **[Apple]** GCD: "When a computer goes to sleep, all
timer dispatch sources are suspended. When the computer wakes up, those timer
dispatch sources are automatically woken up." A `dispatch_time`-based timer
uses a clock that "does not advance while the computer is asleep";
`dispatch_walltime` tracks wall-clock time.
— <https://developer.apple.com/library/archive/documentation/General/Conceptual/ConcurrencyProgrammingGuide/GCDWorkQueues/GCDWorkQueues.html>
**[Apple]** `Timer`: "If the firing time is delayed so far that it passes one
or more of the scheduled firing times, the timer is fired only once for that
time period." Repeating timers compute the next fire date from the original.
— <https://developer.apple.com/documentation/foundation/timer>,
<https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/Timers.html>

**Wake gap.** **[3P]** `didWake` fires at wake; `screenIsUnlocked` fires at
authentication. An overdue `Timer` therefore fires once on the first run-loop
pass after wake, before the user unlocks. A break overlay scheduled that way
appears behind the lock screen. No source states this directly; it follows from
the two facts above.

**Polling instead of listening.** **[Apple]** `CGSessionCopyCurrentDictionary()`
returns the caller's window-server session, or `NULL` outside a GUI session.
Documented keys in `CGSession.h`: `kCGSessionUserIDKey`, `kCGSessionUserNameKey`,
`kCGSessionConsoleSetKey`, `kCGSessionOnConsoleKey`, `kCGSessionLoginDoneKey`.
**[Local]** `CGSSessionScreenIsLocked` is **not** in the header; it is a
third-party-discovered key.
— <https://developer.apple.com/documentation/coregraphics/cgsessioncopycurrentdictionary()>,
<https://github.com/felixrieseberg/macos-notification-state/blob/master/lib/notificationstate-query.cc>
**[Apple]** `CGDisplayIsAsleep` (10.2+) reports whether a display's framebuffer
and monitor are in reduced power mode.
— <https://developer.apple.com/documentation/coregraphics/cgdisplayisasleep(_:)>

## What this research could not settle

- Any Apple statement on the relative order of `screensDidSleep`, `willSleep`,
  `screenIsLocked`, and `screensaver.didstart`, or of `didWake`,
  `screensDidWake`, and `screenIsUnlocked`.
- Any Apple documentation of the `com.apple.screenIsLocked` family or
  `CGSSessionScreenIsLocked`.
- Clamshell / external-display-only behavior for display sleep and lock.
- Whether sandboxed apps may observe distributed notifications (only posting
  is documented).

A local trace on this Mac (log every notification with a timestamp across an
idle sleep, a lid close, and a manual lock) would settle the order for the
hardware EyeBreak actually runs on. That is a follow-up, not part of this
ticket.

## What EyeBreak listens to today

`EyeBreak/Managers/BreakTimerManager+SystemEvents.swift` observes `willSleep`,
`didWake`, `com.apple.screenIsLocked`/`Unlocked`, and
`com.apple.screensaver.didstart`/`didstop`. It does not observe
`screensDidSleep`/`screensDidWake`, so display sleep with "Require password"
off is invisible to the timer.
