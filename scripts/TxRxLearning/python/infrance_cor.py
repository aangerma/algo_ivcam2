import scipy.io as sio
import numpy as np
import torch
import torch.nn.functional as F
from torch.utils.data import DataLoader
import torch.optim as optim
from tensorboardX import SummaryWriter
# import tkinter
# import matplotlib
# matplotlib.use('tkAgg')
import matplotlib.pyplot as plt
from utils import *
from cor_model import cor_model,cor_model2
import argparse
import time
import os
os.environ["CUDA_VISIBLE_DEVICES"]="7"

## genearal parameters
parser = argparse.ArgumentParser(description='PyTorch GC-Net Example')
parser.add_argument('--nEpochs', type=int, default=200, help='number of epochs to train for')
parser.add_argument('--lr', type=float, default=1e-8, help='Learning Rate. Default=0.001')
parser.add_argument('--cuda', type=int, default=1, help='use cuda?')
parser.add_argument('--data_val', type=str, default='/home/administrator/ivcam/datasets/data32/average2/val/', help="data root")
parser.add_argument('--ch', type=int, default=4, help='num of channels')
parser.add_argument('--log_dir', type=str, default='/home/administrator/ivcam/32/cor_summary/only1_lr_1e-3decay_model2/')

opt = parser.parse_args()
sample_dist=0.0187314
system_delay=7.397
max_dist=sample_dist*512

if opt.cuda:
    device='cuda'
else:
    device='cpu'

model=cor_model2(ch=opt.ch)
if opt.cuda:
    model = torch.nn.DataParallel(model).cuda()
optimizer = optim.Adam(model.parameters(), lr=opt.lr, betas=(0.9, 0.999))
checkpoint = torch.load(opt.log_dir +'best_model.pth')
model.load_state_dict(checkpoint['state_dict'], strict=False)
optimizer.load_state_dict(checkpoint['optimizer'])

def evaluate():
    total_l1_loss =0
    total_l1_feasible=0
    total_infeasible=0
    iter=0.
    file_list = os.listdir(opt.data_val)
    for file_name in file_list:
        temp=sio.loadmat(opt.data_val+file_name)
        fast=torch.tensor(temp['fast']).permute(1,0).unsqueeze(1).unsqueeze(0).float()
        slow=torch.tensor(temp['slow'].astype(float)).permute(1,0).unsqueeze(1).unsqueeze(0).float()
        target=torch.tensor(temp['dist'].astype(float)).unsqueeze(0).float()
        with torch.no_grad():
            slow = slow.repeat_interleave(64, dim=3) / 4000
            input = torch.cat((fast, slow), dim=2)
            input = input.squeeze(0)
            target = target.squeeze(0).squeeze(0) / 1000
            if opt.cuda:
                input = input.cuda()
                target = target.cuda()

            output=model(input).squeeze(1)

            l1_loss, hinge_loss, l1_feasible, infeasible = losses(output, target)
            total_l1_loss += l1_loss.item()
            total_l1_feasible += l1_feasible.item()
            total_infeasible += infeasible
            iter+=1
            sio.savemat(opt.log_dir+'rec/'+file_name,{'target':target.cpu().numpy(),'output':output.cpu().numpy()})
            if file_name=='171.mat':
                plt.plot(target.cpu().numpy(),output.cpu().numpy(),'+')
                plt.savefig('1.png')
    return total_l1_loss / iter, total_l1_feasible / iter, total_infeasible / iter

if __name__ == '__main__':
    os.makedirs(opt.log_dir + 'rec/', exist_ok=True)
    l1_loss, l1_feasible, infeasible = evaluate()
    print(opt.log_dir)
    print(f'Finish, L1 Loss: {l1_loss:.4f}, L1 feasible: {l1_feasible:.4f}, infeasible: {infeasible * 100:.2f}%')
