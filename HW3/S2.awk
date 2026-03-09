BEGIN{FS=","}
NR==1{for(i=1;i<=NF;i++)h[i]=$i; next}
{r=0; for(i=1;i<=NF;i++) if($i=="?"){c[i]=1;r=1} if(r){print NR; n++}}
END{print n+0; for(i in c)print h[i]}
