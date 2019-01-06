function [rng_STD, rng_mean, percent_in_rng] = get_STD_mean_within_range(orig_arr, rang)
new_dist_arr = orig_arr(orig_arr > rang(1) & orig_arr < rang(2));
rng_STD = std(new_dist_arr);
rng_mean = mean(new_dist_arr);

percent_in_rng = 100*length(new_dist_arr)/length(orig_arr);
end