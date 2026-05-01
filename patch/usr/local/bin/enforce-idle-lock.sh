#!/bin/bash

set -u

LIMIT_MS=$[15*60*1000]
CHECK_SEC=60
VERIFY_SEC=5
TAG="enforce-idle-lock"

log() {
	#logger -t "$TAG" -- "$*"
	:
}

prop() {
    loginctl show-session "$1" -p "$2" --value 2>/dev/null || true
}

idle_ms() {
    local user="$1" uid="$2"

    runuser -u "$user" -- env \
        XDG_RUNTIME_DIR="/run/user/$uid" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
        /usr/bin/gdbus call \
            --session \
            --dest org.gnome.Mutter.IdleMonitor \
            --object-path /org/gnome/Mutter/IdleMonitor/Core \
            --method org.gnome.Mutter.IdleMonitor.GetIdletime \
        2>/dev/null |
        sed -n 's/.*uint64 \([0-9][0-9]*\).*/\1/p'
}

gdm_greeter_session() {
    loginctl list-sessions --no-legend | while read -r sid uid user seat rest; do
        [ "$user" = "gdm" ] || continue

        class="$(loginctl show-session "$sid" -p Class --value 2>/dev/null || true)"
        state="$(loginctl show-session "$sid" -p State --value 2>/dev/null || true)"

        case "$class" in
            greeter|user)
                echo "$sid"
                return 0
                ;;
        esac
    done | head -n1
}

switch_to_gdm_greeter() {
    greeter_sid="$(gdm_greeter_session)"

    if [ -n "$greeter_sid" ]; then
        log "Activating GDM greeter session=$greeter_sid"
        loginctl activate "$greeter_sid" || true
        return
    fi

    log "No GDM greeter session found; restarting gdm3"
    systemctl restart gdm3 || true
}

while :; do
    loginctl list-sessions --no-legend | while read -r sid uid user seat rest; do
        [ "$(prop "$sid" Class)" = "user" ] || continue
        [ "$(prop "$sid" Type)" = "x11" ] || continue
        [ "$(prop "$sid" State)" = "active" ] || continue
        [ "$(prop "$sid" LockedHint)" != "yes" ] || continue
        [ -S "/run/user/$uid/bus" ] || continue

        ms="$(idle_ms "$user" "$uid")"
        echo "$ms" | grep -Eq '^[0-9]+$' || continue

		log "idle: session=$sid user=$user idle_ms=$ms"

        if [ "$ms" -ge "$LIMIT_MS" ]; then
            log "idle limit reached: session=$sid user=$user idle_ms=$ms; locking"
            loginctl lock-session "$sid"
            sleep "$VERIFY_SEC"

            if [ "$(prop "$sid" LockedHint)" != "yes" ]; then
                log "lock failed: session=$sid user=$user; terminating"
                loginctl terminate-session "$sid"
				sleep 2
				switch_to_gdm_greeter
            fi
        fi
    done

    sleep "$CHECK_SEC"
done
