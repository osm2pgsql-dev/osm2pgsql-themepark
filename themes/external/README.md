
# Theme "external"

This theme contains some layers not generated directly from OSM data but
created from external sources, specifically data that can be downloaded from
https://osmdata.openstreetmap.de/ .

Use the script `download-and-import.sh` in this directory like this:

```{sh}
./download-and-import.sh DIR DB DATASET TABLE
```

So to download the oceans data into the `/tmp` directory and then import into
a database called `osm` into a table called `ocean`, call it like this:

```{sh}
./download-and-import.sh /tmp osm oceans ocean
```

## Datasets

### "oceans"

Layers `oceans` (zoom 10 and above) and `oceans_low` (zoom 0 to 9).

### "continents"

Layers `continents` (zoom 10 and above) and `continents_low` (zoom 0 to 9).

### "coastlines"

Layer `coastlines`.

