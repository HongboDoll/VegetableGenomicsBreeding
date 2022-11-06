#!/usr/bin/env python3

import sys

i1 = open(sys.argv[1])  # 42_vegetable_nearly_single_copy.tsv

for line in i1:
	if 'Orthogroup' not in line:
		line = line.strip().split()
		print(line[0], end='\t')
		for n in range(1, len(line)):
			print(line[n].split(',')[0], end='\t')
		print('')

