#!/usr/bin/env bash
set -euo pipefail

DOCKER_TAR="$1"
OUT_DIR="$2"

mkdir -p "$OUT_DIR/tmp"
tar -xf "$DOCKER_TAR" -C "$OUT_DIR/tmp"

mkdir -p "$OUT_DIR/blobs/sha256"

CONFIG_FILE=$(jq -r '.[0].Config' "$OUT_DIR/tmp/manifest.json")
CONFIG_PATH="$OUT_DIR/tmp/$CONFIG_FILE"
CONFIG_HASH=$(sha256sum "$CONFIG_PATH" | awk '{print $1}')

cp "$CONFIG_PATH" "$OUT_DIR/blobs/sha256/$CONFIG_HASH"
CONFIG_SIZE=$(stat -c%s "$OUT_DIR/blobs/sha256/$CONFIG_HASH")

LAYER_DESCRIPTORS=""
LAYERS=$(jq -r '.[0].Layers[]' "$OUT_DIR/tmp/manifest.json")
FIRST=1
for layer in $LAYERS; do
  LAYER_TAR="$OUT_DIR/tmp/$layer"
  LAYER_HASH=$(sha256sum "$LAYER_TAR" | awk '{print $1}')
  
  cp "$LAYER_TAR" "$OUT_DIR/blobs/sha256/$LAYER_HASH"
  LAYER_SIZE=$(stat -c%s "$OUT_DIR/blobs/sha256/$LAYER_HASH")
  
  if [ $FIRST -eq 0 ]; then
    LAYER_DESCRIPTORS="$LAYER_DESCRIPTORS,"
  fi
  FIRST=0
  
  LAYER_DESCRIPTORS="$LAYER_DESCRIPTORS
    {
      \"mediaType\": \"application/vnd.oci.image.layer.v1.tar\",
      \"digest\": \"sha256:$LAYER_HASH\",
      \"size\": $LAYER_SIZE
    }"
done

jq -n \
  --arg configHash "$CONFIG_HASH" \
  --argjson configSize "$CONFIG_SIZE" \
  --argjson layers "[$LAYER_DESCRIPTORS]" \
  '{
    schemaVersion: 2,
    mediaType: "application/vnd.oci.image.manifest.v1+json",
    config: {
      mediaType: "application/vnd.oci.image.config.v1+json",
      digest: ("sha256:" + $configHash),
      size: $configSize
    },
    layers: $layers
  }' > "$OUT_DIR/tmp/oci-manifest.json"

MANIFEST_HASH=$(sha256sum "$OUT_DIR/tmp/oci-manifest.json" | awk '{print $1}')
cp "$OUT_DIR/tmp/oci-manifest.json" "$OUT_DIR/blobs/sha256/$MANIFEST_HASH"
MANIFEST_SIZE=$(stat -c%s "$OUT_DIR/blobs/sha256/$MANIFEST_HASH")

cat > "$OUT_DIR/oci-layout" <<EOF
{"imageLayoutVersion":"1.0.0"}
EOF

cat > "$OUT_DIR/index.json" <<EOF
{
  "schemaVersion": 2,
  "manifests": [
    {
      "mediaType": "application/vnd.oci.image.manifest.v1+json",
      "digest": "sha256:$MANIFEST_HASH",
      "size": $MANIFEST_SIZE
    }
  ]
}
EOF

