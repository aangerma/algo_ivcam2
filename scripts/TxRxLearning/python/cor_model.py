import torch
import torch.nn as nn

import torch.nn.functional as F
from torch.autograd import Variable

class cor_model2(nn.Module):
    def __init__(self,ch):
        super(cor_model2, self).__init__()
        self.conv = nn.Sequential(nn.Conv1d(2, ch, 5, stride=1, padding=0, dilation=1),
                                 nn.ReLU(),
                                 nn.Conv1d(ch, ch, 5, stride=1, padding=0, dilation=1),
                                 nn.ReLU(),
                                 nn.Conv1d(ch, 2*ch, 5, stride=1, padding=0, dilation=1),
                                 nn.ReLU(),
                                 nn.Conv1d(2*ch, 2*ch, 5, stride=1, padding=0, dilation=1),
                                 nn.ReLU(),
                                 nn.Conv1d(2*ch, 4 * ch, 5, stride=1, padding=0, dilation=1),
                                 nn.ReLU(),
                                 nn.Conv1d(4 * ch, 4 * ch, 5, stride=1, padding=0, dilation=1),
                                 nn.ReLU(),
                                 nn.Conv1d(4*ch, 6*ch, 5, stride=1, padding=0, dilation=1),
                                 nn.ReLU(),
                                 nn.Conv1d(6*ch, 6 * ch, 5, stride=1, padding=0, dilation=1),
                                 nn.ReLU(),
                                 nn.Conv1d(6 * ch, 8 * ch, 5, stride=1, padding=0, dilation=1),
                                 nn.ReLU())

        self.fc=nn.Sequential(nn.Linear(3808*ch, 1024*ch),
                         nn.ReLU(),
                         nn.Linear(1024*ch, 512*ch),
                         nn.ReLU(),
                         nn.Linear(512*ch, 128*ch),
                         nn.ReLU(),
                         nn.Linear(128*ch, 32*ch),
                         nn.ReLU(),
                         nn.Linear(32 * ch, 10),
                         nn.ReLU(),
                         nn.Linear(10, 1))

    def forward(self, inputs):
        output=self.conv(inputs)
        output=output.view(output.size(0), -1)
        output=self.fc(output)

        return output

class cor_model(nn.Module):
    def __init__(self,ch):
        super(cor_model, self).__init__()
        self.conv = nn.Sequential(nn.Conv1d(2, ch, 3, stride=1, padding=0, dilation=1),
                             nn.ReLU(),
                             nn.Conv1d(ch, 2*ch, 3, stride=1, padding=0, dilation=1),
                             nn.ReLU(),
                             nn.Conv1d(2*ch, 4*ch, 3, stride=1, padding=0, dilation=1),
                             nn.ReLU())
        self.fc=nn.Sequential(nn.Linear(2024*ch, 256*ch),
                         nn.ReLU(),
                         nn.Linear(256*ch, 64*ch),
                         nn.ReLU(),
                         nn.Linear(64 * ch, 10),
                         nn.ReLU(),
                         nn.Linear(10, 1))

    def forward(self, inputs):
        output=self.conv(inputs)
        output=output.view(output.size(0), -1)
        output=self.fc(output)

        return output