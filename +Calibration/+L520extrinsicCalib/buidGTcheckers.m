function [gtL_v] = buidGTcheckers(gridSize,targetOffset,squareSize)
ln = gridSize(1)*gridSize(2);
%[gty, gtx] = ndgrid(0:gridSize(1)-1,0:gridSize(2)-1);
[gty, gtx] = ndgrid(targetOffset.offY:targetOffset.offY+gridSize(1)-1,targetOffset.offX:targetOffset.offX+gridSize(2)-1);
gty = flipud(gty*squareSize);
gtx = gtx*squareSize;
gtz = gtx*0;
gtx_v = reshape(gtx,1,ln);
gty_v = reshape(gty,1,ln);
gtz_v = reshape(gtz,1,ln);
gtL_v = [gtx_v ; gty_v ; gtz_v];
end

