%% I assume I have:
% frames - a struct array with the fields:
%   1. temperatures - ldd and more
%   2. GID, maximal error on edge of checkerboard
%   3. Median error, RMS error, 95% error.

% Create a stream that updates every 0.25 second, it shows:
% The frame itself, and graphs of the GID + max, and Ldd graph over time.

% Add a bar that moves forward in time.