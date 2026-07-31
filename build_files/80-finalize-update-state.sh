#!/bin/bash
set -euxo pipefail

ldconfig -X
test -s /etc/ld.so.cache
ldconfig -p >/dev/null
