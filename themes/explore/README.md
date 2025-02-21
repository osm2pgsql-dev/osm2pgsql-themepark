
# Theme `explore`

OpenStreetMap contains an insane amount of complex data. If you want to use
some of that data a first step is often to explore what's there, filter out the
stuff that looks interesting, create some experimental maps, figure out what's
useable and how. The topics in this theme are meant as starting points for such
an exploration, they are intended for advanced OSM users.

The data generated is intended to be used with an interactive tool such as QGIS
to quickly display what's there in different ways.

Some of these topics import quite a lot of data and do extensive
post-processing, try with a smaller extract before you run them on the planet
file.

For some details on the contents of the generated database see the source
code of the config file.

## Naming

All table names have the respective topic as prefix.

## Updates

Topics are mostly written in a way to allow updates of OSM data. But updates
might take a while, so minutely updates are not possible for all of then.
This should be improved upon.

## Postprocessing

Use `osm2pgsql-gen` with the respective config file to run SQL commands that do
some postprocessing on the imported data. Without that some tables and/or
columns will not be filled with data.

## Optional Pre-Filtering

For some topics it can make sense to pre-filter the OSM data, so that
processing with osm2pgsql is faster. This is entirely optional. Each topic will
show a command line using [Osmium](https://osmcode.org/osmium-tool/) that does
this pre-filtering.

## QGIS Config

The `qgis` directory contains QGIS config files for each of the themes. They
all use the [database
service](https://www.postgresql.org/docs/current/libpq-pgservice.html)
`explore`. Create a file `.pg_service.conf` in your home directory (if it is
not already there) and add an entry like this:

```
[explore]
host=localhost
port=5432
dbname=explore
user=USERNAME
password=PASSWORD
```

## Topic: Admin Boundaries

Everything related to administrative boundaries.

Pre-Filtering:

```
osmium tags-filter -o admin_boundaries.osm.pbf DATA.osm.pbf \
    wr/boundary=administrative,disputed
```

## Topic: Coastline

Explore coastline tagging. Everything tagged `natural=coastline`.

Coastline ways are shown, with details if zoomed in. Pseudo-coastlines along
the 180° meridian and the South Pole that have special tagging are also shown.
Coastlines can only be tagged on ways. Nodes and relations with tag
`natural=coastline` are shown as errors. Coastline (self-)intersections and
open ends are shown as errors as well.

Pre-Filtering:

```
osmium tags-filter -o coastline.osm.pbf DATA.osm.pbf \
    natural=coastline
```

## Topic: Postcodes

Explore postcodes in OSM, on POIs, buildings, and from postcode boundaries.

Also generates postcode areas from points using convex hull and Voronoi
decomposition.

Pre-Filtering:

```
osmium tags-filter -o postcodes.osm.pbf DATA.osm.pbf \
    'addr:*' r/postal_code
```

## Topic: Protected Areas

Areas protected for nature conservancy such as national parks. There is a wide
variety of types of such areas found around the world and also quite varied
tagging.

Pre-Filtering:

```
osmium tags-filter -o protected_areas.osm.pbf DATA.osm.pbf \
    boundary=protected_area,national_park,water_protection_area \
    leisure=nature_reserve \
    protect_class protection_title short_protection_title
```

## Topic: Restrictions

Turn restrictions (relations tagged `type=restrictions`) for road navigation.

Pre-Filtering:

```
osmium tags-filter -o restrictions.osm.pbf DATA.osm.pbf \
    w/highway w/amenity=parking r/type=restriction
```

