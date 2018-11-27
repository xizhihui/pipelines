# -*- coding: utf-8 -*-
# @Author: XiZhihui
# @Date:   2018-11-25 18:53:01
# @Last Modified by:   XiZhihui
# @Last Modified time: 2018-11-25 19:01:17
# @Description: idr

import snakemake.shell as shell

in_files = snakemake.input
output = snakemake.output
log = snakemake.log

temps = [i + ".temp" for i in in_files]
print(temps)
for (i,temp) in zip(in_files, temps):
	shell("sort -k8,8nr {} > {}".format(i, temp))

# $ idr --samples Pou5f1_Rep1_sorted_peaks.narrowPeak Pou5f1_Rep2_sorted_peaks.narrowPeak \
# --input-file-type narrowPeak \
# --rank p.value \
# --output-file Pou5f1-idr \
# --plot \
# --log-output-file pou5f1.idr.log

idr_cmd = "idr --samples {} ".format(" ".join(temps))
idr_cmd += "--input-file-type narrowPeak --rank p.value --plot "
idr_cmd += "--output-file {} ".format(output[0])
idr_cmd += "--log-output-file {} ".format(log)
shell(idr_cmd)
shell("rm {}".format(" ".join(temps)))
