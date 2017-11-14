function [ X_offset, Y_offset ] = findImageTranslation ( ref_image, tested_image )

[optimizer, metric] = imregconfig('monomodal');
% estimates the geometric transformation that aligns tester_image with the ref_image
tform = imregtform(ref_image,tested_image, 'translation', optimizer, metric);

X_offset = tform.T(3,1);
Y_offset = tform.T(3,2);

end