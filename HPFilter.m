function [fsig] = HPFilter(sig,Fc,T)

  c1 = 1/(1+tan(Fc*pi*T));
  c2 = (1-tan(Fc*pi*T))/(1+tan(Fc*pi*T));

  sigLen = length(sig);

  fsig = zeros(1,sigLen);
  
  fsig(1) = c1*sig(1);
  for i=2:sigLen
    fsig(i)=c2*fsig(i-1)+c1*(sig(i)-sig(i-1));
  end

end