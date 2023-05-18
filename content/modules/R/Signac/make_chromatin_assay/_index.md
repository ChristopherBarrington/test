---
title: "Make chromatin assay"
layout: nf-module-doc

name: "Make chromatin assay"

description: |
  Create a chromatin assay using Signac and a counts matrix.

tools:
  R:
    description: R is a free software environment for statistical computing and graphics.
    homepage: https://www.r-project.org/
    documentation: https://cran.r-project.org/manuals.html
    licence: "GPL-2 | GPL-3"
  Signac:
    description: Signac is designed for the analysis of single-cell chromatin data, including scATAC-seq, single-cell targeted tagmentation methods such as scCUT&Tag and scNTT-seq, and multimodal datasets that jointly measure chromatin state alongside other modalities.
    homepage: https://stuartlab.org/signac
    documentation: https://stuartlab.org/signac/articles/overview.html
    source: https://github.com/stuart-lab/signac
    licence: MIT

tags:
  - r
  - chromatin accessibility

input:
  - name: opt
    type: map
    description: A map of task-specific variables.
  - name: tag
    type: string
    description: An identifier to use in the tag directive.
  - name: annotations
    type: file
    description: GRanges object of GTF save as RDS file.
  - name: counts matrices
    type: file
    description: RDS file of the counts matrices loaded by Seurat.
  - name: quantification path
    type: path
    description: Path to the quantified dataset from which the ATAC-seq fragments are read.
  - name: feature type 
    type: string
    description: The name of the list key in `counts matrices` that contains the chromatin assay data (eg. "Chromatin Accessibility").

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
  - name: assay
    type: file
    description: RDS file of the newly created chromatin accessibility assay.
    pattern: assay.rds

authors:
  - "@ChristopherBarrington"
---
