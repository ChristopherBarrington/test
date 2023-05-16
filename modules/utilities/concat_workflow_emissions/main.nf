// concatenate the same emitted channel from multiple workflows

def concat_workflow_emissions(channel_list, key) {
	if(channel_list.size() == 0)
		return(null)

	def ch_out = channel_list.first().out.(key)
	channel_list.tail().each{ch_out=ch_out.concat(it.out.(key))}
	ch_out
}

