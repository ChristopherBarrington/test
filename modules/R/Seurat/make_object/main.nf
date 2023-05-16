process make_object {
	tag "$tag"

	cpus 1
	memory '4GB'
	time '1h'

	input:
		val opt
		val tag
		path 'assays/?.rds'
		val assay_names
		path 'misc/?.rds'
		val misc_names
		val project

	output:
		val opt, emit: opt
		path 'task.yaml', emit: task
		path 'versions.yaml', emit: versions
		path 'seurat.rds', emit: seurat

	script:
		assay_names = assay_names.join(',')
		misc_names = misc_names.join(',')
		template workflow.stubRun ? 'stub.sh' : 'main.Rscript'
}
