import torch.utils.data as data
import os
import scipy.io as sio
import torch
import torch.nn.functional as F
import matplotlib.pyplot as plt


def build_inputs(rx_code):
    # input - rx_code with shape (batch size, code length * 8)
    # outputs - input, 2 * rx_code for cyclic auto correlation with shape (batch size, 1, rx code length * 16 -1)
    #         - input_c, 2 * decimated rx_code for cyclic auto correlation with shape (batch size, 1, rx code length * 4 -1)
    input_c = rx_code.view(rx_code.shape[0], rx_code.shape[1] // 4, 4)
    input_c = input_c.sum(dim=2)
    input_c = input_c.unsqueeze(1).repeat(1, 1, 2)
    input_c = input_c[:, :, :-1]

    input = rx_code.unsqueeze(1).repeat(1, 1, 2)
    input = input[:, :, :-1]
    return input_c, input

def coarse_corr(input_c, template_real_c):
    corr_c = F.conv1d(input_c, template_real_c).squeeze(1)
    corr_c = F.softmax(corr_c, dim=1)
    corr_c = corr_c * torch.arange(1, 1+template_real_c.shape[2], device=input_c.device).view(1, template_real_c.shape[2]).float()
    output_c = corr_c.sum(dim=1)
    return output_c * 4

def fine_corr(index, input, template_real):
    # inputs - index, coarse corr output
    #        - input, full rx_code
    #        - template_real
    # output - fine corr index
    mask0 = torch.arange(-31, template_real.shape[2]+33, device=input.device).float().unsqueeze(0).repeat(index.shape[0], 1)
    index = index.unsqueeze(1).float()
    mask0 = torch.sigmoid(mask0 - (index - 16)) + torch.sigmoid(-mask0 + (index + 16)) - 1
    mask = mask0[:, 32:-32]
    mask[:, :32] = mask[:, :32] + mask0[:, -32:]
    mask[:, -32:] = mask[:, -32:] + mask0[:, :32]

    corr = F.conv1d(input, template_real).squeeze(1)
    corr = corr * mask
    corr = F.softmax(corr, dim=1)
    corr = corr * torch.arange(1, 1+template_real.shape[2], device=input.device).view(1, template_real.shape[2]).float()
    output = corr.sum(dim=1)
    return output

def addfigure(code,title,epoch,writer):
    fig = plt.figure(figsize=[9.6, 7.2])
    plt.plot(range(code.shape[0]), code.detach().cpu().numpy(), linestyle='-', marker='.')
    writer.add_figure(title, fig, epoch)
    plt.close('all')

class CodeDataset(data.Dataset):
    def __init__(self, data_path):
        super(CodeDataset, self).__init__()
        self.data_path = data_path
        self.file_list = os.listdir(data_path)

    def __getitem__(self, index):
        temp=sio.loadmat(self.data_path+self.file_list[index])
        fast=torch.tensor(temp['fast']).permute(1,0).unsqueeze(1).float()
        slow=torch.tensor(temp['slow'].astype(float)).permute(1,0).unsqueeze(1).float()
        target=torch.tensor(temp['dist'].astype(float)).float()
        return fast,slow,target

    def __len__(self):
        return len(self.file_list)

def losses(output,target):
    threshold=0.030 # m
    l1_loss=F.l1_loss(output,target)
    hinge_loss=F.threshold(torch.abs(output-target),threshold,threshold)-threshold
    hinge_loss=hinge_loss.mean()
    err=(output-target)
    slope=6
    sig = torch.sigmoid((err-threshold)/slope)-torch.sigmoid((err+threshold)/slope)+1
    sig_loss=torch.mean(sig)
    feasible = torch.abs(output-target)<=threshold
    l1_feasible = F.l1_loss(output[feasible],target[feasible])
    infeasible = torch.sum(torch.abs(output-target)>threshold).float()
    infeasible/=output.shape[0]
    return l1_loss,sig_loss, l1_feasible, infeasible

def losses_coarse(output,target):
    sample_dist = 0.0187314
    threshold=sample_dist * 15 # m
    l1_loss=F.l1_loss(output,target)
    hinge_loss=F.threshold(torch.abs(output-target),threshold,threshold)-threshold
    hinge_loss=hinge_loss.mean()
    feasible = torch.abs(output-target)<=threshold
    l1_feasible = F.l1_loss(output[feasible],target[feasible])
    infeasible = torch.sum(torch.abs(output-target)>threshold).float()
    infeasible/=output.shape[0]
    return l1_loss,hinge_loss, l1_feasible, infeasible

def real_to_3bit(x):
    return torch.round(x * 7) / 7