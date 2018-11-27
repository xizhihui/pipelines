# Details about the pipeline

## Workflow

This pipeline contains these modules:

* preprocess: quality control on raw reads
* alignment: mappint to the reference, get uniquely mapped reads and deduplicate
* callpeak: peak calling with MACS2
* qcchip: quality control on peak calling results
* downstream: downstream analysis like annotate the peaks, motif analysis, enrich analysis
* report: statistics with all the output and reprot a html

![workflow](dag.png)

## Preprocess

By convention, quality control on raw reads is a first necessary step to do NGS anaslysi and is performed here with **FastQC** and **Trimmomatic**. The default parameters of Trimmomatic are:

* TRAILING:5 
* EADING:4
* LIDINGWINDOW:4:5
* INLEN:25
* LLUMINACLIP:adapter.fa:2:30:10

You can change it with yaml syntax in `config.yaml`:

```
	trimmomatic_pe:
	  - param1
	
	trimmomatic_se:
	  - param2
```

## Alignment

After mappint to the reference genome, the mapping quality and uniquely mapped reads are both important things in a ChIP-seq analysis. Here we use "samtools" to filter the low MAPQ reads and get uniquely mapped reads with the command `samtools view -q 20 -b in.bam > out.bam`. 

MACS2 can do the deduplication with the parameter "--keep-dup" through a default value "1", that's why many people won't deduplicate the bams. However, for the sake of estimation of extension size used in the peak model, we deduplicate the bams with "samtools rmdup".

## Callpeak

### peak calling

There are two types of peaks in the output of MACS2, narrow peaks, broad peaks, and gapped peaks. In most situations, transcription factors' ChIP results are the narrow peaks and the broad peaks are from the result of the ChIP experiment with histone modifiction. As for the gapped peaks, they emerge with broad peaks in MACS2. In the [crazyhottommy's pilot-analysis](https://github.com/crazyhottommy/ChIP-seq-analysis/blob/master/part1_peak_calling.md#results-from-pilot-analysis), using "--broad" definetly improve the identification of peaks(or more appropriately:enriched regions), and thus we use the `--broad` to do the histone modification peak calling. However, a narrow peak calling is still used for the transcription factors peak calling. These can be done with different setting of MACS2 paramters.

```
	# broad peak calling, extsize is from the run_SPP.R result
	macs2 callpeak --broad --broad-cutoff 0.1 --nomodel --extsize $extsize <other options>

	# narrow peak calling, let optional parameter be default
	macs2 callpeak <other options>

```

### replicates' reproducibility

In some ChIP-analysis, they first merge all the replicates bams and call peaks with MACS2; then call peaks with replicates seperately, finally regard the peaks both in merged peaks and seperated peaks as the final peak. However, in general, it is not a good idea to combine the reads from biological replicates for the sake of variances within samples in the sample groups and between groups. As is mentioned in [hbctraining's course](https://github.com/hbctraining/In-depth-NGS-Data-Analysis-Course/blob/master/sessionV/lessons/07_handling-replicates-idr.md), IDR suits for the situation. Why IDR? hbctraining gives:

1. IDR avoids choices of initial cutoffs, which are not comparable for different callers
2. IDR does not depend on arbitrary thresholds and so all regions/peaks are considered.
3. It is based on ranks, so does not require the input signals to be calibrated or with a specific fixed scale (only order matters).

In the ENCODE's ChIP-seq pipeline, they only do the IDR frame analysis with the transcription factors. Why? I did't figure it out yet and I decided to follow the ENCODE. As for the histone modification peak calling, I will regard the peaks shared in all replicates as the reproducible peaks by using "bedtools". There are three parts of idr analysis:

* Peak consistency between true replicates
* Peak consistency between pooled pseudoreplicates
* Self-consistency analysis

**Here we just do the first part in the pipeline.**

### blacklist

Functional genomics experiments based on next-gen sequencing (e.g. ChIP-seq, MNase-seq, DNase-seq, FAIRE-seq) that measure biochemical activity of various elements in the genome often produce artifact signal in certain regions of the genome. It is important to keep track of and filter artifact regions that tend to show artificially high signal (excessive unstructured anomalous reads mapping). This can also be done with "bedtools". For details, see below.


## Quality control on ChIP

We use the R package "ChIPQC" for the ChIP's quality assessment. In it's report, we can get three main values to indicate the quality of a ChIP.

### SSD

The SSD score is a measure used to indicate evidence of enrichment. It provides a measure of read pileup across the genome and is computed by looking at the standard deviation of signal pile-up along the genome normalised to the total number of reads. A "good" or enriched sample typically has regions of significant read pile-up so a higher SSD is more indicative of better enrichment. Basically, SSD scores are dependent on the degree of total genome wide signal pile-up, and therefore they are sensitive to regions of artificially high signal in addition to genuine ChIP enrichment. So we need to look closely at the rest of the output of ChIPQC to be sure that the high SSD in samples is actually a result of ChIP enrichment and not some unknown artifact(s).

### RiP: Fraction of Reads in Peaks

RiP (also called FRiP) reports the percentage of reads that overlap within called peaks. This is another good indication of how ”enriched” the sample is, or the success of the immunoprecipitation. It can be considered a ”signal-to-noise” measure of what proportion of the library consists of fragments from binding sites vs. background reads. RiP values will vary depending on the protein of interest:

A typical good quality TF with successful enrichment would exhibit a RiP around 5% or higher.
A good quality PolII would exhibit a RiP of 30% or higher.
There are also known examples of good datasets with FRiP < 1% (i.e. RNAPIII).
In our dataset, RiP percentages are higher for the Nanog replicates as compared to Pou5f1, with Pou5f1-rep2 being very low. This is perhaps an indication that the poor SSD scores for Nanog may not be predictive of poor quality.

### RiBL: Reads overlapping in Blacklisted Regions

It is important to keep track of and filter artifact regions that tend to show artificially high signal (likely due to excessive unstructured anomalous reads mapping). The blacklisted regions typically appear uniquely mappable so simple mappability filters do not remove them. These regions are often found at specific types of repeats such as centromeres, telomeres and satellite repeats. The signal from blacklisted regions has been shown to contribute to confound peak callers and fragment length estimation.


## References

* [hbctraining](https://github.com/hbctraining/In-depth-NGS-Data-Analysis-Course/)
* [crazyhotommy](https://github.com/crazyhottommy/ChIP-seq-analysis/blob/master/part0_quality_control.md#encode-guidlines)
* [chilin](http://cistrome.org/chilin/_downloads/instructions.pdf)
* [ENCODE](http://www.ncbi.nlm.nih.gov/pubmed/22955991)
* [Phantompeakqualtools](https://github.com/kundajelab/phantompeakqualtools)
* [Irreproducibility Discovery Rate](https://github.com/nboley/idr)