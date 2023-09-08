
# Theme "basic"

This theme contains some basic layers for testing and debugging. It can
also be used as a jumping-off point for your own theme creation.

## Topics

### "generic-boundaries"

Creates one table "boundaries" with all relations tagged `type=boundary` or
`type=multipolygon` and a `boundary` tag. The boundaries are contained as
MultiLineString geometries.

### "generic-lines"

Creates one table "lines" with all non-area way geometries.

### "generic-points"

Creates one table "points" with all node geometries (if the node has tags).

### "generic-polygons"

Creates one table "polygons" with all (multi)polygon geometries from closed
ways and multipolygon relations.

### "generic-routes"

Creates one table "routes" with all relations tagged `type=route` as
multilinestrings.

### "nwr"

The "nwr" topic will create three tables called `nodes`, `ways`, and
`relations`.

* All tags are in a JSONB column `tags`.
* For `ways` table: List of node ids is in `nodes` column of type `int8[]`
  (integer array).
* For `relations` table: List of members is in `members` JSONB column.
* The `geom` column contains the geometry, for nodes this is a Point, for
  ways a LineString, and for relations a GeometryCollection containing all
  Point and LineString geometries of the node and way members. The geometry
  of relation members is not available.

