#!/bin/sh
# Test adapter: simulate an early primary failure; use real engine for staging.
set -eu
for argument in "$@"; do
    case "$argument" in
        *:/stage.sh:ro)
            if [ "${SIMULATE_STAGING_FAILURE:-False}" = True ]; then
                echo 'Simulated staging failure (42)' >&2
                exit 42
            fi ;;
        *:/workspace)
            echo 'Simulated primary preparation failure (37)' >&2
            exit 37 ;;
    esac
done
exec "${REAL_CONTAINER_ENGINE:-podman}" "$@"