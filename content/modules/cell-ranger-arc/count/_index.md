---
title: count
layout: nf-module-doc

name: count

description: |
  Aligns and quantifies FastQ files from a 10X scRNA-seq experiment against a reference genome. Output matrices are provided in triplet and h5 formats.

tags:
  - 10x
  - multiome
  - quantification

tools:
  cell ranger arc:
    description: Cell Ranger ARC is a set of analysis pipelines that process Chromium Single Cell Multiome ATAC + Gene Expression sequencing data to generate a variety of analyses pertaining to gene expression (GEX), chromatin accessibility, and their linkage. Furthermore, since the ATAC and GEX measurements are on the very same cell, we are able to perform analyses that link chromatin accessibility and GEX.
    homepage: https://support.10xgenomics.com/single-cell-multiome-atac-gex/software
    documentation: https://support.10xgenomics.com/single-cell-multiome-atac-gex/software/pipelines/latest/using/count

input:
  - name: opt
    type: map
    description: A map of task-specific variables.
  - name: tag
    type: string
    description: An identifier to use in the tag directive.
  - name: samples
    type: string array
    description: "An array of length two: RNA and chromatin assay sample names."
  - name: index_path
    type: path
    description: Path to the propoerly-formatted index directory.
  - name: all_libraries.csv
    type: file
    description: Path to the liraries sample sheet. This will be searched using grep for the relevant samples.

output:
  - name: opt
    type: map
    description: A map of task-specific variables.
  - name: task
    type: file
    description: YAML-formatted file of task parameters.
    pattern: task.yaml
  - name: versions
    type: file
    description: YAML-formatted file of software versions used by the task.
    pattern: versions.yaml
  - name: libraries
    type: file
    description: CSV-formatted file of the libraries used by the task.
    pattern: libraries.csv
  - name: quantification_path
    type: path
    description: Cell Ranger outputs directory ("outs").
    pattern: output/outs
  - name: atac_summary
    type: file
    description: HTML summary for the ATAC-seq assay.
    pattern: atac_summary.html
  - name: joint_summary
    type: file
    description: HTML summary for the join RNA- and ATAC-seq assays.
    pattern: joint_summary.html
  - name: rna_summary
    type: file
    description: HTML summary for the RNA-seq assay.
    pattern: rna_summary.html

authors:
  - "@ChristopherBarrington"
---
