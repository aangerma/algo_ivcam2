
target_dist = (1:1:7) * 1000;
code_length = 52;
code_reps = 50;
dynamic_range1 = [0 7];
dynamic_range2 = [1 6];
measur1_struct = struct('z_std', zeros(length(target_dist), 1), 'z_mean', zeros(length(target_dist), 1), 'dist', zeros(length(target_dist), 1), 'dynamic_range', dynamic_range1);
measur2_struct = measur1_struct;
measur2_struct.dynamic_range = dynamic_range2;

for k = 1: length(target_dist)
    [targt_dist_vec_1] = dynamic_range_test(dynamic_range1, target_dist(k), code_length, code_reps);
    
    [targt_dist_vec_2] = dynamic_range_test(dynamic_range2, target_dist(k), code_length, code_reps);
    
    %------------------------------------------------------------------------------------------------------------------
    figure;
    plot(1:length(targt_dist_vec_1), targt_dist_vec_1, 1:length(targt_dist_vec_1), targt_dist_vec_2);
    title(['Target distance with a ' num2str(code_length) ' code with target at ' num2str(target_dist(k)) ' [mm]' ]);
    hold on;
    plot(1:length(targt_dist_vec_1), repmat(max(targt_dist_vec_1), length(targt_dist_vec_1)), 'g');
    plot(1:length(targt_dist_vec_1), repmat(min(targt_dist_vec_1), length(targt_dist_vec_1)), 'g');
    plot(1:length(targt_dist_vec_1), repmat(max(targt_dist_vec_2), length(targt_dist_vec_1)), 'c');
    plot(1:length(targt_dist_vec_1), repmat(min(targt_dist_vec_2), length(targt_dist_vec_1)), 'c');
    legend(['DynRng: [' num2str(dynamic_range1(1)) ' ' num2str(dynamic_range1(2)) ']'], ['DynRng: [' num2str(dynamic_range2(1)) ' ' num2str(dynamic_range2(2)) ']']);
    
    %------------------------------------------------------------------------------------------------------------------
    measur1_struct.dist(k,1) = target_dist(k);
    measur2_struct.dist(k,1) = target_dist(k);
    
    measur1_struct.z_mean(k,1) = mean(targt_dist_vec_1);
    measur2_struct.z_mean(k,1) = mean(targt_dist_vec_2);
    
    measur1_struct.z_std(k,1) = std(targt_dist_vec_1);
    measur2_struct.z_std(k,1) = std(targt_dist_vec_2);
    disp(['Finished  iteration ' num2str(k) '/' num2str(length(target_dist))]);
end

figure;
plot(measur1_struct.dist, measur1_struct.z_mean, measur2_struct.dist, measur2_struct.z_mean);
xlabel('Distance [mm]'); ylabel('Mean [mm]');
legend('DynRng: [0 7]', 'DynRng: [1 6]');
grid on;

figure;
plot(measur1_struct.dist, measur1_struct.z_std, measur2_struct.dist, measur2_struct.z_std);
xlabel('Distance [mm]'); ylabel('Z STD [mm]');
legend(['DynRng: [' num2str(dynamic_range1(1)) ' ' num2str(dynamic_range1(2)) ']'], ['DynRng: [' num2str(dynamic_range2(1)) ' ' num2str(dynamic_range2(2)) ']']);
grid on;