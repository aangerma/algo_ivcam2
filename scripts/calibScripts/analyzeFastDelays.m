
n = length(delays);

errors = zeros(1,n);
Frames = zeros([size(frames{1}) n]);
for i=1:n
    fprintf('%03u of %u\r', i, n);
    f = double(frames{i});
    %f = fillHolesMM(f);
    Frames(:,:,i) = f;
    %dx = diff(f,1);
    %dy = diff(f,2);
    errors(i) = Calibration.aux.calcDelayCoarseError(f);
end

figure; plot(delays, errors)