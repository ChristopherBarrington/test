// -------------------------------------------------------------------------------------------------
// import any java/groovy libraries as required
// -------------------------------------------------------------------------------------------------

import java.nio.file.Paths

// -------------------------------------------------------------------------------------------------
// specify modules relevant to this workflow
// -------------------------------------------------------------------------------------------------

include { convert_gtf_to_granges } from '../../../modules/R/GenomicRanges/convert_gtf_to_granges'

include { get_mart } from '../../../modules/R/biomaRt/get_mart'

include { make_assay as make_rna_assay }         from '../../../modules/R/Seurat/make_assay'
include { make_object as make_seurat_object }    from '../../../modules/R/Seurat/make_object'
include { percentage_feature_set as mt_percent } from '../../../modules/R/Seurat/percentage_feature_set'
include { write_10x_counts_matrices }            from '../../../modules/R/Seurat/write_10x_counts_matrices'

include { sa154 } from '../../../modules/R/Seurat/sa154'

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

workflow cell_ranger {

	take:
		stage_parameters

	main:
		// -------------------------------------------------------------------------------------------------
		// make GRanges objects for gene annotations of the genomes
		// -------------------------------------------------------------------------------------------------

		// create the channels for the process to make GRanges objects using Cell Ranger indexes
		stage_parameters
			.map{it.subMap(['genome', 'index path'])}
			.unique()
			.map{it + [gtf: Paths.get(it.get('index path').toString(), 'genes', 'genes.gtf')]}
			.map{it + [fai: Paths.get(it.get('index path').toString(), 'fasta', 'genome.fa.fai')]}
			.dump(tag:'seurat:cell_ranger:gtf_files_to_convert_to_granges', pretty:true)
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
			.dump(tag:'seurat:cell_ranger:granges_files', pretty:true)
			.set{granges_files}

		// -------------------------------------------------------------------------------------------------
		// make a biomaRt object for the genome
		// -------------------------------------------------------------------------------------------------

		// create the channels for the process to make biomaRt objects
		stage_parameters
			.map{it.subMap(['genome']) + it.get('genome parameters').subMap(['organism', 'ensembl release'])}
			.unique()
			.dump(tag:'seurat:cell_ranger:biomart_connections_to_make', pretty:true)
			.set{biomart_connections_to_make}

		tags             = biomart_connections_to_make.map{it.get('genome')}
		organisms        = biomart_connections_to_make.map{it.get('organism')}
		ensembl_releases = biomart_connections_to_make.map{it.get('ensembl release')}

		// make the mart rds files
		get_mart(biomart_connections_to_make, tags, organisms, ensembl_releases)

		// make a channel of newly created GRanges rds files
		merge_process_emissions(get_mart, ['opt', 'mart'])
			.map{merge_metadata_and_process_output(it)}
			.dump(tag:'seurat:cell_ranger:mart_files', pretty:true)
			.set{mart_files}

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
			.dump(tag:'seurat:cell_ranger:barcoded_matrices_to_read', pretty:true)
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
			.dump(tag:'seurat:cell_ranger:barcoded_matrices', pretty:true)
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
			.dump(tag:'seurat:cell_ranger:rna_assays_branched', pretty:true)
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
			.dump(tag:'seurat:cell_ranger:rna_assays', pretty:true)
			.set{rna_assays}

		// -------------------------------------------------------------------------------------------------
		// make a seurat object using rna assays
		// -------------------------------------------------------------------------------------------------

		// combine the annotations and rna assays into a channel
		stage_parameters
			.combine(rna_assays)
			.combine(granges_files.map{it.subMap(['genome', 'index path', 'granges'])})
			.combine(barcoded_matrices.filter{it.get('identifier') == 'accession'}.map{it.subMap(['index path', 'quantification path', 'features'])})
			.filter{check_for_matching_key_values(it, 'genome')}
			.filter{check_for_matching_key_values(it, 'index path')}
			.filter{check_for_matching_key_values(it, 'quantification path')}
			.map{concatenate_maps_list(it)}
			.map{it + [ordered_assays:it.subMap('rna_assay_by_accession', 'rna_assay_by_name').values().toList()]}
			.map{if(it.get('feature identifiers') == 'name') {it.ordered_assays = it.get('ordered_assays').reverse()} ; it}
			.map{it.subMap(['unique id', 'ordered_assays', 'dataset tag', 'granges', 'features', 'dataset name', 'dataset id'])}
			.dump(tag:'seurat:cell_ranger:seurat_objects_to_create', pretty:true)
			.set{seurat_objects_to_create}

		// create the channels for the process to make a seurat object
		tags         = seurat_objects_to_create.map{it.get('unique id')}
		assays       = seurat_objects_to_create.map{it.get('ordered_assays')}
		assay_names  = seurat_objects_to_create.map{['RNA', 'RNA_alt']}
		misc_files   = seurat_objects_to_create.map{it.subMap(['granges', 'features']).values()}
		misc_names   = seurat_objects_to_create.map{['gene_models', 'features']}
		projects     = seurat_objects_to_create.map{it.get('dataset name')}

		// read the two rna assays into a seurat object and write to rds file
		make_seurat_object(seurat_objects_to_create, tags, assays, assay_names, misc_files, misc_names, projects)

		// add the new objects into the parameters channel
		merge_process_emissions(make_seurat_object, ['opt', 'seurat'])
			.map{merge_metadata_and_process_output(it)}
			.dump(tag:'seurat:cell_ranger:seurat_objects', pretty:true)
			.set{seurat_objects}

		// -------------------------------------------------------------------------------------------------
		// add mitochondrial expression detected per cell
		// -------------------------------------------------------------------------------------------------

		// create the channels for the process to calculate mitochondrial proportions
		stage_parameters
			.combine(seurat_objects)
			.filter{check_for_matching_key_values(it, ['unique id'])}
			.map{it.first() + it.last().subMap(['seurat'])}
			.map{it.subMap(['unique id', 'dataset id', 'seurat']) + it.get('genome parameters').subMap(['mitochondrial features'])}
			.dump(tag:'seurat:cell_ranger:mt_percent_input', pretty:true)
			.set{mt_percent_input}

		// create the channels for the process to make a seurat object
		tags          = mt_percent_input.map{it.get('unique id')}
		assays        = 'RNA'
		feature_sets  = mt_percent_input.map{it.get('mitochondrial features')}
		input_seurats = mt_percent_input.map{it.get('seurat')}

		// calculate percentages and provide paths to metadata rds files
		mt_percent(mt_percent_input, tags, assays, feature_sets, input_seurats)
		
		// add the new objects into the parameters channel
		merge_process_emissions(mt_percent, ['opt', 'seurat'])
			.map{merge_metadata_and_process_output(it)}
			.dump(tag:'seurat:cell_ranger:mt_percent_output', pretty:true)
			.set{mt_percent_output}







		//
		//
		//

		// stage_parameters
		// 	.combine(mt_percent_output)
		// 	.filter{check_for_matching_key_values(it, ['unique id'])}
		// 	.map{it.first() + it.last().subMap(['seurat'])}
		// 	.map{it.subMap(['unique id', 'dataset id', 'seurat', 'cell barcodes']) + it.get('genome parameters').subMap(['cell cycle genes'])}
		// 	.dump(tag:'seurat:cell_ranger:sa154', pretty:true)
		// 	.set{sa154}

		// // create the channels for the process to make a seurat object
		// tags             = sa154.map{it.get('unique id')}
		// input_seurats    = sa154.map{it.get('seurat')}
		// cell_ids         = sa154.map{it.get('cell barcodes')}
		// cell_cycle_genes = sa154.map{it.get('cell cycle genes')}

		// // calculate percentages and provide paths to metadata rds files
		// sa154(sa154, tags, input_seurats, cell_ids, cell_cycle_genes)
		
		// // add the new objects into the parameters channel
		// // merge_process_emissions(sa154, ['opt', 'seurat'])
		// // 	.map{merge_metadata_and_process_output(it)}
		// // 	.dump(tag:'seurat:cell_ranger:sa154_output', pretty:true)
		// // 	.set{sa154_output}








		// -------------------------------------------------------------------------------------------------
		// join any/all information back onto the parameters ready to emit
		// -------------------------------------------------------------------------------------------------

		stage_parameters
			.combine(seurat_objects)
			.filter{check_for_matching_key_values(it, ['unique id'])}
			.map{it.first() + it.last().subMap(['seurat'])}
			.dump(tag:'seurat:cell_ranger:final_results', pretty:true)
			.set{final_results}

		// -------------------------------------------------------------------------------------------------
		// make summary report for cell ranger arc stage
		// -------------------------------------------------------------------------------------------------

		all_processes = [convert_gtf_to_granges, write_10x_counts_matrices, make_rna_assay, make_seurat_object]

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
