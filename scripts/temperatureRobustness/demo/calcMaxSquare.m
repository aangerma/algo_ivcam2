function     [pmaxSquareL,pmaxSquareA,pEdges,edgErr] = calcMaxSquare(px,py,pz)
pmaxSquareL = [];
pmaxSquareA = [];
edgErr = [];
v = cat(3,px,py,pz);
pEdges = [norm(squeeze(v(1,1,:)-v(1,end,:)));
          norm(squeeze(v(1,end,:)-v(end,end,:)));
          norm(squeeze(v(end,end,:)-v(end,1,:)));
          norm(squeeze(v(end,1,:)-v(1,1,:)))];

end

