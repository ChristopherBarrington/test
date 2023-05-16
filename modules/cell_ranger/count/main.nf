process count {
	tag "$tag"

	executor 'slurm'
	cpus 32
	memory '250GB'
	time '3d'

	input:
		val opt
		val tag
		val sample
		path 'fastq_path_?'
		path 'index_path'

	output:
		val opt, emit: opt
		path 'task.yaml', emit: task
		path 'versions.yaml', emit: versions
		path 'output/outs', emit: quantification_path
		path 'web_summary.html', emit: cell_ranger_report

	script:
		template workflow.stubRun ? 'stub.sh' : 'main.sh'
}
