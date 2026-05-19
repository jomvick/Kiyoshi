#!/bin/bash
INSTALL_DIR="/usr/share/kiyoshi"
export LD_LIBRARY_PATH="$INSTALL_DIR/lib:$LD_LIBRARY_PATH"
exec "$INSTALL_DIR/kiyoshi" "$@"
