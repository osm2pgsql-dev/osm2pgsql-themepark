
# Theme "core"

The topics in this theme are building blocks, not meant to be used on their
own, but together with other themes.

## Topic 'clean-tags'

### Description

This topic adds processing callbacks for nodes, ways, and relations. All tags
are checked against a builtin list of tags and matching tags are removed. If,
after removing the tags, no tags are left, processing is stopped for this
object.

This is used to clear out tags such as `created_by`, `note`, etc. that are
internal to the OSM project and usually not interesting for most data users.

You have to add this topic before other topics.

### Tables

This topic doesn't add any output tables.

### Configuration

* `delete_keys` - An array of key patterns. Tags matching these patterns will
  be removed. If this is not set, an internal list of patterns is used.
  The key pattern can either be the key itself (example: `source`) or a key
  prefix with `*` suffix (example: `source:*`).

### Attributes

This topic doesn't set any attributes.

## Topic 'elevation'

### Description

Get the elevation data from the `ele` tag. Elevation in meter (something like
`1200`, `1200m`, ...) or feet (`400ft`, ...) is understood.

### Tables

This topic doesn't add any output tables.

### Configuration

There are no configuration options for this topic.

### Attributes

If a valid elevation tag is found, the attributes `core.ele_m` and
`core.ele_ft` are added and contain the elevation in meters and feet,
respectively, as a number, rounded to the nearest integer.

## Topic 'extract'

### Description

Restrict imported data to a bounding box or polygon using the Locator feature
of osm2pgsql. Use this topic *before* any other topics you want to restrict.
Objects intersecting the locator area are kept, all others are discarded. For
closed ways the area of the polygon is used for intersection, for unclosed ways
the linestring. For relations that can be turned into multipolygons, the
multipolygon is used, otherwise all node and way members of the polygon are
checked as point and linestring features, respectively.

Geometries are *not* clipped to the locator area.

This only works in osm2pgsql version 2.2.0 and above.

### Tables

This topic doesn't add any output tables.

### Configuration

* `locator`: Set to an existing osm2pgsql.Locator (optional, if not set, a new
  locator will be created).
* `bbox`: A table with the bounding box to be added to the locator. The table
  must contain four elements, in that order: min lon, min lat, max lon, max
  lat.

### Attributes

No attributes are added.


## Topic 'layer'

### Description

Get the layer from the `layer` tag as integer. Defaults to 0 if not set or
of a wrong format.

### Tables

This topic doesn't add any output tables.

### Configuration

There are no configuration options for this topic.

### Attributes

The attributes `core.layer` is set to an integer between -7 and 7.

## Topic 'name-all'

### Description

Add all names found in the tags to a JSONB column.

### Tables

This topic doesn't add any output tables. It registers a name column on
existing tables.

### Configuration

* `column`: The name of the output column. Default: `name`.

### Attributes

This topic doesn't set any attributes.

## Topic 'name-list'

### Description

Get names from several tags (such as `name` or `name:ar`) and put them in
corresponding output columns.

### Tables

This topic doesn't add any output tables. It registers a name column on
existing tables.

### Configuration

* `keys`: A list of tag keys, usually something like `{'name', 'name:it'}`.
   Default: `name`. Corresponding output columns will be created with all
   non-alphabetic characters replaced by `_`.

### Attributes

This topic doesn't set any attributes.

## Topic 'name-single'

### Description

Get a name from a single tag (such as `name` or `name:ar`) and put it in an
output column.

### Tables

This topic doesn't add any output tables. It registers a name column on
existing tables.

### Configuration

* `key`: The key with the name, usually something like `name:it`. Default:
  `name`.
* `column`: The name of the output column. Default: `name`.

### Attributes

This topic doesn't set any attributes.

