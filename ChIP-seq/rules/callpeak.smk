# -*- coding: utf-8 -*-
# @Author: XiZhihui
# @Date:   2018-11-24 21:09:21
# @Last Modified by:   XiZhihui
# @Last Modified time: 2018-11-27 19:21:24
# @Description: peak calling with macs2, replicates analysis with bedtools or idr

#################### helper ####################
def get_macs2_control(wildcards):
	control = mocks.loc[(wildcards.sample, wildcards.unit), ["mock_sample", "mock_unit"]]
	return "output/mapping/{mock_sample}-{mock_unit}.rmdup.bam".format(**control)

def get_macs2_treat(wildcards):
	treat = mocks.loc[(wildcards.sample, wildcards.unit), ["sample", "unit"]]
	return "output/mapping/{sample}-{unit}.rmdup.bam".format(**treat)


#################### transcription factors ####################
rule macs2_transcription_factor:
	input:
		control = get_macs2_control,
		treat = get_macs2_treat
	output:
		"output/callpeak/{sample}/{sample}-{unit}_peaks.narrowPeak"
	log:
		"logs/callpeak/{sample}/{sample}-{unit}_transcription.log"
	conda:
		"../envs/callpeak.yaml"
	params:
		species = config["MACS2"]["species"]
	shell:
		"""
		python scripts/callpeak.py transcription \
			-c {input.control} \
			-t {input.treat} \
			--outdir output/callpeak/{wildcards.sample} \
			-n {wildcards.sample}-{wildcards.unit} \
			-g {params.species} \
			--log {log}
		"""

rule replicates_idr:
	input:
		expand("output/callpeak/{{sample}}/{{sample}}-{unit}_peaks.narrowPeak", unit=get_transcription()["unit"].unique())
	output:
		"output/callpeak/{sample}/{sample}_peaks.narrowPeak"
	conda:
		"../envs/idr.yaml"
	log:
		"logs/callpeak/{sample}/{sample}_replicates_idr.log"
	script:
		"../scripts/idr.py"


#################### histone modification ####################
rule estimate_extsize:
	input:
		"output/mapping/{sample}-{unit}.rmdup.bam"
	output:
		"output/callpeak/{sample}/{sample}-{unit}.extsize"
	log:
		"logs/callpeak/{sample}/{sample}-{unit}_run_spp.log"
	conda:
		"../envs/phamtompeaktools.yaml"
	shell:
		"""
		Rscript ./scripts/run_spp.R -c={input} -savp -rf -out={output} 1> {log} 2>&1
		"""

rule macs2_histone_modification:
	input:
		control = get_macs2_control,
		treat = get_macs2_treat,
		extsize = "output/callpeak/{sample}/{sample}-{unit}.extsize"
	output:
		"output/callpeak/{sample}/{sample}-{unit}_peaks.broadPeak"
	log:
		"logs/callpeak/{sample}/{sample}-{unit}_histone.log"
	conda:
		"../envs/callpeak.yaml"
	params:
		species = config["MACS2"]["species"]
	shell:
		"""
		python scripts/callpeak.py histone \
			--broad --broad-cutoff 0.1 \
			--nomodel --extsize {input.extsize} \
			-c {input.control} \
			-t {input.treat} \
			--outdir output/callpeak/{wildcards.sample} \
			-n {wildcards.sample}-{wildcards.unit} \
			-g {params.species} \
			--log {log}
		"""

def get_bedtools_input(wildcards):
	temp_units = units.loc[wildcards.sample, "unit"]
	return expand("output/callpeak/{sample}/{sample}-{unit}_peaks.broadPeak", sample=wildcards.sample, unit=temp_units)

rule replicates_intersect:
	input:
		a = lambda wildcards: get_bedtools_input(wildcards)[0],
		b = lambda wildcards: get_bedtools_input(wildcards)[1:]
	output:
		"output/callpeak/{sample}/{sample}_peaks.broadPeak"
	conda:
		"../envs/bedtools.yaml"
	log:
		"logs/callpeak/{sample}/{sample}_replicates_intersect.log"
	shell:
		"""
		bedtools intersect -a {input.a} -b {input.b} > {output} 2>{log}
		"""


#################### filter blacklist for both transcription factor and histome modification ####################
rule filter_blacklist:
	input:
		expand("output/callpeak/{sample}/{sample}_peaks.narrowPeak", sample=get_transcription()["sample"].unique()),
		expand("output/callpeak/{sample}/{sample}_peaks.broadPeak", sample=get_histone()["sample"].unique())
	output:
		expand("output/callpeak/{sample}/{sample}_peaks.narrowPeak.final", sample=get_transcription()["sample"].unique()),
		expand("output/callpeak/{sample}/{sample}_peaks.broadPeak.final", sample=get_histone()["sample"].unique())
	conda:
		"../envs/bedtools.yaml"
	log:
		"logs/callpeak/filter_blacklist.log"
	params:
		blacklist = config["MACS2"]["blacklist"]
	shell:
		"""
		for peak in {input};
		do
			bedtools intersect -v -a $peak -b {params.blacklist} > ${{peak}}.final 2>>{log}
		done
		"""