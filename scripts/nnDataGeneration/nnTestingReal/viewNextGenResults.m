r_d = load('X:\Data\IvCam2\NN\JFIL\depthResults\random_depth_full.mat');
noisy = padarray(r_d.noisy,[380/2 540/2],max(r_d.gt(:)),'both');
out = padarray(r_d.out,[380/2 540/2],max(r_d.gt(:)),'both');
gt = padarray(r_d.gt,[380/2 540/2],max(r_d.gt(:)),'both');

ivbin_viewer({noisy,out,gt})

r_d = load('X:\Data\IvCam2\NN\JFIL\depthResults\true_image_depth_full.mat');
noisy = r_d.noisy;
out = r_d.out;
gt = r_d.gt;

ivbin_viewer({noisy,out,gt})

r_d = load('X:\Data\IvCam2\NN\JFIL\depthResults\random_depth_patch_full.mat');
noisy = padarray(r_d.noisy,[380/2 540/2],max(r_d.gt(:)),'both');
out = padarray(r_d.out,[380/2 540/2],max(r_d.gt(:)),'both');
gt = padarray(r_d.gt,[380/2 540/2],max(r_d.gt(:)),'both');
ivbin_viewer({noisy,out,gt})


r_d = load('X:\Data\IvCam2\NN\JFIL\depthResults\sintel.mat');
noisy = r_d.noisy;
out = r_d.out;
gt = r_d.gt;
ivbin_viewer({noisy,out,gt})