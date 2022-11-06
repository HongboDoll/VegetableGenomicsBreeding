#!/bin/bash

cd /public/agis/huangsanwen_group/lihongbo/database/vegetable_amino_acid
./work.sh
cd -

source activate /home/jiayuxin/anaconda3/envs/ortho

rm -rf pep/OrthoFinder

orthofinder -f pep -a 52 -t 52 -T iqtree -M msa  -os

source /home/huyong/software/anaconda3/bin/activate collinerity
#
./convert_orthogroup_2_pan_matrix.py pep/OrthoFinder/Results*/Orthogroups/Orthogroups.tsv > 42_vegetable_matrix_core_dispensable_genes.cluster

./output_nearly_single_copy_OG.py pep/OrthoFinder/Results*/Orthogroups/Orthogroups.GeneCount.tsv 33 > 42_vegetable_Orthogroups_nearly_single_copy_33.tsv

rm 42_vegetable_nearly_single_copy.tsv
awk 'NR!=1' 42_vegetable_Orthogroups_nearly_single_copy_33.tsv | awk '{print $1}' | while read i
do
	grep $i 42_vegetable_matrix_core_dispensable_genes.cluster >> 42_vegetable_nearly_single_copy.tsv
done

./revise_single_copy_OG.py 42_vegetable_nearly_single_copy.tsv > t && mv t 42_vegetable_nearly_single_copy.tsv

cat pep/*fa > 42_vegetable_pep.fa


rm -rf ext.sh  og_pep; mkdir og_pep
cat 42_vegetable_nearly_single_copy.tsv |  while read l
do
	og=`echo $l | awk '{print $1}'`
	echo $l | sed 's/ /\n/g' | awk 'NR!=1' | while read g
	do
		echo -e "give_me_one_seq.pl 42_vegetable_pep.fa $g >> og_pep/${og}_pep.fa" >> ext.sh
	done
done


cat ./ext.sh | parallel -j 52

rm -rf mafft_out_pep; mkdir mafft_out_pep
ls og_pep/*fa | while read i
do
	name=`echo $i | awk -F '/' '{print $2}'`
    mafft --thread 52 --auto ${i} > mafft_out_pep/${name}.out
    fa2phy.py -i mafft_out_pep/${name}.out -o mafft_out_pep/${name}.phylip
    awk 'NR!=1' mafft_out_pep/${name}.phylip | awk '{print $2}' > t && mv t mafft_out_pep/${name}.phylip
done

head -1 42_vegetable_matrix_core_dispensable_genes.cluster | sed 's/\t/\n/g' | awk 'NR!=1' > first_col
n=`ls mafft_out_pep/*.phylip | sed ':a;N;s/\n/ /g;ta'`
paste -d '' $n > mafft_out_pep/GR.phylip.all
awk 'BEIGN{n=1}{print ">"n"\n"$1;n+=1}' mafft_out_pep/GR.phylip.all > mafft_out_pep/GR.phylip.all.fa
#./remove_gap_N_in_fasta_alignment.py mafft_out_pep/GR.phylip.all.fa  mafft_out_pep/GR.phylip.all.noGAP.fa
n1=`grep -v '>' mafft_out_pep/GR.phylip.all.fa | wc -l | awk '{print $1}'`
n2=`sed 's/ //g' mafft_out_pep/GR.phylip.all.fa | grep -v '>' | head -1 |wc | awk '{print $3-1}'`
echo -e "$n1 $n2" > mafft_out_pep/head
cat mafft_out_pep/head <(paste -d '\t' first_col  <(grep -v '>' mafft_out_pep/GR.phylip.all.fa)) | sed 's/\t/            /g' > single_copy_gene_family_pep_4_tree.phylip

rm RAxML_* single_copy_gene_family_pep_4_tree.phylip.*
raxmlHPC-PTHREADS-SSE3 -f a -x 5 -p 5 -# 100 -m PROTGAMMAJTT -s single_copy_gene_family_pep_4_tree.phylip -n single_copy_gene_family_pep_4_tree -T 52
#
#
#
#
#
