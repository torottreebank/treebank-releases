This folder contains files that fall into the following four categories:

CONVERSION OUTPUT:
syn-NAME.xml: converted xml files in the PROIEL/TOROT format

sentence_ids.txt: column 1: "new id", i.e. sentence id in the resulting xml files; column 2: "old id", sentence id in the original tgt file.

critical_flags.txt: ids of those sentences for which the converter knows it cannot convert them correctly. They will be marked as "Unannotated". For some of them the information about the syntactic structure will be completely erased (see info about flags.txt). Column 1: old id, column 2: new id.

nonvroots.txt: ids of those sentences that do not have verb as a root in the original. It also contains info about which method called the method for adding the empty verb (as required by the PROIEL standard) and which nodes were involved.

dub_nargs.txt: the list of the tokens that were assigned a NARG relation which the converter finds dubious. Column 1: new id; Column 2: token id; column 3: the reason for the converter's doubt.

flags.txt: a collection of various warnings produced by different methods in the conversion script. There is a scale (1-4) which shows how likely it is that the converted sentences contains an error and a scale (A-E) which shows how important the error can be (primarily for argument structure studies, since that's what the script was originally created for). "Minas Tirith filter" (the last-hope filter)  means that the final filter (applied after the conversion) finds an important error. "Tree erased" means that the Minas Tirith filter found an error that makes it impossible for the sentence to pass the TOROT validator; syntactic information is completely erased for such sentences (they are marked as "Unannotated" and will be listed in the "critical_flags.txt", too.)"

wordstat.txt: word counts.

CONVERSION TOOLS:
convert.rb: the conversion script. See below for the instructions.
posfreq.csv: a frequency list the converter is using to distinguish between proper and common nouns.

To run the conversion script, you'll need Ruby 1.9+ with the Nokogiri gem installed.
Run the script from the command line: 

Ruby convert.rb syntagrus.tgt, 

where syntagrus.tgt is the path to the single tgt file containing the original Syntagrus. In order to extract the metadata the script also needs the folder "syntagrus_all_files" with the original tgt files from the 2014 we are using. Contact us if you need these files.

EVALUATION TOOLS:
sample.tgt: 100 sentences in the original SynTagRus format randomly drawn from all sentences labelled as "annotated"

sample.xml: the same sample converted to the TOROT format 

sample_gold.xml: the same sample with the annotation manually corrected by the authors 

compare_aligned.rb: a script that compares two proiel-xml files of the same annotated passage (the requirements are the same as for convert.rb). Run the script from the command line:

ruby compare_aligned.rb sample_gold.xml sample.xml

compare.csv: the output of compare_aligned.rb run on sample_gold.xml and sample.xml

compare.r: an R script that produces evaluation statistics on the basis of compare.csv (UAS, LAS, morphology, lemma, secondary dependency accuracy)

2019-01-16