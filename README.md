The TOROT Treebank
==================

The _TOROT Treebank_ is a dependency treebank with morphosyntactic and
information-structure annotation. It includes texts in several stages of Slavic and is freely available under a [Creative Commons
Attribution-NonCommercial-ShareAlike 3.0 License](
http://creativecommons.org/licenses/by-nc-sa/3.0/us/).

Please cite as

> Hanne Martine Eckhoff and Aleksandrs Berdicevskis. 2015. 'Linguistics vs. digital editions: The Tromsø Old Russian and OCS Treebank'. Scripta & e-Scripta 2015 14–15, pp. 9-25.

Releases of the ISWOC Treebank are hosted on
[Github](https://github.com/torottreebank/treebank-releases).

Contents
--------

The following texts are included in this release of the treebank:

  Text                                                | Language                    | Filename    | Size
  ----                                                | --------                    | --------    | ----
  Codex Suprasliensis                            	  | Old Church Slavonic         | supr        | 67196 tokens
  Apollonius of Tyre                                  | Old Russian                 | lav         | 56683 tokens

(The 'size' column in the table above shows the number of annotated tokens in
a text. The number of tokens will be slightly larger than the number of words
in the original printed edition as some words have been split into multiple
tokens and some tokens have been inserted during annotation.)

Please see the XML files for detailed metadata and a full list of contributors.

Data formats
------------

The texts are available on two formats:

1. PROIEL XML: These files are the authoritative source files and the only ones
that contain all available annotation. They contain the complete morphological,
syntactic and information-structure annotation, as well as the complete text,
including punctuation, section headers etc. The schema is defined in
[`proiel.xsd`](https://github.com/proiel/proiel-treebank/blob/master/proiel.xsd).

2. [CoNLL-X format](http://nextens.uvt.nl/depparse-wiki/DataFormat)
