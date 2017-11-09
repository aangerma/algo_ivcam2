function n = normr(m)
n = bsxfun(@rdivide,m,sqrt(sum(m.^2,2)));;
end