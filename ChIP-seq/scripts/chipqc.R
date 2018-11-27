# @Author: XiZhihui
# @Date:   2018-11-25 22:55:59
# @Last Modified by:   XiZhihui
# @Last Modified time: 2018-11-26 16:52:03
# @Description: quality control on a ChIP experiment or sample with ChIPQC

options(stringAsFactors=F)

# read paramas
annotation <- snakemake@params$ref
mocks_file <- snakemake@params$mocks
output_dir <- snakemake@params$output_dir
bam_path <- snakemake@params$bam_path
peak_path <- snakemake@params$peak_path
reference <- snakemake@params$ref
blacklist <- snakemake@params$blacklist
log <- snakemake@log[[1]]

# log and helper
logfile <- file(log, "wt")
sink(logfile)
sink(logfile, type="message")
loginfo <- function(info) {
	info <- paste("[ Info in ChIPQC ]:", info, "\n")
	cat(info)
}

cat(paste("annotation: ", annotation, "\n"))
cat(paste("mocks_file: ", mocks_file, "\n"))
cat(paste("output_dir: ", output_dir, "\n"))
cat(paste("log: ", log, "\n"))

suppressPackageStartupMessages({
	library(ChIPQC)
})

# read mocks_file and prepare metadata
	# sample	unit	mock_sample	mock_unit	type
	# H2Aub1	rep1	Control_MockIP	rep1	tf
	# H2Aub1	rep2	Control_MockIP	rep2	tf
	# H3K36me3	rep1	Control_MockIP	rep1	hm
	# H3K36me3	rep2	Control_MockIP	rep2	hm
	# Ring1B	rep1	Control_MockIP	rep1	tf
	# Ring1B	rep2	Control_MockIP	rep2	tf
loginfo("prepare metadata...")

add_Peaks <- function(type, sample, unit) {
	suffix <- ifelse(type == "tf", "_peaks.narrowPeak", "_peaks.broadPeak")
	filename <- paste0(sample, "-", unit, suffix)
	file.path(peak_path, sample, filename)
}
add_bams <- function(sample, unit) {
	filename <- paste0(sample, "-", unit, ".rmdup.bam")
	file.path(bam_path, filename)
}

# SampleID Replicate bamReads bamControl ControlID 
mocks <- read.table(mocks_file, header=T)
tissue <- mocks$tissue
condition <- mocks$condition 
metadata <- dplyr::transmute(mocks,
				SampleID=paste(sample, unit, sep="."),
				Replicate=unit,
				Factor=sample,
				Tissue=ifelse(is.null(tissue), rep(NA, length(sample)), tissue),
				Condition=ifelse(is.null(condition), rep(NA, length(sample)), condition),
				ControlID=paste(mock_sample, mock_unit, sep="-"),
				bamReads=add_bams(sample, unit),
				bamControl=add_bams(mock_sample, mock_unit),
				Peaks=add_Peaks(type, sample, unit))

loginfo("quality control .....")
experiment = ChIPQC(metadata, 
					annotation=reference,
					blacklist=blacklist)
try({
	ChIPQCreport(experiment, facet=T,
			facetBy=c("Factor"),
			reportFolder=output_dir)
})

# plotCoverageHist(experiment,facetBy="SampleID")
# plotCC(tamoxifen,facetBy=c("Tissue","Factor"))
# # Plotting Relative Enrichment of reads in Genomic Intervals
# plotRegi(tamoxifen,facetBy=c("Tissue","Condition"))
# # Plots of composite peak profile
# plotPeakProfile(tamoxifen,facetBy=c("Tissue","Condition"))
# # Barplots of the relative number of reads that overlap peaks vs. background reads, 
# # as well and the proportion of reads overlapping blacklisted regions
# plotRap(tamoxifen,facetBy=c("Tissue","Condition"))
# plotFribl(tamoxifen,facetBy=c("Tissue","Condition"))
# # sample clustering
# plotCorHeatmap(tamoxifen,attributes=c("Tissue","Factor","Condition","Replicate"))
# # pca plot
# plotPrincomp(tamoxifen,attributes=c("Tissue","Condition"))

# ggsave(file="coverage_hist.png", device="png")

# saveimg <- function(experiment, func, filename, device="png", ...) {
# 	func(experiment, ...)
# 	ggsave(filename, device=device)
# }
# saveimg(experiment, plotCC, filename="cross_coverage.png", facetBy=c("Factor"))
# saveimg(experiment, plotRegi, filename="relative_enrichment_of_reads.png", facetBy="SampleID")
# saveimg(experiment, plotPeakProfile, filename="composite_peak_profile.png", facetBy="SampleID")