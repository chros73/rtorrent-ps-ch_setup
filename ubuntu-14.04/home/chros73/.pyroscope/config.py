# The default PyroScope configuration script
#
# For details, see https://pyrocore.readthedocs.io/en/latest/setup.html
# and https://pyrocore.readthedocs.io/en/latest/custom.html#defining-custom-fields
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
	accessor=lambda o: get_tracker_field(o, "scrape_downloaded"))
    yield engine.DynamicField(int, "seeds", "number of seeds", matcher=matching.FloatFilter,
	accessor=lambda o: get_tracker_field(o, "scrape_complete"))
    yield engine.DynamicField(int, "leeches", "number of leeches", matcher=matching.FloatFilter,
	accessor=lambda o: get_tracker_field(o, "scrape_incomplete"))
    yield engine.DynamicField(engine.untyped, "lastscraped", "time of last scrape", matcher=matching.TimeFilter,
	accessor=lambda o: get_tracker_field(o, "scrape_time_last", max),
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


    # Add file checkers
    def has_nfo(obj):
	"Check for .NFO file."
	pathname = obj.path
	if pathname and os.path.isdir(pathname):
	    return any(i.lower().endswith(".nfo") for i in os.listdir(pathname))
	else:
	    return False if pathname else None

    def has_thumb(obj):
	"Check for folder.jpg file."
	pathname = obj.path
	if pathname and os.path.isdir(pathname):
	    return any(i.lower() == "folder.jpg" for i in os.listdir(pathname))
	else:
	    return False if pathname else None

    yield engine.DynamicField(engine.untyped, "has_nfo", "does download have a .NFO file?",
	matcher=matching.BoolFilter, accessor=has_nfo,
	formatter=lambda val: "NFO" if val else "!DTA" if val is None else "----")
    yield engine.DynamicField(engine.untyped, "has_thumb", "does download have a folder.jpg file?",
	matcher=matching.BoolFilter, accessor=has_thumb,
	formatter=lambda val: "THMB" if val else "!DTA" if val is None else "----")


    # Fields for partial downloads
    def partial_info(obj, name):
	"Helper for partial download info"
	try:
	    return obj._fields[name]
	except KeyError:
	    f_attr = ["get_completed_chunks", "get_size_chunks", "get_range_first", "get_range_second"]
	    chunk_size = obj.fetch("chunk_size")
	    prev_chunk = -1
	    size, completed, chunks = 0, 0, 0
	    for f in obj._get_files(f_attr):
		if f.prio: # selected?
		    shared = int(f.range_first == prev_chunk)
		    size += f.size
		    completed += f.completed_chunks - shared
		    chunks += f.size_chunks - shared
		    prev_chunk = f.range_second - 1

	    obj._fields["partial_size"] = size
	    obj._fields["partial_missing"] = (chunks - completed) * chunk_size
	    obj._fields["partial_done"] = 100.0 * completed / chunks if chunks else 0.0

	    return obj._fields[name]

    yield engine.DynamicField(int, "partial_size", "bytes selected for download",
	matcher=matching.ByteSizeFilter,
	accessor=lambda o: partial_info(o, "partial_size"))
    yield engine.DynamicField(int, "partial_missing", "bytes missing from selected chunks",
	matcher=matching.ByteSizeFilter,
	accessor=lambda o: partial_info(o, "partial_missing"))
    yield engine.DynamicField(float, "partial_done", "percent complete of selected chunks",
	matcher=matching.FloatFilter,
	accessor=lambda o: partial_info(o, "partial_done"))


    # Map name field to TV series name, if applicable, else an empty string
    from pyrocore.util import traits

    def tv_mapper(obj, name, templ):
	"Helper for TV name mapping"
	try:
	    return obj._fields[name]
	except KeyError:
	    itemname = obj.name
	    result = ""

	    kind, info = traits.name_trait(itemname, add_info=True)
	    if kind == "tv":
		try:
		    info["show"] = ' '.join([i.capitalize() for i in info["show"].replace('.',' ').replace('_',' ').split()])
		    result = templ % info
		except KeyError, exc:
		    #print exc
		    pass

	    obj._fields[name] = result
	    return result

    yield engine.DynamicField(fmt.to_unicode, "tv_series", "series name of a TV item",
	matcher=matching.PatternFilter, accessor= lambda o: tv_mapper(o, "tv_series", "%(show)s"))
    yield engine.DynamicField(fmt.to_unicode, "tv_episode", "series name and episode number of a TV item",
	matcher=matching.PatternFilter, accessor= lambda o: tv_mapper(o, "tv_episode", "%(show)s.S%(season)sE%(episode)s"))


    # Disk space check
    def has_room(obj):
	"Check disk space."
	pathname = obj.path
	if pathname and not os.path.exists(pathname):
	    pathname = os.path.dirname(pathname)
	if pathname and os.path.exists(pathname):
	    stats = os.statvfs(pathname)
	    return (stats.f_bavail * stats.f_frsize - int(diskspace_threshold_mb) * 1024**2
		> obj.size * (1.0 - obj.done / 100.0))
	else:
	    return None

    yield engine.DynamicField(engine.untyped, "has_room",
	"check whether the download will fit on its target device",
	matcher=matching.BoolFilter, accessor=has_room,
	formatter=lambda val: "OK" if val else "??" if val is None else "NO")
    globals().setdefault("diskspace_threshold_mb", "500")


# Register our factory with the system
custom_field_factories.append(_custom_fields)
