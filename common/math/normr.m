function n = normr(m)
n = m./sqrt(sum(m.^2,2));
end