BEGIN{FS=","}
NR==1{n=NF; next}
NF!=n{c++; print NR}
END{print c+0}
