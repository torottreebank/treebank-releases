# -*- coding: utf-8 -*-

require 'rubygems'
require 'nokogiri'


gold = File.open(ARGV[0])
comp  = File.open(ARGV[1])

doc = Nokogiri::XML(gold,nil,'utf-8') 

doc2 = Nokogiri::XML(comp,nil,'utf-8')

gld = [385013, 385014, 385015, 385016, 385017, 385018, 385019, 385020, 385021, 385022, 385023, 385024, 385025, 385026, 385027, 385028, 385029, 385030, 385031, 385032, 385033, 385034, 385035, 385036, 385037, 385038, 385039, 385040, 385041, 385042, 385043, 385044, 385045, 385046, 385047, 385048, 385049, 385050, 385051, 385052, 385053, 385054, 385055, 385056, 385057, 385058, 385059, 385060, 385061, 385062, 385063, 385064, 385065, 385066, 385067, 385068, 385069, 385070]

prs = [50089, 30218, 42757, 49114, 58320, 51063, 12418, 50207, 26978, 39349, 26707, 46002, 52078, 32950, 37233, 23717, 48524, 32569, 57599, 48606, 31221, 24116, 2673, 31472, 2257, 18229, 45552, 28727, 27256, 50989, 27535, 35148, 1702, 58001, 33235, 26185, 43271, 55354, 15524, 57701, 35764, 9692, 56915, 2528, 27883, 18810, 17242, 50030, 32185, 3014, 56813, 42831, 51089, 4294, 27713, 46104, 27387, 51836]


STC = gld.zip(prs).to_h

STDERR.puts STC

def find_slashes(t)
  slashes = []
  if t.children.select {|s| s.name == 'slash'}.any?
    t.children.select {|s| s.name == 'slash'}.each do |sl|
      slashes <<  [sl['relation'],sl['target-id']]
    end
  end
  return slashes
end

def slash_target(t,p,match)
  if find_slashes(t).any? and find_slashes(p).any?
    ts = find_slashes(t)
    ps = find_slashes(p)
    return match[ts.first[1]['head-id']] == ps.first[1]['head-id']
  elsif find_slashes(t).any? 
    return "missing slash"
  elsif find_slashes(p).any? 
    return "extra slash"
  else
    return "no slash"
  end
end

def slash_relation(t,p)
  if find_slashes(t).any? and find_slashes(p).any?
    ts = find_slashes(t)
    ps = find_slashes(p)
    return ts.first[0] == ps.first[0]
  elsif find_slashes(t).any? 
    return "missing slash"
  elsif find_slashes(p).any? 
    return "extra slash"
  else
    return "no slash"
  end
end

def return_slash_relation(t)
  if find_slashes(t).any?
    s = find_slashes(t)
    return s.first[0]
  else
    return "no slash"
  end
end

STDOUT.puts "gold_sentence,comp_sentence,id,comp_id,gold_form,comp_form,gold_empty_type,comp_empty_type,lemma,morph,attachment,label_attachment,empty_token_sort,slash_number,gold_slashes,comp_slashes,slash_relation,slash_target,relation_match,pos_match,morph_match,gold_slash_rel,comp_slash_rel"



doc.search('//sentence').each do |s|
  STDERR.puts s['status']
  if STC.keys.include?(s['id'].to_i) and s['status']== 'reviewed'
    STDERR.puts "now running on #{s['id']}" 
    alid = STC[s['id'].to_i].to_s
    STDERR.puts alid.inspect 
    sp = doc2.search('//sentence').select { |sp| sp['id'] == alid }.first
    spt = []
    spid = []
    sp.children.each do |t|
      if t.name == 'token'
        spt << t
        spid << t['id']
      end
    end
    tks = []
    ids = []
    s.children.each do |t|
      if t.name == 'token'
        tks << t
        ids << t['id']
      end
    end
    match = ids.zip(spid).to_h
    STDERR.puts "gold has #{tks.size} tokens, comp has #{spt.size}" if tks.size != spt.size

    STDERR.puts match.inspect if tks.size != spt.size
    spares = []
    if tks.size < spt.size
      spt.each do |t|
        unless tks.select { |gt| match[gt['id']] == t['id']}.any?
          STDERR.puts "#{t['id']} is a spare"
          spares << t
        end
      end
    end

    tks.each do |t|
        p = spt.select { |tk| tk['id'] == match[t['id']] }.first
      STDOUT.puts [
                   s['id'],
                   sp['id'],
                   t['id'],
                   (p ? p['id'] : "no match"),
                   t['form'],
                   (p ? p['form'] : "no match"),
                   t['empty-token-sort'],
                   (p ? p['empty-token-sort'] : "no match"),
                   (p ? [t['lemma'],t['part-of-speech']].join('.') == [p['lemma'],p['part-of-speech']].join('.') : "no match"),
                   (p ? t['morphology'] == p['morphology'] : "no match"),
                   (p ? match[t['head-id']] == p['head-id'] : "no match"),
                   (p ? (t['relation'] == p['relation'] and match[t['head-id']] == p['head-id']): "no match"),
                   (p ? t['empty-token-sort'] == p['empty-token-sort'] : "no match"),
                   (p ? find_slashes(t).size == find_slashes(p).size : "no match"),
                   find_slashes(t).size,
                   (p ? find_slashes(p).size : "no match"),
                   (p ? slash_relation(t,p) : "no match"),
                   (p ? slash_target(t,p,match) : "no match"),
                   (p ? "#{t['relation']}:#{p['relation']}" : "no match"),
                   (p ? "#{t['part-of-speech']}:#{p['part-of-speech']}" : "no match"),
                   (p ? "#{t['morphology']}:#{p['morphology']}" : "no match" ),
                   return_slash_relation(t),
                   (p ? return_slash_relation(p) : "no match")
                   
                   ].join(',')
    end
    spares.each do |p|
      STDERR.puts "now running on spare #{p['id']}"
      STDOUT.puts [
                   s['id'],
                   sp['id'],
                   "no match",
                   p['id'],
                   "no match",
                   p['form'],
                   "no match",
                   p['empty-token-sort'],
                   "no match",
                   "no match",
                   "no match",
                   "no match",
                   "no match",
                   "no match",
                   "no match",
                   find_slashes(p).size,
                   "no match",
                   "no match",
                   "no match",
                   "no match"
                   ].join(',')
    end
  end
end









