a = read.csv('compare.csv')


library(xtable)

print("ATTACHMENT SITE")

a$attachment <- factor(a$attachment, c("false","true","no match"))

aattachment = table(a$attachment)

print(aattachment)

print(prop.table(aattachment)*100)


print("LABELED ATTACHMENT SITE")

alab = table(a$label_attachment)

print(prop.table(alab)*100)

print("MORPHOLOGY")

a$morph <- factor(a$morph, c("false","true","no match"))
amorph = table(a$morph)
print(prop.table(amorph)*100)

print("LEMMA.POS INTERACTION")

a$lemma <- factor(a$lemma, c("false","true","no match"))
alemma = table(a$lemma)
print(prop.table(alemma)*100)


print("SLASH RELATION LABEL")
a$slash_relation <- factor(a$slash_relation, c("no match","no slash","true","extra slash","missing slash"))
aslashrel = table(a$slash_relation)
print(prop.table(aslashrel)*100)

print("SLASH TARGET")

a$slash_target <- factor(a$slash_target, c("no match","no slash","true","extra slash","missing slash"))
aslashtarget = table(a$slash_target)
print(prop.table(aslashtarget)*100)

print("CORRECT SLASHES")
print("Share of slashes with correct label and target")
print(nrow(subset(a, interaction(slash_relation,slash_target)=='true.true'))/nrow(subset(a, comp_slashes == 1)))
print("Recall for XSUB slashes")
print(nrow(subset(a, interaction(slash_relation,slash_target)=='true.true'))/nrow(subset(a, gold_slashes == 1)))


print("MISMATCH STATISTICS")
las = droplevels(subset(a, label_attachment == 'false'))
mrph = droplevels(subset(a, morph == 'false'))
pos = droplevels(subset(a, lemma == 'false'))

print(table(las$relation_match))
print(table(mrph$morph_match))
print(table(pos$pos_match))











