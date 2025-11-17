#!/usr/bin/env python3
import pandas as pd
import random

df = pd.read_csv('data/orthologs/ensembl_compara_table.tsv', sep='\t', low_memory=False)
ids = df['Gene stable ID'].unique()

print(f'Total unique gene IDs: {len(ids)}')
print('\nFirst 20 gene IDs with their directory names:')
for gid in sorted(ids)[:20]:
    gene_name = f"Gene_{str(gid).split('G')[-1][:8]}"
    print(f'  {gid} -> {gene_name}')

print('\nLast 20 gene IDs with their directory names:')
for gid in sorted(ids)[-20:]:
    gene_name = f"Gene_{str(gid).split('G')[-1][:8]}"
    print(f'  {gid} -> {gene_name}')

# Check for collisions
gene_names = {}
for gid in ids:
    gene_name = f"Gene_{str(gid).split('G')[-1][:8]}"
    if gene_name not in gene_names:
        gene_names[gene_name] = []
    gene_names[gene_name].append(gid)

collisions = {k: v for k, v in gene_names.items() if len(v) > 1}
print(f'\nDirectory name collisions: {len(collisions)}')
if len(collisions) > 0:
    print('\nFirst 5 collision examples:')
    for i, (name, ids_list) in enumerate(list(collisions.items())[:5]):
        print(f'  {name}: {len(ids_list)} genes')
        for gid in ids_list[:3]:
            print(f'    - {gid}')
