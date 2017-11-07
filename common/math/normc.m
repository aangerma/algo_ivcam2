function n = normc(m)
n = bsxfun(@rdivide,m,sqrt(sum(m.^2)));
end
