import tensorflow as tf
import numpy as np


def calibDFZ(rpts,regs):
  
  xyz = rpt2xyz(rpts,regs)
  errors = gid(xyz,params)
  loss = tf.reduce_mean(errors)
  return loss
def rpt2xyz(rpts,regs):
  rpts = applyPolyUndistAndPitchFix(rtps,regs)
  xyz = ang2vec(rpts,regs)
def applyPolyUndistAndPitchFix(rpts,regs):
  return rpts
def ang2vec(rpts,regs):
	xfov=regs['xfov']
	yfov=regs['yfov']
	angXfactor = xfov*0.25/(2^11-1)
	angYfactor = yfov*0.25/(2^11-1)
    
	angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx)             sind(angy) cosd(angy).*cosd(angx)]';

	laserIncidentDirection = [0,0,-1]
	oXYZfunc = @(mirNormalXYZ_)  bsxfun(@plus,laserIncidentDirection,-bsxfun(@times,2*laserIncidentDirection'*mirNormalXYZ_,mirNormalXYZ_));
	applyFOVex = @(v) Calibration.aux.applyFOVex(v, regs); % Model-based implementation (nominal FOVex + lens distortion)

	angyQ=angyQin(:);angxQ =angxQin(:); % [DSM units]
	angx = single(angxQ)*angXfactor; % [deg]
	angy = single(angyQ)*angYfactor; % [deg]
	
	xyzMirrorNormal = []
	oXYZ = applyFOVex(oXYZfunc(angles2xyz(angx,angy)));
	oXYZ(1:2,:) = rotmat*oXYZ(1:2,:);   
	  
  
  
def gid(xyz,params):
  