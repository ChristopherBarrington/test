// remove keys from a map

def remove_keys_from_map(x, keys) {
	keys = keys.class==String ? [keys] : keys
	def keys_to_keep = x.keySet().findAll{!keys.contains(it)}
	x.subMap(keys_to_keep)
}
