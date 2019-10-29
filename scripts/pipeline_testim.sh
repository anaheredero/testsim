
cd /home/user15/Desktop/Testim/testsim
export WD=$(pwd)

#E.coli genome...
echo "Downloading E.coli genome..."
mkdir res/genome
wget -O res/genome/ecoli.fasta.gz ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz
gunzip -k res/genome/ecoli.fasta.gz

#index
cd $WD
echo "Running STAR index..."
mkdir -p res/genome/star_index
STAR --runThreadN 4 --runMode genomeGenerate \
--genomeDir res/genome/star_index/ \
--genomeFastaFiles res/genome/ecoli.fasta \
--genomeSAindexNbases 9

for sampleid in $(ls data/*.fastq.gz | cut -d "_" -f1 | sed 's:data/::' | sort | uniq)
do
#fastQC
echo "Running FastQC..."
mkdir -p out/fastqc
fastqc -o out/fastqc data/${sampleid}*.fastq.gz

#cutadapt
echo "Running cutadapt - removing sequencing adapters..."
cd $WD
mkdir out/cutadapt
mkdir log/cutadapt
cutadapt -m 20 -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT \
-o out/cutadapt/${sampleid}_1.trimmed.fastq.gz \
-p out/cutadapt/${sampleid}_2.trimmed.fastq.gz data/${sampleid}_1.fastq.gz data/${sampleid}_2.fastq.gz > log/cutadapt/${sampleid}.log

#alignment
cd $WD
echo "Running STAR alignment..."
mkdir -p out/star/${sampleid}
STAR --runThreadN 4 --genomeDir res/genome/star_index/ \
--readFilesIn out/cutadapt/${sampleid}_1.trimmed.fastq.gz out/cutadapt/${sampleid}_2.trimmed.fastq.gz \
--readFilesCommand zcat \
--outFileNamePrefix out/star/${sampleid}/
done

#multiQC
cd $WD
echo "Running multiQC in order to create a report..."
multiqc -o out/multiqc $WD
cd out/multiqc
firefox multiqc_report.html

echo "FINALLY DONE!!!"
