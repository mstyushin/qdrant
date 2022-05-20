#!/usr/bin/env bash
set -Eeo pipefail


declare -g QDRANT_INITIALIZED
if [[ -f /qdrant/storage/aliases/data.json ]]; then
    QDRANT_INITIALIZED='true'
fi

if [ -z "$QDRANT_INITIALIZED" ]; then
    echo
    echo "starting tmp qdrant instance"
    echo
    "$@" & &> /dev/null
    # TODO: dirty hack to make sure qdrant is fully up&running
    sleep 1

    for f in $(ls /init.d/*); do
        case "${f}" in
            *.sh)
                if [[ -x ${f} ]]; then
                    echo "init: running ${f}"
                    ${f}
                    echo
                fi
                ;;
            *)  echo "init: ignoring ${f}" ;;
         esac
    done

    echo
    echo "stopping tmp qdrant instance"
    echo
    kill %1
    sleep 1
fi

echo
echo "starting qdrant"
echo
if [[ $(id -u) -eq '0' ]]; then
	find /qdrant \! -user qdrant -exec chown -R qdrant:qdrant '{}' +
	exec gosu qdrant "$BASH_SOURCE" "$@"
fi

exec "$@"
