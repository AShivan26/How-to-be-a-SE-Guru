BEGIN { FS=","; Total=0 }
NR==1 { next }
NR<=11 { train(); next }
{ c=classify(); print $NF" "c; train() }

function train(    i,c) {
  Total++; c=$NF; Classes[c]++
  for(i=1; i<NF; i++) {
    if($i=="?") continue
    Freq[c,i,$i]++
    if(++Seen[i,$i]==1) Attr[i]++ }}

function classify(    i,c,t,best,bestc) {
  best=-1e30
  for(c in Classes) {
    t=log(Classes[c]/Total)
    for(i=1; i<NF; i++) {
      if($i=="?") continue
      t+=log((Freq[c,i,$i]+1)/(Classes[c]+Attr[i])) }
    if(t>best) { best=t; bestc=c }}
  return bestc }
