# -*- coding: utf-8 -*-
# @Author: XiZhihui
# @Date:   2018-11-25 21:02:41
# @Last Modified by:   XiZhihui
# @Last Modified time: 2018-11-27 22:05:26
# @Description: annotation with ChIPseeker, motif analysis with homer

import os


#################### annotation ####################
### plz be careful with the directory, it is used with a hardly code in chipseeker.R
def get_output_files():
	pdfs = [
		"peaks_over_chromosomes.pdf",
		"heatmap_of_peaks_on_TSS.pdf",
		"read_count_frequency_of_peaks.pdf",
		"annotation_bar.pdf",
		"annotation_pie.pdf",
		"annotation_upset.pdf",
		"annotation_distance_to_TSS.pdf",
	]
	samples = mocks["sample"].unique()
	return expand("output/annotation/{sample}/{pdf}", sample=samples, pdf=pdfs)

rule chipseeker:
	input:
		expand("output/callpeak/{sample}/{sample}_peaks.narrowPeak.final", sample=get_transcription()["sample"].unique()),
		expand("output/callpeak/{sample}/{sample}_peaks.broadPeak.final", sample=get_histone()["sample"].unique())
	output:
		get_output_files(),
		"output/annotation/heatmap_of_peaks_on_TSS.pdf",
		"output/annotation/read_count_frequency_of_peaks.pdf"
	conda:
		"../envs/chipseeker_clusterprofiler.yaml"
	params:
		species = config["MACS2"]["species"],
		upstream = 2000,
		downstream = 2000,
		output_dir = "output/annotation"
	log:
		"logs/annotation/chipseeker.log"
	threads:
		config["processors"]
	script:
		"../scripts/chipseeker.R"

#################### annotation ####################
rule motif_analysis:
	input:
		expand("output/callpeak/{sample}/{sample}_peaks.narrowPeak.final", sample=get_transcription()["sample"].unique()),
		expand("output/callpeak/{sample}/{sample}_peaks.broadPeak.final", sample=get_histone()["sample"].unique())
	output:
		expand("output/motif/{sample}/homerResults.html", sample=mocks["sample"].unique())
	log:
		"logs/output/motif.log"
	params:
		config["ref"]["name"]
	run:
		shell("export PATH=$PATH:$(pwd)/homer/bin")
		for i in range(len(input)):
			peak = input[i]
			output_dir = os.path.split(peak)[0]		# items in output and input may be not in the same order
			output_dir = output_dir.replace("callpeak", "motif") # so use input item instead
			cmd = "findMotifsGenome.pl {peak} {params} {output} -len 8,10,12 -p 8 1>{log} 2>&1"
			cmd = cmd.format(peak=peak,
							params=params,
							output=output_dir,
							log=log)
			shell(cmd)