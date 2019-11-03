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
import os
os.environ["CUDA_VISIBLE_DEVICES"]="1"

## genearal parameters
parser = argparse.ArgumentParser(description='PyTorch GC-Net Example')
parser.add_argument('--nEpochs', type=int, default=1000, help='number of epochs to train for')
parser.add_argument('--lr', type=float, default=1e-3, help='Learning Rate. Default=0.001')
parser.add_argument('--cuda', type=int, default=1, help='use cuda?')
parser.add_argument('--data_train', type=str, default='/home/administrator/ivcam/datasets/data32/average2/train/', help="data root")
parser.add_argument('--data_val', type=str, default='/home/administrator/ivcam/datasets/data32/average2/val/', help="data root")
parser.add_argument('--log_dir', type=str, default='/home/administrator/ivcam/32/fine_coarse_summary/average2_1e-3')
opt = parser.parse_args()
sample_dist=0.0187314 # in m
system_delay=7.397
max_dist=sample_dist*512
learn_fine = True
learn_coarse = True

train_set = CodeDataset(opt.data_train)
val_set = CodeDataset(opt.data_val)
training_data_loader = DataLoader(dataset=train_set, num_workers=4, batch_size=1, shuffle=True)
val_data_loader = DataLoader(dataset=val_set, num_workers=4, batch_size=1, shuffle=False)
if opt.cuda:
    device='cuda'
else:
    device='cpu'

## init templates
# template_real = torch.rand(1, 1, 512, device=device) # random
# template_real_c = torch.rand(1, 1, 128, device=device)

temp = sio.loadmat('codes.mat') # from codes.mat file (all recorded data is 64bit so we can use only 64bit codes - best to init with the recorded code
code_index=2
txcode_real = torch.tensor(temp['codes'][0,code_index-1]['code'], device=device).float().squeeze()
txcode_real = txcode_real.flip(0)
code_length = txcode_real.shape[0]
max_dist = sample_dist * code_length * 8
template_real = torch.nn.Parameter(txcode_real.repeat_interleave(8).unsqueeze(0).unsqueeze(0).detach(),requires_grad=learn_fine)
template_real_c = torch.nn.Parameter(txcode_real.repeat_interleave(2).unsqueeze(0).unsqueeze(0).detach(),requires_grad=learn_coarse)
optimizer = torch.optim.Adam([template_real,template_real_c], lr=opt.lr, betas=(0.9, 0.999))

def evaluate():
    total_l1_loss =0
    total_l1_feasible=0
    total_infeasible=0
    iter=0
    for batch in val_data_loader:
        with torch.no_grad():
            fast, slow, target = batch
            target=target.squeeze(0).squeeze(0)/1000
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
            iter+=1
    return total_l1_loss / iter, total_l1_feasible / iter, total_infeasible / iter

if __name__ == '__main__':
    writer = SummaryWriter(log_dir=opt.log_dir)
    addfigure( template_real[0, 0, :],'Fine_Template',0, writer)
    addfigure( template_real_c[0, 0, :],'Coarse_Template', 0, writer)

    best_loss=1e12
    best_epoch=0
    best_coarse = template_real_c[0, 0, :].detach().cpu().numpy()
    best_fine = template_real[0, 0, :].detach().cpu().numpy()
    total_time = time.time()

    for epoch in range(opt.nEpochs):
        # if epoch%20==0:
        #     opt.lr/=5
        train_loss = 0
        global_step = epoch * len(training_data_loader)
        start_time = time.time()
        for iteration, batch in enumerate(training_data_loader):
            fast, slow, target = batch
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
            optimizer.zero_grad()
            l1_loss.backward()
            optimizer.step()

            with torch.no_grad():
                template_real_c.data = template_real_c.clamp(0, 1)
                template_real.data = template_real.clamp(0, 1)

            train_loss+=l1_loss.item()
            if iteration%10==0:
                print(f'Epoch {epoch+1}: {iteration}/{len(training_data_loader)}, Train Loss: {train_loss/(iteration+1):.4f}')
                writer.add_scalar('Training Loss', train_loss / (iteration + 1),  global_step+iteration)
        l1_loss, l1_feasible, infeasible = evaluate()
        print(f'Epoch {epoch+1}, L1 Loss: {l1_loss:.4f},  L1 feasible: {l1_feasible:.4f}, infeasible: {infeasible * 100:.2f}%, Time: {(time.time()-start_time)/60:.2f}')
        writer.add_scalar('L1 Loss', l1_loss, epoch+1)
        writer.add_scalar('L1 feasible loss', l1_feasible, epoch+1)
        writer.add_scalar('infeasible', infeasible, epoch+1)
        addfigure(template_real[0, 0, :], 'Fine_Template', epoch + 1, writer)
        addfigure(template_real_c[0, 0, :],'Coarse_Template', epoch + 1, writer)
        
        val_loss=l1_loss
        if val_loss < best_loss:
            best_loss = val_loss
            best_coarse = template_real_c[0,0,:].cpu().detach().numpy()
            best_fine = template_real[0,0,:].cpu().detach().numpy()
            best_epoch=epoch+1

        np.save(opt.log_dir + '/best_fine', best_fine)
        sio.savemat(opt.log_dir + '/best_fine.mat',{'fine_template':best_fine})
        np.save(opt.log_dir + '/best_coarse', best_coarse)
        sio.savemat(opt.log_dir + '/best_coarse.mat', {'fine_template': best_coarse})

    writer.close()
    print(opt.log_dir)
    print(f'Finish training, best loss: {best_loss} at epoch {best_epoch}, total time: {(time.time()-total_time)/3600} hours')