import scipy.io as sio
import numpy as np
import torch
import torch.nn.functional as F
# from torch.utils.data import DataLoader
from tensorboardX import SummaryWriter
import argparse
import matplotlib.pyplot as plt
from utils import *
import simulator
import time
import os

# os.environ["CUDA_LAUNCH_BLOCKING"] = "1"
os.environ["CUDA_VISIBLE_DEVICES"] = "0"

parser = argparse.ArgumentParser(description='PyTorch')
parser.add_argument('--nVal', type=int, default=10, help='number of epochs to train for')
parser.add_argument('--batch_size', type=int, default=1000, help='batch size')
parser.add_argument('--cuda', type=int, default=1, help='use cuda?')
parser.add_argument('--log_dir', type=str, default='/home/administrator/ivcam/tx_learning/test0.65')

opt = parser.parse_args()

sample_dist = 0.0187314  # in m
system_delay =0 # 0.2046 #0.6658 # 7.397
dist_min=0.500
dist_max=4.000
albedo_min=0.3
albedo_max=1
rx_sim = simulator.Simulator0

if opt.cuda:
    device = 'cuda'
else:
    device = 'cpu'

# template_real = torch.rand(1, 1, 512, device=device)
# template_real = torch.nn.Parameter(template_real)
temp = sio.loadmat('codes.mat')
code_index=4
txcode_real = torch.tensor(temp['codes'][0,code_index-1]['code'], device=device).float().squeeze()
txcode_real = torch.tensor(np.load(opt.log_dir+'/best_code.npy'), device=device)
txcode_real = torch.nn.Parameter(txcode_real)
code_length=txcode_real.shape[0]
max_dist = sample_dist * code_length * 8

def evaluate():
    # total_loss=0
    total_l1_loss = 0
    total_l1_feasible = 0
    total_infeasible = 0
    iter = 0
    plt.plot(txcode_real.detach().cpu().numpy())
    plt.show()
    for i in range(opt.nVal):
        with torch.no_grad():
            target_dist = torch.rand(opt.batch_size, device=device) * (dist_max - dist_min) + dist_min
            rx_code = rx_sim(txcode_real, target_dist,albedo_min, albedo_max)
            input_c, input = build_inputs(rx_code)

            # # template_3bit = torch.nn.Parameter(real_to_3bit(template_real))
            template_real = txcode_real.repeat_interleave(8).unsqueeze(0).unsqueeze(0)
            template_real_c = txcode_real.repeat_interleave(2).unsqueeze(0).unsqueeze(0)

            output_c = coarse_corr(input_c, template_real_c)
            output = fine_corr(output_c, input, template_real)
            output = output * sample_dist
            output = (output - system_delay) % max_dist

            l1_loss, hinge_loss, l1_feasible, infeasible = losses(output, target_dist)
            total_l1_loss += l1_loss.item()
            total_l1_feasible += l1_feasible.item()
            total_infeasible += infeasible
            iter += 1
            if i==0:
                plt.plot(target_dist.cpu().numpy(), output.cpu().numpy(), '+')
                plt.savefig('learned.png')
    return total_l1_loss / iter, total_l1_feasible / iter, total_infeasible / iter


if __name__ == '__main__':
    # for code_index in range(0,11):
    #     txcode_real = torch.tensor(temp['codes'][0, code_index]['code'], device=device).float().squeeze()
    #     txcode_real = torch.nn.Parameter(txcode_real)
    #     code_length = txcode_real.shape[0]
    #     max_dist = sample_dist * code_length * 8
    #     l1_loss, l1_feasible, infeasible = evaluate()
    #     print(temp['codes'][0, code_index]['name'])
    #     print(f'L1 Loss: {l1_loss:.4f}, L1 feasible: {l1_feasible:.4f}, infeasible: {infeasible * 100:.2f}%')

    l1_loss, l1_feasible, infeasible = evaluate()
    print(opt.log_dir)
    print(f'L1 Loss: {l1_loss:.4f}, L1 feasible: {l1_feasible:.4f}, infeasible: {infeasible * 100:.2f}%')
