# The default PyroScope configuration script
#
# For details, see https://pyrocore.readthedocs.io/en/latest/setup.html
#

def _custom_fields():
    """ Yield custom field definitions.
    """
    # Import some commonly needed modules
    import os
    from pyrocore.torrent import engine, matching
    from pyrocore.util import fmt

    # PUT CUSTOM FIELD CODE HERE

    # Add rTorrent attributes not available by default
    def get_tracker_field(obj, name, aggregator=sum):
	"Get an aggregated tracker field."
	return aggregator(obj._engine._rpc.t.multicall(obj._fields["hash"], 0, "t.%s=" % name)[0])

    yield engine.OnDemandField(int, "is_partially_done", "is partially done", matcher=matching.FloatFilter)
    yield engine.OnDemandField(int, "selected_size_bytes", "size of selected data", matcher=matching.FloatFilter)
    yield engine.OnDemandField(int, "peers_connected", "number of connected peers", matcher=matching.FloatFilter)
    yield engine.DynamicField(int, "downloaders", "number of completed downloads", matcher=matching.FloatFilter,
	accessor=lambda o: get_tracker_field(o, "get_scrape_downloaded"))
    yield engine.DynamicField(int, "seeds", "number of seeds", matcher=matching.FloatFilter,
	accessor=lambda o: get_tracker_field(o, "get_scrape_complete"))
    yield engine.DynamicField(int, "leeches", "number of leeches", matcher=matching.FloatFilter,
	accessor=lambda o: get_tracker_field(o, "get_scrape_incomplete"))
    yield engine.DynamicField(engine.untyped, "lastscraped", "time of last scrape", matcher=matching.TimeFilter,
	accessor=lambda o: get_tracker_field(o, "get_scrape_time_last", max),
	formatter=lambda dt: fmt.human_duration(float(dt), precision=2, short=True))

    # Add peer attributes not available by default
    def get_peer_data(obj, name, aggregator=None):
	"Get some peer data via a multicall."
	aggregator = aggregator or (lambda _: _)
	result = obj._engine._rpc.p.multicall(obj._fields["hash"], 0, "p.%s=" % name)
	return aggregator([i[0] for i in result])

    yield engine.DynamicField(set, "peers_ip", "list of IP addresses for connected peers",
	matcher=matching.TaggedAsFilter, formatter=", ".join,
	accessor=lambda o: set(get_peer_data(o, "address")))

# Register our factory with the system
custom_field_factories.append(_custom_fields)
