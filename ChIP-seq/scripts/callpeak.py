#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Author: XiZhihui
# @Date:   2018-11-24 21:33:26
# @Last Modified by:   XiZhihui
# @Last Modified time: 2018-11-26 16:29:08
# @Description: peak calling with macs2

import os
import argparse
import subprocess

def parse_args():
	"""
	macs2 callpeak --broad --broad-cutoff 0.1 \
		--nomodel --extsize {}
		-c {input.control} \
		-t {input.treat} \
		--outdir {params.path} \
		-g {params.species} \
		-n {wildcards.sample}-combined \
		1>{log} 2>{log}
	"""
	def add_common_args(par):
		## input/output params
		par.add_argument("-c", metavar="control/mock.bam", help="control bam file", type=str, required=True)
		par.add_argument("-t", metavar="treat/ChIP.bam", help="ChIP bam file", type=str, required=True)
		par.add_argument("--outdir", dest="outdir", help="output directory (default: .)", default=".")
		par.add_argument("-n", help="output file prefix", type=str, default="macs2")
		par.add_argument("-g", help="samples species", required=True, choices=["hs", "mm", "ce", "dm"])
		par.add_argument("--log", dest="log", help="log file", type=str, default="macs2.log")

	parser = argparse.ArgumentParser()

	subparsers = parser.add_subparsers(title="Peak calling",
										description="call peaks for transcription factors or histone modification ?",
										metavar="peak_calling_type")
	
	# transcription factors
	tf = subparsers.add_parser("transcription", help="perform peak calling for transcription factors")
	add_common_args(tf)
	# without any more params

	# histone modification
	hm = subparsers.add_parser("histone", help="perform peak calling for histone modification")
	hm.add_argument("--broad", action="store_true", help="broad peaks calling")
	hm.add_argument("--broad-cutoff", type=float, default=0.1, help="broad-cutoff in broad peak calling")
	hm.add_argument("--nomodel", action="store_true", help="broad peaks calling with no model")
	hm.add_argument("--extsize", type=str, required=True)
	add_common_args(hm)


	args = parser.parse_args()
	return args

def main():
	args = parse_args()
	myargs = vars(args)
	cmd = []
	print(myargs)
	## args shared by transcription factors and histone modifications
	for name in ["c", "t", "g", "n"]:
		cmd.extend(["-"+name, myargs[name]])
	cmd.extend(["--outdir", myargs["outdir"]])

	cmd.extend(["1>{}".format(myargs["log"]), "2>&1"])			# logs

	## histone modifications only
	if "broad" in myargs:
		cmd.append("--broad")
		cmd.extend(["--broad-cutoff", str(myargs["broad_cutoff"])])
	if "nomodel" in myargs:
		cmd.append("--nomodel")
	if "extsize" in myargs:
		# extsize is a required parameter
		with open(myargs["extsize"], "r") as f:
			extsize = f.readlines()[0].strip().split("\t")
			extsize = extsize[2].split(",")[0]
			cmd.extend(["--extsize", extsize])

	cmd = "macs2 callpeak {}".format(" ".join(cmd))
	print(cmd)
	run_status = subprocess.call(cmd, shell=True)	# give the "shell" paramter to regard cmd as a commond string, subprocess.call(["ls", "-l"])
	exit(run_status)

if __name__ == '__main__':
	main()