BEGIN { 
    FS=","
    Total=0
    Correct=0
    Tested=0
    NumClasses=0
    if (k == "") k=1
    if (m == "") m=2
}
NR==1 { next }
NR<=11 { train(); next }
{ 
  c=classify()
  if (c == $NF) Correct++
  Tested++
  train() 
}
END {
    print "Accuracy: " (Correct/Tested) * 100 "%"
}

function train(    i,c) {
  Total++; c=$NF
  if (Classes[c]++ == 0) NumClasses++
  
  for(i=1; i<NF; i++) {
    if($i=="?") continue
    Freq[c,i,$i]++
    if(++Seen[i,$i]==1) Attr[i]++ 
  }
}

function classify(    i,c,t,best,bestc) {
  best=-1e30
  for(c in Classes) {
    t=log((Classes[c] + m)/(Total + m * NumClasses))
    
    for(i=1; i<NF; i++) {
      if($i=="?") continue
      t+=log((Freq[c,i,$i] + k)/(Classes[c] + k * Attr[i])) 
    }
    if(t>best) { best=t; bestc=c }
  }
  return bestc 
}