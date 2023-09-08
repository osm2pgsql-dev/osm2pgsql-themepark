#!/bin/bash
#
#  download-and-import.sh DIR DB DATASET TABLE
#
#  DIR     - Download directory
#  DB      - Database (database name or postgres: URI)
#  DATASET - Dataset to download and import
#  TABLE   - Table name
#
#  Available datasets are:
#  * coastlines
#  * continents
#  * oceans
#
#  Download and import OSM data from https://osmdata.openstreetmap.de/
#

set -euo pipefail

if [ "$#" -lt 4 ]; then
    echo "Usage: download-and-import.sh DIR DB DATASET TABLE"
    echo "Datasets: coastlines continents oceans"
    exit 2
fi

DIR="$1"
DB="$2"
DATASET="$3"
TABLE="$4"

download() {
    local layer="$1"
    wget --quiet -N "https://osmdata.openstreetmap.de/download/$layer.zip"
}

download_dataset() {
    local dataset="$1"

    case "$dataset" in
        oceans)
            download water-polygons-split-3857
            download simplified-water-polygons-split-3857
            ;;
        continents)
            download land-polygons-split-3857
            download simplified-land-polygons-complete-3857
            ;;
        coastlines)
            download coastlines-split-3857
            ;;
        *)
            echo "Unknown dataset ${dataset}"
            exit 1
            ;;
    esac
}

import() {
    local db="$1"
    local layer="$2"
    local file="$3"
    local inlayer="$4"

    ogr2ogr -f PostgreSQL "PG:dbname=$db" -overwrite -nln "$layer" \
        -lco GEOMETRY_NAME=geom \
        -lco FID=id \
        -sql 'select "_ogr_geometry_" from '"$inlayer" \
        "/vsizip/$file.zip/$file"

    psql --quiet -d "$DB" -c "ANALYZE $layer;"
}

import_dataset() {
    local dataset="$1"
    local db="$2"
    local table="$3"

    case "$dataset" in
        oceans)
            import "$db" "${table}_low" simplified-water-polygons-split-3857 simplified_water_polygons
            import "$db" "${table}" water-polygons-split-3857 water_polygons
            ;;
        continents)
            import "$db" "${table}_low" continents_low simplified-land-polygons-complete-3857 simplified_land_polygons
            import "$db" "${table}" continents land-polygons-split-3857 land_polygons
            ;;
        coastlines)
            import "$db" "${table}" coastlines-split-3857 lines
            ;;
        *)
            echo "Unknown dataset ${dataset}"
            exit 1
            ;;
    esac
}

cd "$DIR"
echo "Downloading files..."
download_dataset "$DATASET"
echo "Importing..."
import_dataset "$DATASET" "$DB" "$TABLE"

echo "Done."

