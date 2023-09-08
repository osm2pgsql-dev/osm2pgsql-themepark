
# Osm2pgsql Themepark

https://osm2pgsql.org/themepark/

THIS IS BETA SOFTWARE. EVERYTHING IN HERE IS SUBJECT TO CHANGE.

This is a framework for creating [osm2pgsql](https://osm2pgsql.org/)
configurations assembled from many building blocks. Some of those blocks are
provided in this repository, others you can add yourself. This way you don't
have to start with a new configuration from scratch every time you build and
style a new map. Instead you take those existing blocks that suit your needs
and add new ones for those things that make your map special.

This framework makes use of the [flex
output](https://osm2pgsql.org/doc/manual.html#the-flex-output) and it needs at
least version 1.9.2 of osm2pgsql. See [the osm2pgsql installation
documentation](https://osm2pgsql.org/doc/install.html) for how to install
osm2pgsql.

When running osm2pgsql you'll always need the command line parameters `-O flex
-S CONFIG.lua`. `CONFIG.lua` is the configuration file you are writing that
makes use of this framework. Some example config files are provided in the
`config` directory. Read the [User
Manual](https://osm2pgsql.org/themepark/users-manual.html) for instructions on
how to create one yourself.

## Plugins

The framework has support for plugins adding some functionality. They are in
the `lua/themepark/plugins` directory.

Available plugins are:
* `taginfo`: For creating [Taginfo project files]().
* `tilekiln`: For creating a config file for the
  [Tilekiln](https://github.com/pnorman/tilekiln) tile server.
* `t-rex`: For creating a config file for the
  [T-Rex](https://t-rex.tileserver.ch/) tile server.

## Themes

Themes provide building blocks for map data transformations. They usually
contain some common code plus several *topics*; each topic usually provides the
code to create one or more database tables which can then be used as a basis
for a map layer.

You can write your own themes and topics, read the [Authors
Manual](https://osm2pgsql.org/themepark/authors-manual.html) for details.

Several themes are available in this repository to get you going and support
some common use cases.

### Theme `basic`

This theme contains some basic layers for testing and debugging. It can
also be used as a jumping-off point for your own theme creation.

[More...](themes/basic/README.md)

### Theme `core`

The topics in this theme are not meant to be used on their own, but they
provide common transformations which can be used with other themes and
topics. This includes functionality for handling *names*.

[More...](themes/core/README.md)

### Theme `experimental`

These are some experimental layers. Use at your own risk.

[More...](themes/experimental/README.md)

### Theme `external`

This theme contains some layers not generated directly from OSM data but
created from external sources, specifically data that can be downloaded from
https://osmdata.openstreetmap.de/ .

[More...](themes/external/README.md)

### Theme `shortbread_v1`

Implements the [Shortbread (v1.0)
schema](https://shortbread-tiles.org/schema/1.0). Data for low zoom levels
are not generated.

[More...](themes/shortbread_v1/README.md)

### Theme `shortbread_v1_gen`

Implements the [Shortbread (v1.0)
schema](https://shortbread-tiles.org/schema/1.0) with automated
generalization for low zoom levels. This needs the experimental `osm2pgsql-gen`
command provided with newer osm2pgsql versions.

[More...](themes/shortbread_v1_gen/README.md)

## License

Copyright 2023 Jochen Topf <jochen@topf.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Author

This framework is written and maintained by Jochen Topf (jochen@topf.org).

