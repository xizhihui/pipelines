# @Author: XiZhihui
# @Date:   2018-11-23 20:01:06
# @Last Modified by:   XiZhihui
# @Last Modified time: 2018-11-26 18:49:19
# @Description: analysis peaks with ChIPSeeker

# get params
peakfiles <- unlist(snakemake@input)
samples <- sapply(peakfiles, function(peakfile) {
	filename <- basename(peakfile)
	filename <- gsub("_peaks\\.(narrowPeak|broadPeak).final", "", filename)
	filename
})
log <- snakemake@log[[1]]
output_dir <- snakemake@params$output_dir	# filenames: output_dir/sample/xxxx.pdf
species <- snakemake@params$species
upstream <- snakemake@params$upstream
downstream <- snakemake@params$downstream

# logging
logfile <- file(log, "wt")
sink(logfile)
sink(logfile, type="message")
# helper for log
loginfo <- function(info) {
	info <- paste("[ Info in ChIPseeker.R ]:", info, "\n")
	cat(info)
}

cat(paste("peaksfiles:", peakfiles, "\n"))
cat(paste("samples:", samples, "\n"))
cat(paste("log: ", log, "\n"))
cat(paste("output_dir: ", output_dir, "\n"))
cat(paste("species: ", species, "\n"))

suppressPackageStartupMessages(library(ChIPseeker))
if (species == "mm") {
	suppressPackageStartupMessages({
		library(org.Mm.eg.db)
		library(TxDb.Mmusculus.UCSC.mm10.knownGene)
	})
	txdb = TxDb.Mmusculus.UCSC.mm10.knownGene
	orgdb = org.Mm.eg.db
} else if (species == "hs") {
	suppressPackageStartupMessages({
		library(org.Hs.eg.db)
		library(TxDb.Hsapiens.UCSC.hg38.knowGene)
	})
	txdb = TxDb.Mmusculus.UCSC.mm10.knowGene
	orgdb = org.Mm.eg.db
} else if (species == "ce") {
	source("http://bioconductor.org/biocLite.R")
	biocLite("org.Ce.eg.db")
	biocLite("TxDb.Celegans.UCSC.ce11.refGene")
	suppressPackageStartupMessages({
		library(org.Ce.eg.db)
		library(TxDb.Celegans.UCSC.ce11.refGene)
	})
	txdb = TxDb.Celegans.UCSC.ce11.refGene
	orgdb = org.Ce.eg.db
} else if (species == "dm") {
	source("http://bioconductor.org/biocLite.R")
	biocLite("org.Dm.eg.db")
	biocLite("TxDb.Dmelanogaster.UCSC.dm6.ensGene")
	suppressPackageStartupMessages({
		library(org.Dm.eg.db)
		library(TxDb.Dmelanogaster.UCSC.dm6.ensGene)
	})
	txdb = TxDb.Dmelanogaster.UCSC.dm6.ensGene
	orgdb = org.Dm.eg.db
}

## helper for save pdf
savepdf <- function(aim, suffix, func, peaks_name=NULL, ...) {
	if (is.null(peaks_name)) {
		filename = file.path(output_dir, suffix)
	} else {
		filename = file.path(output_dir, peaks_name, suffix)
	}
	cat(filename)
	pdf(file=filename)
	print(func(aim, ...))
	# ggplot2::ggsave(filename=file.path(output_dir, peaks_name, suffix), device="pdf")
	dev.off()
	# loginfo(file.path(output_dir, peaks_name, suffix))
}


## read files and get gene region
promoter <- getBioRegion(TxDb=txdb, upstream=upstream, downstream=downstream, by='gene')
peaks_list = sapply(peakfiles, readPeakFile)
names(peaks_list) <- samples
loginfo("compute tag_matrix_list...")
tag_matrix_list = lapply(peaks_list, getTagMatrix, windows=promoter)
names(tag_matrix_list) <- samples
loginfo("compute tag_matrix_list completed.")
##########################
# for cycle begins
##########################
for (i in 1:length(peakfiles)) {
	peaks_name <- samples[i]
	peaks <- peaks_list[[peaks_name]]

########################## peak 在基因组上的富集区域，plot peak coverage ##########################
	loginfo(paste("run go here: line 90, ", peaks_name))
	savepdf(aim=peaks,
			peaks_name=peaks_name,
			suffix="peaks_over_chromosomes.pdf",
			func=covplot,
			title=paste(peaks_name, "peaks over Chromosomes", sep=" - "))

########################## heatmap of peaks on TSS upstream and downstream ##########################
	# heatmap of peaks on TSS upstream and downstream
	tag_matrix <- tag_matrix_list[[peaks_name]]
	# heatmap of peaks on TSS upstream and downstream
	savepdf(aim=tag_matrix,
			peaks_name=peaks_name,
			suffix="heatmap_of_peaks_on_TSS.pdf",
			func=tagHeatmap,
			xlim=c(-upstream, downstream),
			color='red',
			xlab="Heatmap on TSS",
			title=peaks_name)

	# read count frequency of peaks
	savepdf(aim=tag_matrix,
			peaks_name=peaks_name,
			suffix="read_count_frequency_of_peaks.pdf",
			func=plotAvgProf,
			xlim=c(-upstream, downstream),
            xlab="Genomic Region (5'->3')", 
            ylab="Read Count Frequency",
            title=paste(peaks_name, "read count frequency of peaks", sep=" - "),
            conf=0.95, resample=1000)

######################### peak annotation #########################
	loginfo(paste("run go here: line 123, ", peaks_name))
	peakAnno = annotatePeak(peaks, 
	                        tssRegion=c(-upstream, downstream), 
	                        TxDb=txdb)
	savepdf(aim=peakAnno, peaks_name=peaks_name, suffix="annotation_pie.pdf", func=plotAnnoPie)

	savepdf(aim=peakAnno, peaks_name=peaks_name, suffix="annotation_bar.pdf", func=plotAnnoBar)

	# vennpie(peakAnno)
	savepdf(aim=peakAnno, 
			peaks_name=peaks_name, 
			suffix="annotation_upset.pdf",
			func=upsetplot,
			vennpie=T)

	savepdf(aim=peakAnno,
			peaks_name=peaks_name,
			suffix="annotation_distance_to_TSS.pdf",
			func=plotDistToTSS,
			title=paste(peaks_name, 'Distribution of TF-binding loci relative to TSS', sep=" - "))
}
##########################
# for cycle ends
##########################
# combine multiple heatmap and read count frequency of peaks together
##########################
# heatmap of peaks on TSS upstream and downstream
savepdf(aim=tag_matrix_list,
		suffix="heatmap_of_peaks_on_TSS.pdf",
		func=tagHeatmap,
		xlim=c(-upstream, downstream),
		xlab="Heatmap on TSS")

# # read count frequency of peaks
savepdf(aim=tag_matrix_list,
		suffix="read_count_frequency_of_peaks.pdf",
		func=plotAvgProf,
		xlim=c(-upstream, downstream),
        xlab="Genomic Region (5'->3')", 
        ylab="Read Count Frequency",
        title=paste("read count frequency of peaks", sep=" - "),
        conf=0.95, resample=1000)