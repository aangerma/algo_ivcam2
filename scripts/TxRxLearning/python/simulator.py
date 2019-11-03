import torch
import torch.nn.functional as F
import math
import matplotlib.pyplot as plt
import scipy.io as sio

def plot(y):
    plt.plot(y.detach().cpu().numpy())
    plt.show()

def Simulator(txcode,dist,albedo_min, albedo_max):   # build from the matlab simulator "algo_ivcam2/+Simulator/runSim.m"
    albedo=torch.rand(dist.shape,device=txcode.device)*(albedo_max-albedo_min)+albedo_min
    dist = dist * 1000
    albedo = albedo.unsqueeze(1)
    dist = dist.unsqueeze(1)

    prms = load_prms()
    repeat = 2
    prms['runTime'] = txcode.shape[0] / prms['laser']['frequency'] * repeat
    # UNITS: freq: Ghz, time: nSec, distance: mm
    txQuietHeadTime = 0
    Tx = 1 / prms['laser']['frequency']
    Tc = Tx / prms['overSamplingRate']  # over sample time
    Ts = 1 / prms['Comparator']['frequency']

    laserPeakcurrent = prms['laser']['peakCurrent']
    laserHi = (laserPeakcurrent - prms['laser']['thresholdCurrent']) * prms['laser']['slopeEfficiency']
    laserLo = (prms['laser']['biasCurrent'] - prms['laser']['thresholdCurrent']) * prms['laser']['slopeEfficiency']

    y_c = txcode.repeat_interleave(prms['overSamplingRate'])*laserHi+laserLo  # without time jitter
    y_c = y_c.repeat(repeat)  # without time jitter
    y_c = y_c.repeat(dist.shape[0],1)

    y_c = applyNoisyLPF(Tc, y_c, 0.35 / prms['laserDriver']['riseTim'], 1, 0, 1)
    fParasitic = 1 / (2 * math.pi * prms['laserDriver']['parasiticResistance'] * prms['laserDriver'][
        'parasiticCapacitance'] * 1e-12) * 1e-9
    y_c = applyNoisyLPF(Tc, y_c, fParasitic, 1, 0, 2)
    y_c = applyNoisyLPF(Tc, y_c, 0.35 / prms['laser']['riseTime'], 1, 0, 3)

    # TX-> Env
    specularityFactor = 1
    # # dist[0]=torch.tensor([2000],device=dist.device)
    tau_delay = rmm2dtnsec(dist)
    # dist = torch.ones_like(t_c, device=txcode.device) * dist
    # tau_delay = torch.ones_like(t_c,device=txcode.device) * tau_delay
    albedoEff = albedo * prms['environment']['wavelengthReflectivityFactor']
    # #     albedoEff[0] = torch.tensor([0.8], device=dist.device)
    y_c = y_c * prms['optics']['lensArea'] / ((1 + dist) ** 2 * specularityFactor * math.pi) * albedoEff * \
          prms['optics']['TXopticsGain']
    tau_delay_c = (tau_delay / Tc).long()
    for i in range(tau_delay_c.shape[0]):
        y_c[i,tau_delay_c[i]:] = y_c[i,:-tau_delay_c[i]].clone()
        y_c[i,:tau_delay_c[i]] = 0
    y_c = y_c * prms['optics']['RXopticsGain']

    # ENV --> APD
    apdResponsivity = prms['APD']['responsivity'] * prms['APD']['mFactor']
    y_c = torch.min(y_c, torch.tensor(prms['APD']['overloadPower'], device=y_c.device)) * apdResponsivity
    y_c = y_c + prms['APD']['darkCurrentDC'] * 1e-9 * 1e3
    ambientMS = prms['environment']['ambientNoiseFactor'] * 1e-6 * math.sqrt(
        prms['optics']['RXopticsGain']) / math.sqrt(1e9)
    apdCutoffFreq = 0.35 / prms['APD']['riseTime']
    apdNEP = math.sqrt(
        2 * 1.6e-19 * prms['APD']['excessNoiseFactor'] * prms['APD']['darkCurrentAC'] * 1e-9) / apdResponsivity * 1e3
    apdSHOT = torch.sqrt(2 * 1.6e-19 * prms['APD']['excessNoiseFactor'] * y_c * 1e-3) / apdResponsivity * 1e3
    aptNEPtot = torch.sqrt(apdNEP ** 2 + apdSHOT ** 2 + ambientMS ** 2) * apdResponsivity
    y_c = applyNoisyLPF(Tc, y_c, apdCutoffFreq, 1, aptNEPtot, 4)

    # APD --> TIA
    tiaPreAmpIRN = prms['TIA']['preAmpIRN']
    tiaPreAmpCutoffFreq = 0.35 / prms['TIA']['preAmpRiseTime']
    preAmpGain = prms['TIA']['preAmpGain']
    y_c = applyNoisyLPF(Tc, y_c, tiaPreAmpCutoffFreq, 4, tiaPreAmpIRN, 5) * preAmpGain
    offsetVoltage = prms['TIA']['inputBiasCurrent'] * prms['TIA']['preAmpGain']
    y_c = (y_c + offsetVoltage) * prms['TIA']['postAmpGain']
    y_c = torch.min(y_c, torch.tensor(prms['TIA']['overloadVoltage'], device=y_c.device))

    # TIA --> HPF
    # hpfCuroff = 0.35 / prms['HPF']['riseTime']
    # # [b, a] = butter_(1, hpfCuroff * Tc * 2, 'high');
    # # y_c = filter(b, a, y_c)
    # # y_c = y_c.unsqueeze(1)
    # # temp = sio.loadmat('ker/6.mat')
    # # ker = torch.tensor(temp['ker'], device=txcode.device).unsqueeze(0).float()
    # # ker = ker.flip(2)
    # # y_c1 = F.conv1d(y_c, ker, padding=ker.shape[2] - 1).squeeze()
    # # y_c = y_c1[:, :y_c.shape[2]]
    # y_c=high_pass(y_c,0.9999,1,-1)
    y_c=y_c-y_c.mean(dim=1,keepdim=True)  # very bad highpass approximation

    # HPF --> SAMPLER
    # delta sempler
    # nSamples = txcode.shape[0] / prms['laser']['frequency'] / Ts /2
    # sampleTimes = torch.arange(nSamples,2*nSamples,device=y_c.device)*Ts
    # sampleNoise = randnWithS2Sbound(sampleTimes.shape[0], prms['Comparator']['jitterRMS'], prms['Comparator']['jitterMaxC2C'])
    # sampleTimes = sampleTimes + sampleNoise

    y_c = applyNoisyLPF(Tc, y_c, 0.35 / prms['Comparator']['riseTime'], prms['Comparator']['filterOrder'],
                        prms['Comparator']['irn'], 7)

    rxcode = y_c[:,txcode.shape[0] * prms['overSamplingRate']::int(prms['overSamplingRate'] * Ts)]
    rxcode = torch.sigmoid(rxcode)


    # rxcode=torch.zeros(dist.shape[0],8*txcode.shape[0],device=txcode.device)
    # for i in range(dist.shape[0]):
    #     albedo = torch.rand(1,device=txcode.device)*10
    #     albedo=10
    #     rxcode[i,:]=Simulator_onedist(txcode,dist[i],albedo)
    return rxcode


def Simulator_onedist(txcode,dist,albedo):
    dist=dist*1000

    prms=load_prms()
    repeat=2
    prms['runTime'] = txcode.shape[0]/prms['laser']['frequency']*repeat
    # UNITS: freq: Ghz, time: nSec, distance: mm
    txQuietHeadTime = 0
    Tx = 1 / prms['laser']['frequency']
    Tc = Tx / prms['overSamplingRate'] # over sample time
    Ts = 1 / prms['Comparator']['frequency']



    laserPeakcurrent = prms['laser']['peakCurrent']
    laserHi = (laserPeakcurrent - prms['laser']['thresholdCurrent']) * prms['laser']['slopeEfficiency']
    laserLo = (prms['laser']['biasCurrent'] - prms['laser']['thresholdCurrent']) * prms['laser']['slopeEfficiency']

    # create oversample time domain
    # t_c = torch.arange(0, prms['runTime'], Tc)
    # transmitedSignalJitter = randnWithS2Sbound(round(prms['runTime']/Tx), prms['laser']['jitterRMS'], prms['laser']['jitterMaxC2C'],txcode.device)
    # transmitedSignalJitter = interp1(transmitedSignalJitter, t_c.shape[0]) #### to fix

    # y_c = cyclicBinarySeq(t_c + transmitedSignalJitter - txQuietHeadTime, prms.laser.txSequence, Tx) * laserHi + laserLo

    y_c = txcode.repeat_interleave(prms['overSamplingRate']) # without time jitter
    y_c = y_c.repeat(repeat)                                 # without time jitter

    y_c = applyNoisyLPF(Tc, y_c, 0.35 / prms['laserDriver']['riseTim'], 1, 0,1)
    fParasitic = 1 / (2 * math.pi * prms['laserDriver']['parasiticResistance'] * prms['laserDriver']['parasiticCapacitance'] * 1e-12) * 1e-9
    y_c = applyNoisyLPF(Tc, y_c, fParasitic, 1, 0,2)
    y_c = applyNoisyLPF(Tc, y_c, 0.35 / prms['laser']['riseTime'], 1, 0,3)

    # TX-> Env
    specularityFactor = 1
    tau_delay = rmm2dtnsec(dist)
    # dist = torch.ones_like(t_c, device=txcode.device) * dist
    # tau_delay = torch.ones_like(t_c,device=txcode.device) * tau_delay
    albedoEff = albedo * prms['environment']['wavelengthReflectivityFactor']
    y_c = y_c * prms['optics']['lensArea'] / ((1 + dist) ** 2 * specularityFactor * math.pi) * albedoEff * prms['optics']['TXopticsGain']
    tau_delay_c=(tau_delay/Tc).long()
    y_c[tau_delay_c:] = y_c[:-tau_delay_c]
    y_c[:tau_delay_c] = 0
    y_c = y_c * prms['optics']['RXopticsGain']

    # ENV --> APD
    apdResponsivity = prms['APD']['responsivity'] * prms['APD']['mFactor']
    y_c = torch.min(y_c, torch.tensor(prms['APD']['overloadPower'],device=y_c.device)) * apdResponsivity
    y_c = y_c + prms['APD']['darkCurrentDC'] * 1e-9 * 1e3
    ambientMS = prms['environment']['ambientNoiseFactor'] * 1e-6 * math.sqrt(prms['optics']['RXopticsGain']) / math.sqrt(1e9)
    apdCutoffFreq = 0.35 / prms['APD']['riseTime']
    apdNEP = math.sqrt(2 * 1.6e-19 * prms['APD']['excessNoiseFactor'] * prms['APD']['darkCurrentAC'] * 1e-9) / apdResponsivity * 1e3
    apdSHOT = torch.sqrt(2 * 1.6e-19 * prms['APD']['excessNoiseFactor'] * y_c * 1e-3) / apdResponsivity * 1e3
    aptNEPtot = torch.sqrt(apdNEP ** 2 + apdSHOT ** 2 + ambientMS ** 2) * apdResponsivity
    y_c = applyNoisyLPF(Tc, y_c, apdCutoffFreq, 1, aptNEPtot,4)

    # APD --> TIA
    tiaPreAmpIRN = prms['TIA']['preAmpIRN']
    tiaPreAmpCutoffFreq = 0.35 / prms['TIA']['preAmpRiseTime']
    preAmpGain = prms['TIA']['preAmpGain']
    y_c = applyNoisyLPF(Tc, y_c, tiaPreAmpCutoffFreq, 4, tiaPreAmpIRN,5) * preAmpGain
    offsetVoltage = prms['TIA']['inputBiasCurrent'] * prms['TIA']['preAmpGain']
    y_c = (y_c + offsetVoltage) * prms['TIA']['postAmpGain']
    y_c = torch.min(y_c, torch.tensor(prms['TIA']['overloadVoltage'],device=y_c.device))

    # TIA --> HPF
    hpfCuroff = 0.35 / prms['HPF']['riseTime']
    # [b, a] = butter_(1, hpfCuroff * Tc * 2, 'high');
    # y_c = filter(b, a, y_c)
    y_c = y_c.unsqueeze(0).unsqueeze(0)
    y_c = F.conv1d(y_c, torch.ones(1, 1, 3, device=y_c.device) / 3, padding=1).squeeze()


    # HPF --> SAMPLER
    # delta sempler
    # nSamples = txcode.shape[0] / prms['laser']['frequency'] / Ts /2
    # sampleTimes = torch.arange(nSamples,2*nSamples,device=y_c.device)*Ts
    # sampleNoise = randnWithS2Sbound(sampleTimes.shape[0], prms['Comparator']['jitterRMS'], prms['Comparator']['jitterMaxC2C'])
    # sampleTimes = sampleTimes + sampleNoise

    y_c = applyNoisyLPF(Tc, y_c, 0.35 / prms['Comparator']['riseTime'], prms['Comparator']['filterOrder'], prms['Comparator']['irn'],7)

    rx=y_c[txcode.shape[0]*prms['overSamplingRate']::int(prms['overSamplingRate']*Ts)]
    rx = torch.sigmoid(rx)
    # a = y_c.reshape(128, 1000)
    # b = a.mean(dim=1)
    # b = b[64:]
    return rx

def Simulator0(txcode, dist,albedo_min, albedo_max): # simple version, just add noise
    sample_dist = 0.0187314
    rxcode=txcode.repeat_interleave(8).unsqueeze(0)
    rxcode=rxcode.repeat(dist.shape[0],1)

    # noise=torch.randn(rxcode.shape,device=rxcode.device)*1.5 # addtive noise
    # rxcode=rxcode+noise
    # rxcode = 1 / (1 + torch.exp(-rxcode))

    noise = torch.rand_like(rxcode, device=rxcode.device) > 0.65 # flip noise
    noise  = noise.float()
    rxcode = (1-rxcode)*noise + rxcode*(1-noise)

    for i in range(dist.shape[0]):
        n=int(dist[i]/sample_dist)
        rxcode[i,:]=torch.cat((rxcode[i,-n:], rxcode[i,:-n]),dim=0)
    return rxcode

def high_pass(yin,a,b1,b2):
    out=yin.clone()
    for i in range(1,yin.shape[1]):
        out[:,i] = a*out[:,i-1] + b1*yin[:,i] + b2*yin[:,i-1]
    return out

def interp1(image, sample_amount):
    # input image is: W
    image = image.unsqueeze(0).unsqueeze(0).unsqueeze(3) # change to:  1 x C x W x H
    samples_x=torch.arange(0,sample_amount,device=image.device).float().unsqueeze(0)
    samples_x = samples_x.unsqueeze(2)
    samples_x = samples_x.unsqueeze(3)
    samples = torch.cat([samples_x, torch.zeros(samples_x.shape,device=image.device)], 3)
    samples[:, :, :, 0] = (samples[:, :, :, 0] / (image.shape[2] - 1))  # normalize to between  0 and 1
    samples = samples * 2 - 1  # normalize to between -1 and 1
    return torch.nn.functional.grid_sample(image, samples).squeeze()

def bilinear_interpolate_torch_gridsample(image, samples_x, samples_y):
    # input image is: W x H x C
    image = image.permute(2, 0, 1)  # change to:      C x W x H
    image = image.unsqueeze(0)  # change to:  1 x C x W x H
    samples_x = samples_x.unsqueeze(2)
    samples_x = samples_x.unsqueeze(3)
    samples_y = samples_y.unsqueeze(2)
    samples_y = samples_y.unsqueeze(3)
    samples = torch.cat([samples_x, samples_y], 3)
    samples[:, :, :, 0] = (samples[:, :, :, 0] / (W - 1))  # normalize to between  0 and 1
    samples[:, :, :, 1] = (samples[:, :, :, 1] / (H - 1))  # normalize to between  0 and 1
    samples = samples * 2 - 1  # normalize to between -1 and 1
    return torch.nn.functional.grid_sample(image, samples)

def randnWithS2Sbound(n,s,bound,device):
    v = torch.randn(n,device=device)*s
    if (s>0 and bound>0):
        print('need to implement randnWithS2Sbound')
    return v

def applyNoisyLPF(Tc,yin,cutOffFreq,filterOrder,stdNoiseHz,ker_index):
    noiseStd = stdNoiseHz * math.sqrt(cutOffFreq*1e9)

    rrr = torch.randn(yin.shape,device=yin.device)
    n = applyLPF(Tc,rrr,cutOffFreq,filterOrder,ker_index)
    n = n/torch.std(n)*noiseStd
    yout = applyLPF(Tc,yin,cutOffFreq,filterOrder,ker_index)
    yout = yout + n;
    return yout

def applyLPF(Tc,yin,cutOffFreq,N,ker_index):
    # if(isempty(cutOffFreq))
    #     yout = yin;
    #     return;
    # end
    # cutOffFreqN=cutOffFreq*Tc*2
    # [b,a]=butter_(N,cutOffFreqN,'low')
    # yout = filter(b,a,yin);
    yin=yin.unsqueeze(1)
    # ker=torch.ones(1,1,3,device=yin.device)/3
    temp=sio.loadmat('ker/'+str(ker_index)+'.mat')
    ker=torch.tensor(temp['ker'],device=yin.device).unsqueeze(0).float()
    ker=ker.flip(2)
    yout=F.conv1d(yin,ker,padding=ker.shape[2]-1).squeeze()
    return yout[:,:yin.shape[2]]


def load_prms():
    prms={}
    prms['overSamplingRate'] = 1000


    prms['laser']={}
    prms['laser']['frequency'] = 1.
    prms['laser']['peakCurrent'] = 250.
    prms['laser']['slopeEfficiency'] = 1.
    prms['laser']['thresholdCurrent'] = 50.
    prms['laser']['biasCurrent'] = 60.
    prms['laser']['jitterMaxC2C'] = 0
    prms['laser']['jitterRMS'] = 0
    prms['laser']['riseTime'] = 0.3

    prms['Comparator'] = {}
    prms['Comparator']['jitterRMS'] = 0
    prms['Comparator']['jitterMaxC2C'] = 0
    prms['Comparator']['riseTime'] = 0.35
    prms['Comparator']['filterOrder'] = 1
    prms['Comparator']['irn'] = 2.45e-6
    prms['Comparator']['sensitivity'] = 0.5
    prms['Comparator']['frequency'] = 8.

    prms['laserDriver']={}
    prms['laserDriver']['riseTim'] = 0.3
    prms['laserDriver']['parasiticResistance'] = 95.
    prms['laserDriver']['parasiticCapacitance'] = 1.5

    prms['environment']={}
    prms['environment']['wavelengthReflectivityFactor'] = 0.8
    prms['environment']['ambientNoiseFactor'] = 0.4e-6

    prms['optics']={}
    prms['optics']['lensArea'] = 0.196
    prms['optics']['TXopticsGain'] = 1.0
    prms['optics']['RXopticsGain'] = 4.7

    prms['APD']={}
    prms['APD']['responsivity'] = 0.5
    prms['APD']['mFactor'] = 100.
    prms['APD']['overloadPower'] = 0.1
    prms['APD']['darkCurrentDC'] = 50.
    prms['APD']['riseTime'] = 0.4
    prms['APD']['excessNoiseFactor'] = 11.79
    prms['APD']['darkCurrentAC'] = 0.14

    prms['TIA'] = {}
    prms['TIA']['preAmpIRN'] = 3.5e-9
    prms['TIA']['preAmpRiseTime'] = 0.4118
    prms['TIA']['preAmpGain'] = 5.0e3
    prms['TIA']['inputBiasCurrent'] = 0
    prms['TIA']['postAmpGain'] = 10.0
    prms['TIA']['overloadVoltage'] = 600.0

    prms['HPF'] = {}
    prms['HPF']['riseTime'] = 35.

    # p.HDRsampler.frequency = 1;
    # p.HDRsampler.riseTime = 0.35;
    # p.HDRsampler.filterOrder = 1;
    # p.HDRsampler.maxVal = 255;
    # p.HDRsampler.minVal = 10;
    # p.HDRsampler.nBits = 8;


    return prms

def rmm2dtnsec(rmm):
    # C = 299792458 # vacum
    C = 299702547 # air
    return rmm*1e-3*2/C *1e9 # nsec