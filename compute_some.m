%RECORDS="100 104 114 117 215 s20011 s20021 s20031 s20041";
RECORDS="s20011 s20021 s20031 s20041 s20051 s20061 s20071 s20081 s20091 s20101";
record_list = split(RECORDS, ' ');

for i = 1:length(record_list)
   path = record_list(i);
   %path = append('ltst/', record_list(i));
   Detector(path); 
end
