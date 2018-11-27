# -*- coding: utf-8 -*-
# @Author: XiZhihui
# @Date:   2018-11-22 17:49:53
# @Last Modified by:   XiZhihui
# @Last Modified time: 2018-11-27 19:39:28
# @Description: quality statistics and correlation analysis and output a HTML report

#################### fastqc  ####################


#################### mapping statistics ####################


#################### ChIP quality ####################
rule chipqc:
	input:
		narrow_peaks = expand("output/callpeak/{m.sample}/{m.sample}-{m.unit}_peaks.narrowPeak", m=get_transcription().itertuples()),
		broad_peaks = expand("output/callpeak/{m.sample}/{m.sample}-{m.unit}_peaks.broadPeak", m=get_histone().itertuples()),
		narrow_bams = expand("output/mapping/{m.sample}-{m.unit}.rmdup.bam", m=get_transcription().itertuples()),
		broad_bams = expand("output/mapping/{m.sample}-{m.unit}.rmdup.bam", m=get_histone().itertuples()),
		control_bams = expand("output/mapping/{u.sample}-{u.unit}.rmdup.bam", u=units.loc["Control_MockIP", ["sample", "unit"]].itertuples()),
		index = expand("output/mapping/{u.sample}-{u.unit}.rmdup.bam.bai", u=units[["sample", "unit"]].itertuples())
	output:
		"output/qc/chipqc/ChIPQC.html"
	conda:
		"../envs/chipseeker_clusterprofiler.yaml"
	log:
		"logs/qc/chipqc.log"
	threads:
		config["processors"]
	params:
		ref = config["ref"]["name"],
		mocks = config["mocks"],
		output_dir = "output/qc/chipqc",
		bam_path = "output/mapping",
		peak_path = "output/callpeak",
		blacklist = config["MACS2"]["blacklist"]
	script:
		"../scripts/chipqc.R"