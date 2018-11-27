# -*- coding: utf-8 -*-
# @Author: XiZhihui
# @Date:   2018-11-22 16:16:11
# @Last Modified by:   XiZhihui
# @Last Modified time: 2018-11-27 19:37:00
# @Description: quality control and filter or trim

# input helper for rule fastqc_before_trim and trimmomatic
def get_fastq(wildcards):
	return units.loc[(wildcards.sample, wildcards.unit), ["fq1", "fq2"]].dropna()

def get_trim_out(wildcards):
	single = is_single(wildcards)
	if single:
		return expand("output/trim/{sample}-{unit}.fastq.gz", **wildcards)
	else:
		return expand([
				"output/trim/{sample}-{unit}.1.fastq.gz",
				"output/trim/{sample}-{unit}.2.fastq.gz",
			], **wildcards)

#################### fastqc ####################
rule fastqc_before_trim:
	input:
		get_fastq
	output:
		# directory("output/fastqc")
		html = "output/qc/fastqc_before/{sample}-{unit}_fastqc.html",
		zip = "output/qc/fastqc_before/{sample}-{unit}_fastqc.zip"
	log:
		"logs/qc/fastqc/{sample}-{unit}.before_trim.log"
	params:
		"-t {} -f fastq".format(config["processors"])
	threads:
		config["processors"]
	wrapper:
		"0.27.1/bio/fastqc"

rule fastqc_after_trim:
	input:
		get_trim_out
	output:
		# directory("output/fastqc")
		html = "output/qc/fastqc_after/{sample}-{unit}_fastqc.html",
		zip = "output/qc/fastqc_after/{sample}-{unit}_fastqc.zip"
	log:
		"logs/qc/fastqc/{sample}-{unit}.after_trim.log"
	params:
		"-t {} -f fastq".format(config["processors"])
	threads:
		config["processors"]
	wrapper:
		"0.27.1/bio/fastqc"


#################### trimmomtic ####################
def get_fastq_r1(wildcards):
	res = units.loc[[wildcards.sample, wildcards.unit], ["fq1", "fq2"]]["fq1"]
	return res

def get_fastq_r2(wildcards):
	res = units.loc[[wildcards.sample, wildcards.unit], ["fq1", "fq2"]]["fq2"]
	return res

rule trimmomatic_pe:
	input:
		r1 = get_fastq_r1,
		r2 = get_fastq_r2
	output:
		r1 = "output/trim/{sample}-{unit}.1.fastq.gz",
		r1_unpaired = "output/trim/{sample}-{unit}.1_unpaired.fastq.gz",
		r2 = "output/trim/{sample}-{unit}.2.fastq.gz",
		r2_unpaired = "output/trim/{sample}-{unit}.2_unpaired.fastq.gz"
	log:
		"logs/trim/{sample}-{unit}.log"
	params:
		trimmer = config["trimmomatic_pe"],
		extra =  "-threads {}".format(config["processors"])
	threads:
		config["processors"]
	wrapper:
		"0.27.1/bio/trimmomatic/pe"

rule trimmomatic_se:
	input:
		get_fastq
	output:
		"output/trim/{sample}-{unit}.fastq.gz"
	log:
		"logs/trim/{sample}-{unit}.log"
	params:
		trimmer = config["trimmomatic_se"],
		extra =  "-threads {}".format(config["processors"])
	threads:
		config["processors"]
	wrapper:
		"0.27.1/bio/trimmomatic/se"