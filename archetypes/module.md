---
title: "{{ replace .Name "-" " " | title }}"
layout: nf-module-doc

name: "{{ replace .Name "-" " " | title }}"

description: |
  This is a module that does an amaing thing.

tools:
  bash:
    description: No introduction necessary
    homepage: https://www.gnu.org/software/bash
    documentation: https://www.gnu.org/software/bash
    tool_dev_url: https://www.gnu.org/software/bash
    licence: GPL-3.0
  mac os x:
    description: Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
    homepage: https://www.apple.com
    doi: 10.1016/j.cell.2019.05.031

input:
  apples:
    type: integer
    description: The number of apples in the basket.
  oranges:
    type: integer
    description: The number of oranges in the basket.
  basket:
    type: string
    description: The type of basket the fruit is in.

output:
  juice:
    type: file
    description: Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
    pattern: "*.juicer"

authors:
  - "@ChristopherBarrington"
---
