function Detector( record )
  % Summary of this function and detailed explanation goes here

  % First convert the record into matlab (creates recordm.mat):
  % wfdb2mat -r record
  fileName = sprintf('%s', record);
  fprintf(append('Loading file: ', fileName, '\n'));
  t=cputime();
  idx = QRSDetect(fileName);
  fprintf('Running time: %f\n', cputime() - t);
  asciName = sprintf('%s.asc',record);
  fid = fopen(asciName, 'wt');
  for i=1:size(idx,1)
      fprintf(fid,'0:00:00.00 %d N 0 0 0\n', idx(i,1) );
  end
  fclose(fid);

  % Now convert the .asc text output to binary WFDB format:
  % wrann -r record -a qrs <record.asc
  % And evaluate against reference annotations (atr) using bxb:
  % bxb -r record -a atr qrs
end

