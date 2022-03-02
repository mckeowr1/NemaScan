/*
======================================
~ > *                            * < ~
~ ~ > *                        * < ~ ~
~ ~ ~ > *  RUN GWAS MAPPING  * < ~ ~ ~
~ ~ > *                        * < ~ ~
~ > *                            * < ~
======================================
*/

/*
------------ GCTA
*/

process prepare_gcta_files {

    // machineType 'n1-standard-4'
    label "large"

    input:
        tuple file(strains), val(TRAIT), file(traits), file(vcf), file(index), file(num_chroms)

    output:
        tuple val(TRAIT), file("plink_formated_trats.tsv"), file("${TRAIT}.bed"), file("${TRAIT}.bim"), file("${TRAIT}.fam"), file("${TRAIT}.map"), file("${TRAIT}.nosex"), file("${TRAIT}.ped"), file("${TRAIT}.log")

    """
    bcftools annotate --rename-chrs ${num_chroms} ${vcf} |\\
    bcftools view -S ${strains} -Ou |\\
    bcftools filter -i N_MISSING=0 -Oz --threads 5 -o renamed_chroms.vcf.gz
    tabix -p vcf renamed_chroms.vcf.gz
    plink --vcf renamed_chroms.vcf.gz \\
          --threads 5 \\
          --snps-only \\
          --biallelic-only \\
          --maf ${params.maf} \\
          --set-missing-var-ids @:# \\
          --indep-pairwise 50 10 0.8 \\
          --geno \\
          --not-chr MtDNA \\
          --allow-extra-chr
    tail -n +2 ${traits} | awk 'BEGIN {OFS="\\t"}; {print \$1, \$1, \$2}' > plink_formated_trats.tsv
    plink --vcf renamed_chroms.vcf.gz \\
          --threads 5 \\
          --make-bed \\
          --snps-only \\
          --biallelic-only \\
          --maf ${params.maf} \\
          --set-missing-var-ids @:# \\
          --extract plink.prune.in \\
          --geno \\
          --recode \\
          --out ${TRAIT} \\
          --allow-extra-chr \\
          --pheno plink_formated_trats.tsv
    """
}

process gcta_grm {

    // machineType 'n1-highmem-4'
    label "xl"

    input:
        tuple val(TRAIT), file(traits), file(bed), file(bim), file(fam), file(map), file(nosex), file(ped), file(log)

    output:
        tuple val(TRAIT), file(traits), file(bed), file(bim), file(fam), file(map), file(nosex), file(ped), file(log), file("${TRAIT}_gcta_grm.grm.bin"), file("${TRAIT}_gcta_grm.grm.id"), file("${TRAIT}_gcta_grm.grm.N.bin"), file("${TRAIT}_heritability.hsq"), file("${TRAIT}_heritability.log"), file("${TRAIT}_gcta_grm_inbred.grm.bin"), file("${TRAIT}_gcta_grm_inbred.grm.id"), file("${TRAIT}_gcta_grm_inbred.grm.N.bin"), file("${TRAIT}_heritability_inbred.hsq"), file("${TRAIT}_heritability_inbred.log")

    when:
        params.maps

    """
    gcta64 --bfile ${TRAIT} \\
           --autosome \\
           --maf ${params.maf} \\
           --make-grm \\
           --out ${TRAIT}_gcta_grm \\
           --thread-num 5
    gcta64 --bfile ${TRAIT} \\
           --autosome \\
           --maf ${params.maf} \\
           --make-grm-inbred \\
           --out ${TRAIT}_gcta_grm_inbred \\
           --thread-num 5
    gcta64 --grm ${TRAIT}_gcta_grm \\
           --pheno plink_formated_trats.tsv \\
           --reml \\
           --out ${TRAIT}_heritability \\
           --thread-num 5
    gcta64 --grm ${TRAIT}_gcta_grm_inbred \\
           --pheno plink_formated_trats.tsv \\
           --reml \\
           --out ${TRAIT}_heritability_inbred \\
           --thread-num 5
    """
}


process gcta_lmm_exact_mapping {

    // machineType 'n1-highmem-4'
    label "xl"

    publishDir "${params.out}/Mapping/Raw", pattern: "*fastGWA", overwrite: true
    publishDir "${params.out}/Mapping/Raw", pattern: "*loco.mlma", overwrite: true

    // why?
    // errorStrategy 'ignore'

    input:
    tuple val(TRAIT), file(traits), file(bed), file(bim), file(fam), file(map), \
    file(nosex), file(ped), file(log), file(grm_bin), file(grm_id), file(grm_nbin), \
    file(h2), file(h2log), file(grm_bin_inbred), file(grm_id_inbred), file(grm_nbin_inbred), \
    file(h2_inbred), file(h2log_inbred)

    output:
    tuple val(TRAIT), file("${TRAIT}_lmm-exact_inbred.fastGWA"), file("${TRAIT}_lmm-exact.loco.mlma")


    """
    gcta64 --grm ${TRAIT}_gcta_grm \\
           --make-bK-sparse ${params.sparse_cut} \\
           --out ${TRAIT}_sparse_grm \\
           --thread-num 5
    gcta64 --mlma-loco \\
           --grm ${TRAIT}_sparse_grm \\
           --bfile ${TRAIT} \\
           --out ${TRAIT}_lmm-exact \\
           --pheno ${traits} \\
           --maf ${params.maf} \\
           --thread-num 5
    gcta64 --grm ${TRAIT}_gcta_grm_inbred \\
           --make-bK-sparse ${params.sparse_cut} \\
           --out ${TRAIT}_sparse_grm_inbred \\
           --thread-num 5
    gcta64 --fastGWA-lmm-exact \\
           --grm-sparse ${TRAIT}_sparse_grm \\
           --bfile ${TRAIT} \\
           --out ${TRAIT}_lmm-exact_inbred \\
           --pheno ${traits} \\
           --maf ${params.maf} \\
           --thread-num 5
    """
}



process gcta_intervals_maps {

    // machineType 'n1-highmem-8'
    label "highmem"

    publishDir "${params.out}/Mapping/Processed", mode: 'copy', pattern: "*AGGREGATE_mapping.tsv"
    publishDir "${params.out}/Mapping/Processed", mode: 'copy', pattern: "*AGGREGATE_qtl_region.tsv" //would be nice to put all these files per trait into one file


    input:
        tuple val(TRAIT), file(pheno), file(tests), file(geno), val(P3D), val(sig_thresh), \
        val(qtl_grouping_size), val(qtl_ci_size), file(lmmexact_inbred), file(lmmexact_loco), \
        file(aggregate_mappings), file(find_aggregate_intervals_maps)

    output:
        tuple file(geno), file(pheno), val(TRAIT), file(tests), file("*AGGREGATE_mapping.tsv"), emit: maps_to_plot
        path "*AGGREGATE_qtl_region.tsv", emit: qtl_peaks
        tuple file("*AGGREGATE_mapping.tsv"), val(TRAIT), emit: for_html

    """
    echo ".libPaths(c(\\"${params.R_libpath}\\", .libPaths() ))" | cat - ${aggregate_mappings} > Aggregate_Mappings
    Rscript --vanilla Aggregate_Mappings ${lmmexact_loco} ${lmmexact_inbred}
    
    echo ".libPaths(c(\\"${params.R_libpath}\\", .libPaths() ))" | cat - ${find_aggregate_intervals_maps} > Find_Aggregate_Intervals_Maps
    Rscript --vanilla Find_Aggregate_Intervals_Maps ${geno} ${pheno} temp.aggregate.mapping.tsv ${tests} ${qtl_grouping_size} ${qtl_ci_size} ${sig_thresh} ${TRAIT}_AGGREGATE
    """
}
