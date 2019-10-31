import scipy.io as sio
import numpy as np
import torch
import torch.nn.functional as F
from torch.utils.data import DataLoader
import torch.optim as optim
from tensorboardX import SummaryWriter
import matplotlib.pyplot as plt
from utils import *
from cor_model import cor_model, cor_model2
import argparse
import time
import os
os.environ["CUDA_VISIBLE_DEVICES"]="3"

## genearal parameters
parser = argparse.ArgumentParser(description='PyTorch GC-Net Example')
parser.add_argument('--nEpochs', type=int, default=2000, help='number of epochs to train for')
parser.add_argument('--lr', type=float, default=1e-4, help='Learning Rate. Default=0.001')
parser.add_argument('--cuda', type=int, default=1, help='use cuda?')
parser.add_argument('--data_train', type=str, default='/home/administrator/ivcam/datasets/data32/average4/train/', help="data root")
parser.add_argument('--data_val', type=str, default='/home/administrator/ivcam/datasets/data32/average4/val/', help="data root")
parser.add_argument('--ch', type=int, default=4, help='num of channels')
parser.add_argument('--log_dir', type=str, default='/home/administrator/ivcam/ttt/32/cor_summary/average4_lr_1e-4decay500_model/')

opt = parser.parse_args()
train_set = CodeDataset(opt.data_train)
val_set = CodeDataset(opt.data_val)
training_data_loader = DataLoader(dataset=train_set, num_workers=2, batch_size=1, shuffle=True)
val_data_loader = DataLoader(dataset=val_set, num_workers=2, batch_size=1, shuffle=False)

model=cor_model(ch=opt.ch)
if opt.cuda:
    model = torch.nn.DataParallel(model).cuda()
optimizer = optim.Adam(model.parameters(), lr=opt.lr, betas=(0.9, 0.999))
scheduler = torch.optim.lr_scheduler.StepLR(optimizer, step_size=500, gamma=0.33)

def evaluate():
    total_l1_loss =0
    total_l1_feasible=0
    total_infeasible=0
    iter=0
    for batch in val_data_loader:
        with torch.no_grad():
            fast, slow, target = batch
            slow = slow.repeat_interleave(64,dim=3)/4000
            input=torch.cat((fast,slow),dim=2)
            input = input.squeeze(0)
            target=target.squeeze(0).squeeze(0)/1000
            if opt.cuda:
                input = input.cuda()
                target = target.cuda()

            output=model(input).squeeze(1)

            l1_loss, hinge_loss, l1_feasible, infeasible = losses(output, target)
            total_l1_loss += l1_loss.item()
            total_l1_feasible += l1_feasible.item()
            total_infeasible += infeasible
            iter += 1
        return total_l1_loss / iter, total_l1_feasible / iter, total_infeasible / iter

if __name__ == '__main__':
    writer = SummaryWriter(log_dir=opt.log_dir)
    best_loss = 1e12
    best_epoch = 0
    total_time = time.time()

    for epoch in range(opt.nEpochs):
        train_loss = 0
        global_step = epoch * len(training_data_loader)

        start_time=time.time()
        for iteration, batch in enumerate(training_data_loader):
            fast, slow, target = batch
            slow = slow.repeat_interleave(64,dim=3)/4000
            input=torch.cat((fast,slow),dim=2)
            input = input.squeeze(0)
            target=target.squeeze(0).squeeze(0)/1000
            if opt.cuda:
                input = input.cuda()
                target = target.cuda()

            output=model(input).squeeze(1)

            l1_loss, hinge_loss, l1_feasible, infeasible = losses(output, target)
            loss=l1_loss
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
            train_loss+=loss.item()
            if iteration%10==0:
                print(f'Epoch {epoch+1}: {iteration}/{len(training_data_loader)}, Train Loss: {train_loss/(iteration+1):.4f}')
                writer.add_scalar('Training Loss', train_loss/(iteration+1), global_step+iteration)
        l1_loss, l1_feasible, infeasible = evaluate()
        print(
            f'Epoch {epoch + 1}, L1 Loss: {l1_loss:.4f}, L1 feasible: {l1_feasible:.4f}, infeasible: {infeasible * 100:.2f}%, Time: {(time.time() - start_time) / 60:.2f}')

        writer.add_scalar('L1 Loss', l1_loss, epoch + 1)
        writer.add_scalar('L1 feasible loss', l1_feasible, epoch + 1)
        writer.add_scalar('infeasible', infeasible, epoch + 1)
        val_loss = l1_loss
        if val_loss < best_loss:
            best_loss = val_loss
            best_epoch=epoch+1
            torch.save({'epoch': epoch, 'state_dict': model.state_dict(),
                        'optimizer': optimizer.state_dict()}, opt.log_dir + "best_model.pth")
        scheduler.step()

    writer.close()
    print(opt.log_dir)
    print(f'Finish training, best loss: {best_loss} at epoch {best_epoch}, total time: {(time.time() - total_time) / 3600:.2f} hours')

