import scipy.io as sio
import numpy as np
import torch
import torch.nn.functional as F
from torch.utils.data import DataLoader
from tensorboardX import SummaryWriter
import argparse
import matplotlib.pyplot as plt
from utils import *
import time
import scipy.io as sio
import os
from torch.autograd import Variable
os.environ["CUDA_VISIBLE_DEVICES"]="1"

## genearal parameters
parser = argparse.ArgumentParser(description='PyTorch GC-Net Example')
parser.add_argument('--cuda', type=int, default=1, help='use cuda?')
parser.add_argument('--data_val', type=str, default='/home/administrator/ivcam/datasets/data32/average4/val/', help="data root")
parser.add_argument('--log_dir', type=str, default='/home/administrator/ivcam/32/fine_coarse_summary/test32_1e-3_/')
opt = parser.parse_args()
sample_dist=0.0187314 # in m
system_delay=7.397
max_dist=sample_dist*512

if opt.cuda:
    device='cuda'
else:
    device='cpu'

## init templates
# temp = sio.loadmat('codes.mat') # from codes.mat file (all recorded data is 64bit so we can use only 64bit codes - best to init with the recorded code
# code_index=2
# txcode_real = torch.tensor(temp['codes'][0,code_index-1]['code'], device=device).float().squeeze()
# txcode_real = txcode_real.flip(0)
# code_length = txcode_real.shape[0]
# max_dist = sample_dist * code_length * 8
# template_real = txcode_real.repeat_interleave(8).unsqueeze(0).unsqueeze(0).detach()
# template_real_c = txcode_real.repeat_interleave(2).unsqueeze(0).unsqueeze(0).detach()

temp=np.load(opt.log_dir+'/best_fine.npy')                                          # init the learned templates
template_real=torch.tensor(temp, device=device).float().unsqueeze(0).unsqueeze(0)
temp=np.load(opt.log_dir+'/best_coarse.npy')
template_real_c=torch.tensor(temp, device=device).float().unsqueeze(0).unsqueeze(0)
code_length = template_real_c.shape[2]//2
max_dist = sample_dist * code_length * 8

def evaluate():
    total_l1_loss =0
    total_l1_feasible=0
    total_infeasible=0
    total_invalid=0
    iter=0
    file_list = os.listdir(opt.data_val)
    for file_name in file_list:
        temp=sio.loadmat(opt.data_val+file_name)
        fast=torch.tensor(temp['fast']).permute(1,0).unsqueeze(1).float()
        target=torch.tensor(temp['dist'].astype(float)).float()
        with torch.no_grad():
            target = target.squeeze(0).squeeze(0) / 1000
            if opt.cuda:
                fast = fast.cuda()
                target = target.cuda()

            input_c, input = build_inputs(fast.squeeze())

            output_c = coarse_corr(input_c, template_real_c)
            output = fine_corr(output_c, input, template_real)
            output = output * sample_dist
            output = (output - system_delay) % max_dist

            l1_loss, hinge_loss, l1_feasible, infeasible = losses(output, target)
            total_l1_loss += l1_loss.item()
            total_l1_feasible += l1_feasible.item()
            total_infeasible += infeasible
            iter += 1
            sio.savemat(opt.log_dir+'/rec/'+file_name,{'target':target.cpu().numpy(),'output':output.cpu().numpy()})
            if file_name=='171.mat':
                plt.figure()
                plt.plot(target.cpu().numpy(),output.cpu().numpy(),'+')
                plt.savefig('scatter.png')

    return total_l1_loss / iter, total_l1_feasible / iter, total_infeasible / iter, total_invalid/iter

if __name__ == '__main__':
    plt.plot(template_real.cpu().numpy().squeeze())
    plt.savefig('template.png')
    os.makedirs(opt.log_dir+'rec/', exist_ok=True)
    l1_loss,  l1_feasible, infeasible,invalid = evaluate()
    print(opt.log_dir)
    print(f'Finish, L1 Loss: {l1_loss:.4f}, L1 feasible: {l1_feasible:.4f}, infeasible: {infeasible*100:.2f}%,invalid: {invalid*100:.2f}%')
