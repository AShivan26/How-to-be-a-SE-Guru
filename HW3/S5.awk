BEGIN{FS=","}
NR==1{next}
{cnt[$0]++}
END{for(k in cnt) if(cnt[k]>1) d+=cnt[k]; print d}
