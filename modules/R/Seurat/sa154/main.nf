process sa154 {
	tag "$tag"

	executor 'slurm'
	cpus 8
	memory '60GB'
	time '48h'

	input:
		val opt
		val tag
		path 'input_seurat.rds'
		path 'cell_ids.tsv'
		path 'cell_cycle_genes.yaml'

	output:
		val opt, emit: opt
		path 'task.yaml', emit: task
		path 'versions.yaml', emit: versions
		path 'seurat.rds', emit: seurat

	script:
		template workflow.stubRun ? 'stub.sh' : 'main.Rscript'
}
