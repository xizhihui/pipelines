# -*- coding: utf-8 -*-
# @Author: XiZhihui
# @Date:   2018-11-22 16:46:42
# @Last Modified by:   XiZhihui
# @Last Modified time: 2018-11-25 17:17:23
# @Description: common things used in pipeline

import os
import pandas as pd
from snakemake.utils import validate


##### report template #####
#report: "../report/workflow.rst"


##### config validation #####
configfile: "config.yaml"
validate(config, schema="../schemas/config.yaml")

##### sample and units file #####
samples = pd.read_table(config["samples"]).set_index("sample", drop=False)
validate(samples, schema="../schemas/samples.yaml")

units = pd.read_table(config["units"], dtype=str).set_index(["sample", "unit"], drop=False)
units.index = units.index.set_levels([i.astype(str) for i in units.index.levels])  # enforce str in index
validate(units, schema="../schemas/units.yaml")

mocks = pd.read_table(config["mocks"], dtype=str).set_index(["sample", "unit"], drop=False)
mocks.index = mocks.index.set_levels([i.astype(str) for i in mocks.index.levels])
validate(mocks, schema="../schemas/mocks.yaml")


##### rule order ####
# ruleorder: macs2_combined > bedtools_overlap


##### wildcards #####
wildcard_constraints:
	unit = "|".join(units["unit"].unique()),
	sample = "|".join(units["sample"].unique())


##### helpers #####
# email when pipeline is completed or error happens
def send_email(title, log=None):
	if config["email"] != "None":
		if os.path.exists(log):
			info = "grep -A 10 -E '[eE](rror|xception)|Finished' {} |".format(log)
		else:
			info = ''
		cmd = "{info} mail -s '{title}' {email}".format(
				info = info,
				title=title, 
				email=config["email"])
		shell(cmd)

def is_single(wildcards):
	# 这里的 wildcards.sample/unit 要以元组的形式传入，作为一个 index，如果是以数组传入，则是作为 2 个 index （index 列表）
	inputs = units.loc[(wildcards.sample, wildcards.unit), ["fq1", "fq2"]].dropna()
	return len(inputs) == 1

def get_transcription():
	is_tf = mocks["type"] == "tf"
	return mocks[is_tf]

def get_histone():
	is_hm = mocks["type"] == "hm"
	return mocks[is_hm]