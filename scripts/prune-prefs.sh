#!/bin/bash
# Delete the preference keys that 3.0.0 orphaned from com.eyebreak.app.
#
# Run this once, by hand, after scripts/dev-install.sh installs 3.0.0. It is not
# part of the build and nothing calls it. Re-running it is safe: every delete is
# skipped when the key is already gone.
#
# The point is an honest `defaults read com.eyebreak.app`. The feature cut left
# 32 settings behind with no code that reads them, and the Sparkle removal before
# it left four more. This script is also the record of what 3.0.0 removed, so it
# names all 38 keys even though most were never written to disk - @AppStorage
# writes a key when the setting is set, not when it is read, so a setting nobody
# ever touched has no row to delete.
#
# It quits EyeBreak first. AppKit holds the Settings window frame in memory and
# writes it back on quit, so deleting that key under a running app achieves
# nothing. It leaves the app quit for the same reason - relaunch by hand.
#
# Deliberately NOT deleted:
#   workIntervalMinutes, breakDurationSeconds, requireBreakDismissal,
#   soundEnabled, idleDetectionEnabled, idleThresholdMinutes, launchAtLogin
#       - the seven settings 3.0.0 still has.
#   accessibilityPromptedForVersion
#       - still read by AccessibilityPermission, which serves Require Dismissal.
#   NSStatusItem Preferred Position EyeBreakStatusItem
#       - where you dragged the menu bar icon.

set -euo pipefail

DOMAIN="com.eyebreak.app"

DRY_RUN=false
case "${1:-}" in
    --dry-run) DRY_RUN=true ;;
    "") ;;
    *)
        echo "usage: $0 [--dry-run]" >&2
        exit 2
        ;;
esac

# Ambient reminders - the floating blink-and-stretch pop-up.
KEYS=(
    ambientRemindersEnabled
    ambientReminderIntervalMinutes
    ambientReminderDurationSeconds
    customReminderEmoji
    customReminderMessage
    useCustomReminder
)

# Water reminders - the hourly drink-water overlay.
KEYS+=(
    waterReminderEnabled
    waterReminderInterval
    waterReminderStyle
    customWaterReminderIcon
    customWaterReminderMessage
    useCustomWaterReminder
)

# Smart Schedule - work hours and active days.
KEYS+=(
    smartScheduleEnabled
    workHoursStart
    workHoursEnd
    pauseOnWeekends
    activeDays
)

# Colour themes - three surfaces, two keys each.
KEYS+=(
    ambientReminderThemeType
    ambientReminderCustomTheme
    breakOverlayThemeType
    breakOverlayCustomTheme
    waterReminderThemeType
    waterReminderCustomTheme
)

# Break styles - the Floating Window and Eye Exercise alternatives.
KEYS+=(
    breakStyle
    eyeExerciseDurationSeconds
    exerciseIntervalSeconds
)

# Statistics - the tab and the history the timer wrote behind it.
KEYS+=(
    dailyBreakGoal
    breakStatistics
)

# Timer settings that lost their control.
KEYS+=(
    sessionType
    autoStartTimer
    preBreakWarningSeconds
)

# Onboarding - a flow nothing could reach.
KEYS+=(
    hasLaunchedBefore
)

# Sparkle, removed before this cut and never swept up.
KEYS+=(
    SUHasLaunchedBefore
    SULastCheckTime
    SUUpdateGroupIdentifier
    "NSWindow Frame SUUpdateAlert2"
)

# Window state for a Settings window that no longer has a sidebar, and a frame
# saved at the old size.
KEYS+=(
    "NSWindow Frame settings"
    "NSSplitView Subview Frames settings, SidebarNavigationSplitView"
)

has_key() {
    defaults read "$DOMAIN" "$1" > /dev/null 2>&1
}

if [ "$DRY_RUN" = true ]; then
    echo "Dry run. Nothing is quit and nothing is deleted."
    echo
    present=0
    for key in "${KEYS[@]}"; do
        if has_key "$key"; then
            echo "  would delete  $key"
            present=$((present + 1))
        else
            echo "  not on disk   $key"
        fi
    done
    echo
    echo "${#KEYS[@]} keys named, $present on disk."
    exit 0
fi

echo "Before:"
defaults read "$DOMAIN" || echo "  (no preferences)"
echo

echo "Quitting EyeBreak..."
osascript -e 'tell application "EyeBreak" to quit' 2> /dev/null || true
# Give the app a moment to write its window frame and release the menu bar item.
for _ in 1 2 3 4 5 6 7 8 9 10; do
    pgrep -x EyeBreak > /dev/null || break
    /bin/sleep 0.2
done
pkill -x EyeBreak 2> /dev/null || true
echo

deleted=0
for key in "${KEYS[@]}"; do
    if has_key "$key"; then
        defaults delete "$DOMAIN" "$key"
        echo "  deleted  $key"
        deleted=$((deleted + 1))
    fi
done
echo
echo "Deleted $deleted of the ${#KEYS[@]} keys named; the rest were never written."
echo

echo "After:"
defaults read "$DOMAIN" || echo "  (no preferences)"
echo
echo "EyeBreak is quit. Relaunch it yourself - reopening it now is what saves a"
echo "fresh window frame, and that frame is one of the keys just deleted."
