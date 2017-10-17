function r=cellmode(x)

y = unique(x);
n = zeros(length(y), 1);
for iy = 1:length(y)
  n(iy) = length(find(strcmp(y{iy}, x)));
end
[~, itemp] = max(n);
r=y{itemp};
end