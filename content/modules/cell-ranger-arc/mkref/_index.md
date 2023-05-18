---
title: mkref
layout: nf-module-doc

name: mkref

description: |
  Creates an index for use with Cell Ranger ARC. It can produce custom genomes if provided with the relevant (and correctly formatted) FastA and GTF files.

tags:
  - 10x
  - multiome
  - create index

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
  - name: organism
    type: string
    description: Name of the organism (eg. Mus_musculus)
  - name: assembly
    type: string
    description: Genome assembly (eg. mm10)
  - name: mon-nuclear contigs
    type: strings
    description: An array of chromosome names present in the FastA and GTF files that are not in the nucleus and therefore lack chromatin structure.
  - name: motifs
    type: file
    description: Path to the transcription factor motifs in JASPAR format.
  - name: path to FastAs
    type: path
    description: Path to directory containing FastA files to index. These will be concatenated into a single FastA file.
  - name: path to GTFs
    type: path
    description: Path to directory containing GTF files. These will be concatenated into a single GTF file.

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
  - name: path
    type: path
    description: Path to the newly created index.

authors:
  - "@ChristopherBarrington"
---
