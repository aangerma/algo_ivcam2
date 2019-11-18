function interpretFailedCBDetection(ir, errMsgTitle)

midRow = ceil(size(ir,1)/2);
if all(ir(midRow,:)==0)
    error('%s: Failed to detect checkerboard (image is probably split)', errMsgTitle)
else
    error('%s: Failed to detect checkerboard (something went wrong)', errMsgTitle)
end

end