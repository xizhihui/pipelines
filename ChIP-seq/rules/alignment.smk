# -*- coding: utf-8 -*-
# @Author: XiZhihui
# @Date:   2018-11-22 18:43:44
# @Last Modified by:   XiZhihui
# @Last Modified time: 2018-11-26 12:41:00
# @Description: mappint to the reference and filter the bam

#################### alignment ####################
rule bowtie_index:
	input:
		config["ref"]["genome"]
	output:
		# only for bowtie2 index suffex
		[os.path.join(config["ref"]["index_path"], config["ref"]["name"] + filetype) for filetype in ".1.bt2 .2.bt2 .3.bt2 .4.bt2 rev..1.bt2 rev..2.bt2".split(" ")]
	params:
		prefix = os.path.join(config["ref"]["index_path"], config["ref"]["name"])
	log:
		"logs/mapping/bowtie2_index.log"
	wrapper:
		"0.27.1/bio/bowtie2/index"

def get_bowtie2_input(wildcards):
	single = is_single(wildcards)
	if single:
		return ["output/trim/{sample}-{unit}.fastq.gz".format(**wildcards)]
	else:
		return expand(["output/trim/{sample}-{unit}.1.fastq.gz", "output/trim/{sample}-{unit}.2.fastq.gz"], **wildcards)

rule bowtie2:
	input:
		sample = get_bowtie2_input
	output:
		"output/mapping/{sample}-{unit}.bam"
	params:
		index = os.path.join(config["ref"]["index_path"], config["ref"]["name"]),
		extra = ""
	threads:
		config["processors"]
	log:
		"logs/mapping/mapping_{sample}-{unit}.log"
	wrapper:
		"0.27.1/bio/bowtie2/align"

rule samtools_sort:
	input:
		"output/mapping/{sample}-{unit}.bam"
	output:
		"output/mapping/{sample}-{unit}.sorted.bam"
	threads:
		config["processors"]
	log:
		"logs/mapping/samsort_{sample}-{unit}.log"
	params:
		"-m 4G"
	wrapper:
		"0.27.1/bio/samtools/sort"


#################### filter ####################
rule samtools_filter:
	# samtools view -q 20 -b -o filtered.bam data.bam  
	input:
		"output/mapping/{sample}-{unit}.sorted.bam",
	output:
		"output/mapping/{sample}-{unit}.filter.bam"
	log:
		"logs/mapping/samfilter_{sample}-{unit}.log"
	params:
		config["samtools_view"] # optional params string
	wrapper:
		"0.27.1/bio/samtools/view"

rule mark_duplicates:
    input:
        "output/mapping/{sample}-{unit}.filter.bam"
    output:
        bam="output/mapping/{sample}-{unit}.rmdup.bam",
        metrics="output/mapping/{sample}-{unit}.rmdup.txt"
    log:
        "logs/mapping/rmdup_{sample}-{unit}.log"
    params:
        "REMOVE_DUPLICATES=true"
    wrapper:
        "0.27.1/bio/picard/markduplicates"

#################### index ####################
rule samtools_index:
	input:
		"output/mapping/{sample}-{unit}.rmdup.bam"
	output:
		"output/mapping/{sample}-{unit}.rmdup.bam.bai"
	threads:
		config["processors"]
	log:
		"logs/mapping/samindex_{sample}-{unit}.log"
	wrapper:
		"0.27.1/bio/samtools/index"