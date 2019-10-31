import scipy.io as sio
import numpy as np
import torch
import torch.nn.functional as F
from tensorboardX import SummaryWriter
import argparse
import matplotlib.pyplot as plt
from utils import *
import simulator
import time
import os

os.environ["CUDA_VISIBLE_DEVICES"] = "0"

## genearal parameters
parser = argparse.ArgumentParser(description='PyTorch')
parser.add_argument('--nEpochs', type=int, default=10000, help='number of epochs to train for')
parser.add_argument('--nVal', type=int, default=1, help='number of epochs to train for')
parser.add_argument('--batch_size', type=int, default=100, help='batch size')
parser.add_argument('--lr', type=float, default=1e-1, help='Learning Rate. Default=0.001')
parser.add_argument('--cuda', type=int, default=1, help='use cuda?')
parser.add_argument('--log_dir', type=str, default='/home/administrator/ivcam/tx_learning/test_sim_init1_template_1e-1')

opt = parser.parse_args()
code_length=64
sample_dist = 0.0187314  # in m
system_delay = 0.2046 # 7.397
dist_min=0.500
dist_max=4.000
albedo_min=0.3
albedo_max=1
learn_template = True
rx_sim = simulator.Simulator

if opt.cuda:
    device = 'cuda'
else:
    device = 'cpu'

## init tx code
# template_real = torch.rand(64, device=device)  # random
# template_real = torch.nn.Parameter(template_real)
temp = sio.loadmat('codes.mat')
code_index=1
txcode_real = torch.tensor(temp['codes'][0,code_index-1]['code'], device=device).float().squeeze() # from codes.mat file
# txcode_real = torch.ones(code_length, device=device).float()*0.5 # init code to flat 0.5
txcode_real = torch.nn.Parameter(txcode_real)
code_length=txcode_real.shape[0]
max_dist = sample_dist * code_length * 8

if learn_template:
    template_real = torch.nn.Parameter(txcode_real.repeat_interleave(8).unsqueeze(0).unsqueeze(0).detach())
    template_real_c = torch.nn.Parameter(txcode_real.repeat_interleave(2).unsqueeze(0).unsqueeze(0).detach())
    optimizer = torch.optim.Adam([txcode_real,template_real,template_real_c], lr=opt.lr, betas=(0.9, 0.999))
else:
    optimizer = torch.optim.Adam([txcode_real], lr=opt.lr, betas=(0.9, 0.999))
# scheduler = torch.optim.lr_scheduler.StepLR(optimizer, step_size=25, gamma=0.33)



# def build_inputs(rx_code):
#     input_c = rx_code.view(rx_code.shape[0], rx_code.shape[1] // 4, 4)
#     input_c = input_c.sum(dim=2)
#     input_c = input_c.unsqueeze(1).repeat(1, 1, 2)
#     input_c = input_c[:, :, :-1]
#
#     input = rx_code.unsqueeze(1).repeat(1, 1, 2)
#     input = input[:, :, :-1]
#     return input_c, input
#
# def coarse_corr(input_c, template_real_c):
#     corr_c = F.conv1d(input_c, template_real_c).squeeze(1)
#     corr_c = F.softmax(corr_c, dim=1)
#     corr_c = corr_c * torch.arange(1, 1+code_length*2, device=device).view(1, code_length*2).float()
#     output_c = corr_c.sum(dim=1)
#     return output_c * 4
#
# def fine_corr(index, input, template_real):
#     # index_int = torch.floor(index).long()
#     # w1 = (index - index_int.float()).unsqueeze(1)
#     # w0 = (1 - index + index_int.float()).unsqueeze(1)
#     # mask = w0 * ker[torch.fmod(index_int,512), :] + w1 * ker[torch.fmod(index_int+1,512), :]
#     mask0 = torch.arange(-31, code_length*8+33, device=device).float().unsqueeze(0).repeat(index.shape[0], 1)
#     index = index.unsqueeze(1).float()
#     mask0 = torch.sigmoid(mask0 - (index - 16)) + torch.sigmoid(-mask0 + (index + 16)) - 1
#     mask = mask0[:, 32:-32]
#     mask[:, :32] = mask[:, :32] + mask0[:, -32:]
#     mask[:, -32:] = mask[:, -32:] + mask0[:, :32]
#
#     corr = F.conv1d(input, template_real).squeeze(1)
#     corr = corr * mask
#     corr = F.softmax(corr, dim=1)
#     corr = corr * torch.arange(1, 1+code_length*8, device=device).view(1, code_length*8).float()
#     output = corr.sum(dim=1)
#     return output

def evaluate(txcode,template,template_c):
    # total_loss=0
    total_l1_loss = 0
    total_l1_feasible = 0
    total_infeasible = 0
    iter = 0
    for i in range(opt.nVal):
        with torch.no_grad():
            target_dist = torch.rand(opt.batch_size, device=device) * (dist_max - dist_min) + dist_min
            rx_code = rx_sim(txcode, target_dist,albedo_min, albedo_max)
            input_c, input = build_inputs(rx_code)

            output_c = coarse_corr(input_c, template_c)
            output = fine_corr(output_c, input, template)
            output = output * sample_dist
            output = (output - system_delay) % max_dist

            l1_loss, hinge_loss, l1_feasible, infeasible = losses(output, target_dist)
            total_l1_loss += l1_loss.item()
            total_l1_feasible += l1_feasible.item()
            total_infeasible += infeasible
            iter += 1
    return total_l1_loss / iter, total_l1_feasible / iter, total_infeasible / iter


if __name__ == '__main__':
    writer = SummaryWriter(log_dir=opt.log_dir)
    addfigure(txcode_real,'Tx_Code',0, writer)

    best_loss = 1e12
    best_epoch = 0
    best_code = txcode_real.detach().cpu().numpy()

    total_time = time.time()
    for epoch in range(opt.nEpochs):
        # scheduler.step()
        # if epoch==14:
        #     optimizer.param_groups[0]['lr']=1e-5
        start_time = time.time()

        target_dist=torch.rand(opt.batch_size,device=device)*(dist_max-dist_min)+dist_min
        rx_code=rx_sim(txcode_real,target_dist,albedo_min, albedo_max)
        input_c ,input = build_inputs(rx_code)

        # template_3bit = torch.nn.Parameter(real_to_3bit(template_real))
        if not learn_template:
            template_real = txcode_real.repeat_interleave(8).unsqueeze(0).unsqueeze(0).detach()
            template_real_c = txcode_real.repeat_interleave(2).unsqueeze(0).unsqueeze(0).detach()

        output_c = coarse_corr(input_c, template_real_c)
        output = fine_corr(output_c, input, template_real)
        output = output * sample_dist
        output = (output - system_delay) % max_dist

        l1_loss, sig_loss, l1_feasible, infeasible = losses(output, target_dist)

        optimizer.zero_grad()
        l1_loss.backward()
        optimizer.step()

        with torch.no_grad():
            txcode_real.data = txcode_real.clamp(0, 1)
            template_real.data = template_real.clamp(0, 1)
            template_real_c.data = template_real_c.clamp(0, 1)

        if epoch % 10 == 0:
            # print(f'Epoch {epoch+1}/{len(opt.nEpochs)}, Train Loss: {l1_loss.item():.4f}')
            # writer.add_scalar('Training Loss', l1_loss.item(), epoch)

            l1_loss, l1_feasible, infeasible = evaluate(txcode_real,template_real,template_real_c)
            print(f'Epoch {epoch}, L1 Loss: {l1_loss:.4f}, L1 feasible: {l1_feasible:.4f}, infeasible: {infeasible * 100:.2f}%, Time: {(time.time() - start_time) / 60:.2f}')
            writer.add_scalar('L1 Loss', l1_loss, epoch)
            writer.add_scalar('L1 feasible loss', l1_feasible, epoch)
            writer.add_scalar('infeasible', infeasible, epoch)
            addfigure(txcode_real,'Tx_Code', epoch, writer)
            addfigure(template_real[0,0,:], 'Template', epoch, writer)
            addfigure(template_real_c[0,0,:], 'Coarse Template', epoch, writer)
            val_loss = l1_loss
            if val_loss < best_loss:
                best_loss = val_loss
                best_code = txcode_real.cpu().detach().numpy()
                best_epoch = epoch

            # np.save(opt.log_dir + '/code' + str(epoch), txcode_real.cpu().detach().numpy())
            np.save(opt.log_dir + '/best_code', best_code)
            sio.savemat(opt.log_dir + '/best_code.mat', {'tx_code': best_code})

    writer.close()
    print(opt.log_dir)
    print(f'Finish training, best loss: {best_loss} at epoch {best_epoch}, total time: {(time.time() - total_time) / 3600} hours')