function a = prctile(x, p)
  y = sort(x);
  if size (y,1) == 1
     y = y.';
  end
  trim = 1 + (size(y,1)-1)*p(:)*0.01;
  delta = (trim - floor(trim))*ones(1,size(y,2));
  a = y(floor(trim), :) .* delta + y(ceil(trim), :) .* (1-delta);
end
