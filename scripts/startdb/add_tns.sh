#!/bin/bash
# Append PDBMBDS alias to tnsnames.ora if not already present
# Also clean up any duplicate FREEPDB1 entries left from previous runs
TNSFILE=/opt/oracle/product/26ai/dbhomeFree/network/admin/tnsnames.ora

# Remove duplicate FREEPDB1 block (HOST = localhost) if present, keeping Oracle's default one (HOST=)
# The duplicate block starts with "FREEPDB1 =" after the EXTPROC block and has HOST = localhost
if grep -c "^FREEPDB1" "$TNSFILE" 2>/dev/null | grep -q "^[2-9]"; then
  # Use awk to keep only the first FREEPDB1 block
  awk '
    BEGIN { seen_freepdb1=0 }
    /^FREEPDB1[[:space:]]*=/ {
      seen_freepdb1++
      if (seen_freepdb1 > 1) { skip=1; next }
    }
    skip && /^[A-Z]/ && !/^FREEPDB1/ { skip=0 }
    skip && /^$/ { next }
    !skip { print }
  ' "$TNSFILE" > "${TNSFILE}.tmp" && mv "${TNSFILE}.tmp" "$TNSFILE"
  echo "Duplicate FREEPDB1 entry removed."
fi

# Add PDBMBDS alias if not present
if ! grep -q "^PDBMBDS" "$TNSFILE" 2>/dev/null; then
cat >> "$TNSFILE" << 'EOF'

PDBMBDS =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = FREEPDB1)
    )
  )
EOF
echo "TNS alias PDBMBDS added."
else
  echo "TNS alias PDBMBDS already present."
fi
