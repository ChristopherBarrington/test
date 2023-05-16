// -------------------------------------------------------------------------------------------------
// import any java/groovy libraries as required
// -------------------------------------------------------------------------------------------------

import java.nio.file.Paths

// -------------------------------------------------------------------------------------------------
// specify modules relevant to this workflow
// -------------------------------------------------------------------------------------------------

include { convert_gtf_to_granges } from '../../../modules/R/GenomicRanges/convert_gtf_to_granges'

include { make_assay as make_rna_assay }      from '../../../modules/R/Seurat/make_assay'
include { make_object as make_seurat_object } from '../../../modules/R/Seurat/make_object'
include { write_10x_counts_matrices }         from '../../../modules/R/Seurat/write_10x_counts_matrices'

include { make_chromatin_assay } from '../../../modules/R/Signac/make_chromatin_assay'

include { check_for_matching_key_values }     from '../../../modules/utilities/check_for_matching_key_values'
include { concat_workflow_emissions }         from '../../../modules/utilities/concat_workflow_emissions'
include { concatenate_maps_list }             from '../../../modules/utilities/concatenate_maps_list'
include { merge_metadata_and_process_output } from '../../../modules/utilities/merge_metadata_and_process_output'
include { merge_process_emissions }           from '../../../modules/utilities/merge_process_emissions'
include { rename_map_keys }                   from '../../../modules/utilities/rename_map_keys'

include { merge_yaml as merge_software_versions } from '../../../modules/yq/merge_yaml'
include { merge_yaml as merge_task_properties }   from '../../../modules/yq/merge_yaml'

// -------------------------------------------------------------------------------------------------
// define the workflow
// -------------------------------------------------------------------------------------------------

workflow cell_ranger_arc {

	take:
		stage_parameters

	main:
		// -------------------------------------------------------------------------------------------------
		// make GRanges objects for gene annotations of the genomes
		// -------------------------------------------------------------------------------------------------

		// create the channels for the process to make GRanges objects using Cell Ranger ARC indexes
		stage_parameters
			.map{it.subMap(['genome', 'index path'])}
			.unique()
			.map{it + [gtf: Paths.get(it.get('index path').toString(), 'genes', 'genes.gtf.gz')]}
			.map{it + [fai: Paths.get(it.get('index path').toString(), 'fasta', 'genome.fa.fai')]}
			.dump(tag:'seurat:cell_ranger_arc:gtf_files_to_convert_to_granges', pretty:true)
			.set{gtf_files_to_convert_to_granges}

		tags      = gtf_files_to_convert_to_granges.map{it.get('genome')}
		genomes   = gtf_files_to_convert_to_granges.map{it.get('genome')}
		gtf_files = gtf_files_to_convert_to_granges.map{it.get('gtf')}
		fai_files = gtf_files_to_convert_to_granges.map{it.get('fai')}

		// make the granges rds files from gtf files
		convert_gtf_to_granges(gtf_files_to_convert_to_granges, tags, genomes, gtf_files, fai_files)

		// make a channel of newly created GRanges rds files
		merge_process_emissions(convert_gtf_to_granges, ['opt', 'granges'])
			.map{merge_metadata_and_process_output(it)}
			.dump(tag:'seurat:cell_ranger_arc:granges_files', pretty:true)
			.set{granges_files}

		// -------------------------------------------------------------------------------------------------
		// read the 10X cell ranger matrices into an object
		// -------------------------------------------------------------------------------------------------

		// get the unique set of quantification matrices and feature identifiers' columns
		stage_parameters
			.map{[it.subMap('index path', 'quantification path'), ['accession','name']]}
			.transpose()
			.map{it.first() + [identifier:it.last()]}
			.unique()
			.map{it + ['barcoded matrix path': Paths.get(it.get('quantification path').toString(), 'filtered_feature_bc_matrix')]}
			.map{it + ['tag': it.toString().md5().take(9)]}
			// .map{it + ['tag': it.get('quantification path').toString().takeRight(33)]}
			.dump(tag:'seurat:cell_ranger_arc:barcoded_matrices_to_read', pretty:true)
			.set{barcoded_matrices_to_read}

		// create the channels for the process to make a 10X matrix
		tags                  = barcoded_matrices_to_read.map{it.get('tag')}
		barcoded_matrix_paths = barcoded_matrices_to_read.map{it.get('barcoded matrix path')}
		identifiers           = barcoded_matrices_to_read.map{it.get('identifier')}

		// write 10x matrix of counts to rds file
		write_10x_counts_matrices(barcoded_matrices_to_read, tags, barcoded_matrix_paths, identifiers)

		// make a channel of newly created counts matrices
		merge_process_emissions(write_10x_counts_matrices, ['opt', 'counts_matrices', 'features'])
			.map{merge_metadata_and_process_output(it)}
			.dump(tag:'seurat:cell_ranger_arc:barcoded_matrices', pretty:true)
			.set{barcoded_matrices}

		// -------------------------------------------------------------------------------------------------
		// make an RNA assay
		// -------------------------------------------------------------------------------------------------

		// create the channels for the process to make an RNA assay
		tags            = barcoded_matrices.map{it.get('tag')}
		counts_matrices = barcoded_matrices.map{it.get('counts_matrices')}

		// write rna assay to rds file
		make_rna_assay(barcoded_matrices, tags, 'Gene Expression', counts_matrices)

		// make a channel of newly created rna assays
		merge_process_emissions(make_rna_assay, ['opt', 'assay'])
			.map{merge_metadata_and_process_output(it)}
			.map{rename_map_keys(it, 'assay', sprintf('rna_assay_by_%s', it.get('identifier')))}
			.dump(tag:'seurat:cell_ranger_arc:rna_assays_branched', pretty:true)
			.branch({
				identifier = it.get('identifier')
				accession: identifier == 'accession'
				name: identifier == 'name'})
			.set{rna_assays_branched}

		rna_assays_branched.accession
			.combine(rna_assays_branched.name)
			.filter{check_for_matching_key_values(it, 'quantification path')}
			.map{concatenate_maps_list(it)}
			.map{it.subMap(['quantification path', 'rna_assay_by_accession', 'rna_assay_by_name'])}
			.dump(tag:'seurat:cell_ranger_arc:rna_assays', pretty:true)
			.set{rna_assays}

		// -------------------------------------------------------------------------------------------------
		// make an ATAC assay
		// -------------------------------------------------------------------------------------------------

		// create the channels for the process to make a chromatin assay
		barcoded_matrices
			.filter{it.get('identifier') == 'accession'}
			.combine(granges_files.map{it.subMap(['index path','granges'])})
			.filter{check_for_matching_key_values(it, 'index path')}
			.map{concatenate_maps_list(it)}
			.map{it.subMap(['tag', 'granges', 'counts_matrices', 'quantification path'])}
			.dump(tag:'seurat:cell_ranger_arc:chromatin_assays_to_create', pretty:true)
			.set{chromatin_assays_to_create}

		// create the channels for the process to make a chromatin assay
		tags                 = chromatin_assays_to_create.map{it.get('tag')}
		annotations          = chromatin_assays_to_create.map{it.get('granges')}
		counts_matrices      = chromatin_assays_to_create.map{it.get('counts_matrices')}
		quantification_paths = chromatin_assays_to_create.map{it.get('quantification path')}

		// write chromatin assay to rds file
		make_chromatin_assay(chromatin_assays_to_create, tags, annotations, counts_matrices, quantification_paths, 'Peaks')

		// make a channel of newly created chromatin assays
		merge_process_emissions(make_chromatin_assay, ['opt', 'assay'])
			.map{merge_metadata_and_process_output(it)}
			.map{rename_map_keys(it, 'assay', 'chromatin_assay')}
			.map{it.subMap(['quantification path', 'chromatin_assay'])}
			.dump(tag:'seurat:cell_ranger_arc:chromatin_assays', pretty:true)
			.set{chromatin_assays}

		// -------------------------------------------------------------------------------------------------
		// make a seurat object using rna and atac assays and the annotations
		// -------------------------------------------------------------------------------------------------

		// combine the annotations and rna and chromatin assays into a channel
		stage_parameters
			.combine(rna_assays)
			.combine(chromatin_assays)
			.combine(granges_files.map{it.subMap(['genome', 'index path', 'granges'])})
			.combine(barcoded_matrices.filter{it.get('identifier') == 'accession'}.map{it.subMap(['index path', 'quantification path', 'features'])})
			.filter{check_for_matching_key_values(it, 'genome')}
			.filter{check_for_matching_key_values(it, 'index path')}
			.filter{check_for_matching_key_values(it, 'quantification path')}
			.map{concatenate_maps_list(it)}
			.map{it.subMap(['unique id', 'rna_assay_by_accession', 'rna_assay_by_name', 'chromatin_assay', 'granges', 'features', 'dataset name', 'dataset id'])}
			.dump(tag:'seurat:cell_ranger_arc:seurat_objects_to_create', pretty:true)
			.set{seurat_objects_to_create}

		// create the channels for the process to make a seurat object
		tags         = seurat_objects_to_create.map{it.get('unique id')}
		assays       = seurat_objects_to_create.map{it.subMap(['rna_assay_by_accession', 'rna_assay_by_name', 'chromatin_assay']).values()}
		assay_names  = seurat_objects_to_create.map{['RNA', 'RNA_alt', 'ATAC']}
		misc_files   = seurat_objects_to_create.map{it.subMap(['granges', 'features']).values()}
		misc_names   = seurat_objects_to_create.map{['gene_models', 'features']}
		projects     = seurat_objects_to_create.map{it.get('dataset name')}

		// read the two rna assays and chromatin accessibility assay into a seurat object and write to rds file
		make_seurat_object(seurat_objects_to_create, tags, assays, assay_names, misc_files, misc_names, projects)

		// add the new objects into the parameters channel
		merge_process_emissions(make_seurat_object, ['opt', 'seurat'])
			.map{merge_metadata_and_process_output(it)}
			.dump(tag:'seurat:cell_ranger_arc:seurat_objects', pretty:true)
			.set{seurat_objects}

		// -------------------------------------------------------------------------------------------------
		// join any/all information back onto the parameters ready to emit
		// -------------------------------------------------------------------------------------------------

		stage_parameters
			.combine(seurat_objects)
			.filter{check_for_matching_key_values(it, ['unique id'])}
			.map{it.first() + it.last().subMap(['seurat'])}
			.dump(tag:'seurat:cell_ranger_arc:final_results', pretty:true)
			.set{final_results}

		// -------------------------------------------------------------------------------------------------
		// make summary report for cell ranger arc stage
		// -------------------------------------------------------------------------------------------------

		all_processes = [convert_gtf_to_granges, write_10x_counts_matrices, make_rna_assay, make_chromatin_assay, make_seurat_object]

		// collate the software version yaml files into one
		concat_workflow_emissions(all_processes, 'versions')
			.collect()
			.set{versions}

		merge_software_versions(versions)

		// collate the software version yaml files into one
		concat_workflow_emissions(all_processes, 'task')
			.collect()
			.set{task_properties}

		merge_task_properties(task_properties)

		// -------------------------------------------------------------------------------------------------
		// render a report for this part of the analysis
		// -------------------------------------------------------------------------------------------------

		// TODO: add process to render a chapter of a report

	emit:
		result = final_results
		report = channel.of('report.document')
}
