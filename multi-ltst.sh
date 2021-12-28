
## Script for running C program and evaluation of the algorithm.
##########

rm eval1.txt
rm eval2.txt

FILES=ltst/*.dat


for f in $FILES
do
  f=$(basename $f)
  f=${f%.*}
  
  wrann -r ltst/$f -a det < ltst/$f.asc
  bxb -r ltst/$f -a atr det -l eval1.txt eval2.txt
 done
 
# Calculate aggregate statistics
sumstats eval1.txt eval2.txt >results.txt


# dat - signal recordings from the database
# atr - reference annotations from the database
# qrs - annotations of implemented algorithm
# results.txt - final statistics for reporting

# If your implementation is in Matalab, then comment out compiling and running
# the C program and just use the part for evaluation (bxb and sumstats).

# Other explanations of how to run programs and convert records and annotation 
# files are described on the web-classrom under certain laboratory sessions.
