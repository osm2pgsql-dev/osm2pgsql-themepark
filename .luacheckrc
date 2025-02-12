--
--  Configuration for luacheck
--

unused_args = false
unused_secondaries = false

stds.osm2pgsql = {
    read_globals = {
        osm2pgsql = {
            fields = {
                process_node = {
                    read_only = false
                },
                process_way = {
                    read_only = false
                },
                process_relation = {
                    read_only = false
                },
                process_untagged_node = {
                    read_only = false
                },
                process_untagged_way = {
                    read_only = false
                },
                process_untagged_relation = {
                    read_only = false
                },
                select_relation_members = {
                    read_only = false
                },
                process_gen = {
                    read_only = false
                },
                after_nodes = {
                    read_only = false
                },
                after_ways = {
                    read_only = false
                },
                after_relations = {
                    read_only = false
                },
            },
            other_fields = true,
        }
    }
}

std = 'min+osm2pgsql+busted'

