#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
UCM_ROOT="$ROOT/system_files/usr/share/alsa/ucm2"
SECTION_PATTERN='^[[:space:]]*(Section(Device|UseCase|Modifier))\."([^"]+)"[[:space:]]*\{'
failed=0
config_count=0
section_count=0

while IFS= read -r -d '' config; do
	declare -A seen=()
	line_number=0
	config_count=$((config_count + 1))

	while IFS= read -r line || [[ -n "$line" ]]; do
		line_number=$((line_number + 1))
		if [[ $line =~ $SECTION_PATTERN ]]; then
			section_type="${BASH_REMATCH[1]}"
			section_name="${BASH_REMATCH[3]}"
			section_key="$section_type/$section_name"
			section_count=$((section_count + 1))

			if [[ -n "${seen[$section_key]+x}" ]]; then
				printf 'duplicate %s."%s" in %s:%d (first declared on line %s)\n' \
					"$section_type" "$section_name" "${config#"$ROOT"/}" \
					"$line_number" "${seen[$section_key]}" >&2
				failed=1
			else
				seen[$section_key]="$line_number"
			fi
		fi
	done <"$config"
done < <(find "$UCM_ROOT" -type f -name '*.conf' -print0 | sort -z)

if ((config_count == 0 || section_count == 0)); then
	printf 'no ALSA UCM sections found under %s\n' "$UCM_ROOT" >&2
	exit 1
fi

if ((failed)); then
	exit 1
fi

printf 'ALSA UCM duplicate section test passed (%d sections in %d files)\n' \
	"$section_count" "$config_count"
