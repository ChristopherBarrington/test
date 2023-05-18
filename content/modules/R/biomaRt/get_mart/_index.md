---
title: get mart
layout: nf-module-doc

name: get mart

description: |
  Make a connection to the release-matched Ensembl database and saves the object as an RDS file.

tags:
  - r
  - ensembl
  - biomart

tools:
  R:
    description: R is a free software environment for statistical computing and graphics.
    homepage: https://www.r-project.org/
    documentation: https://cran.r-project.org/manuals.html
    licence: "GPL-2 | GPL-3"
  biomaRt:
    description: biomaRt provides an interface to a growing collection of databases implementing the BioMart software suite.
    homepage: https://bioconductor.org/packages/release/bioc/html/biomaRt.html
    documentation: https://bioconductor.org/packages/release/bioc/vignettes/biomaRt/inst/doc/accessing_ensembl.html
    source: https://github.com/grimbough/biomaRt
    licence: Artistic-2.0
 
input:
  - name: opt
    type: map
    description: A map of task-specific variables.
  - name: tag
    type: string
    description: An identifier to use in the tag directive.
  - name: organism
    type: string
    description: The organism name (eg. mus musculus) that will be converted to an Ensembl species (eg. mmusculus).
  - name: release
    type: string
    description: Ensembl database release version (eg. 101).

output:
  - name: mart
    type: file
    description: RDS object of a biomaRt connection.
    pattern: mart.rds

authors:
  - "@ChristopherBarrington"
---
