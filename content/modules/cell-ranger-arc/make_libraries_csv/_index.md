---
title: make libraries CSV
layout: nf-module-doc

name: make libraries CSV

description: |
  Creates a sample sheet for a whole project, listing the sample names, assay types and paths to FastQ files. It can be subset to produce a sample sheet for a sample.

tags:
  - 10x
  - multiome

input:
  - name: opt
    type: map
    description: A map of task-specific variables.
  - name: fastq paths
    type: files
    description: An array of paths that contain FastQ files that could be added to the sample sheet. 
  - name: fastq files regex
    type: string
    description: A regular expression used to filter the files in the `fastq paths` to identify proper FastQ files.
  - name: samples
    type: strings
    description: An array of sample names to search for.
  - name: feature types
    type: strings
    description: An array of "Gene Expression" or "Chromatin Accessibility" for each sample. This must be the same order as the `samples` channel.

output:
  - name: opt
    type: map
    description: A map of task-specific variables.
  - name: path
    type: file
    description: CSV-formatted sample sheet that includes every sample in the project.
    pattern: libraries.csv

authors:
  - "@ChristopherBarrington"
---
