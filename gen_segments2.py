####
## gen matlab struct containing two fields: keyframes, scores and frames
import sys
import os
import commands
import string
import random
import os.path
import re
import math

import numpy as np
from scipy.signal import argrelextrema
from datetime import datetime
import scipy.io as sio

import subprocess
 
def get_video_length(path):
	cmd = 'ffmpeg -i {} 2>&1 | sed -n "s/.*Duration: \\([^,]*\\), .*/\\1/p"'.format(path);
	
	duration = subprocess.check_output(cmd, shell=True)
	
	p = re.compile(r"(?P<hh>\d\d)\:(?P<mm>\d\d)\:(?P<ss>\d\d.\d+)")
	m = p.search(duration)
	
	hours = float(m.group('hh'))
	minutes = float(m.group('mm'))
	seconds = float(m.group('ss'))
 
	total = 0
	total += 60 * 60 * hours
	total += 60 * minutes
	total += seconds
	return total

	
def get_video_fps(video_file):
	command = 'ffmpeg -i ' + video_file
	line = commands.getoutput(command)
	tokens = line.split(',')
	found_fps = 0;
	for token in tokens:
		if 'fps' in token and 'Header' not in token:
			#print 'Found token: ' + token
			tks = token.strip().split(' ') # bugs: must strip ',' before spliting	
			if tks[0].replace('.', '').isdigit():
				fps = eval(tks[0])
				#print 'Found fps: ' + str(fps)
				found_fps = 1;
				break
				
	if not found_fps:
		#print "FPS not found for video " + video_file
		#print line
		fps = 25
	
	return fps

if (len(sys.argv) < 3):
	print sys.argv[0] + " <dataset> <partition>";
	exit();

	
dataset = sys.argv[1]
partition = sys.argv[2]
#threshold = float(sys.argv[3])

#threshold to filter out similarity which considered as scene cut
#threshold = 0.05

#partition = 'devel'

if dataset == 'trecvidmed10':
	video_dir = '/net/per900a/raid0/plsang/dataset/MED10_Resized'
elif dataset == 'trecvidmed11':
	if partition == 'devel':	
		video_dir = '/net/per900a/raid0/plsang/dataset/MED11_Resized/MED11DEV';
	elif partition == 'test':
		video_dir = '/net/per900a/raid0/plsang/dataset/MED11_Resized/MED11TEST';
	else:
		raise Exception('Unknown partition')
else:
	raise Exception('Unknown dataset')

feat_dir = '/net/per900a/raid0/plsang/' + dataset + '/feature/deepcaffe' + '/' + partition

out_dir = '/net/per900a/raid0/plsang/' + dataset + '/metadata/common'

out_file = '{}/{}_{}_shotinfo.mat'.format(out_dir, dataset, partition)

if os.path.exists(out_file):
	print 'File [{}] already exists'.format(out_file);
	exit()

if not os.path.exists(out_dir):
	os.makedirs(out_dir)
			
videos = [vid for vid in os.listdir(feat_dir) if re.search('HVC\d+', vid)]


#print len(videos)
total_segment = 0
total_duration = 0

log_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), os.path.basename(__file__) + '.log')

shot_infos = {}

for vid in videos:
	#if vid != 'HVC128378':
	#	continue
		
	index = videos.index(vid);
	if not index % 10:
		print index, ' '
	video_file = video_dir + '/' + vid + '.mp4'
			
	fps = get_video_fps(video_file)
	duration = get_video_length(video_file)
	
	
	if not duration:
		raise Exception(
			"Could not get video length for video {}.".format(vid))
	
	#print fps, vid, math.floor(duration * fps)
	
	deepcaffe_file = feat_dir + '/' + vid + '/' + '{}.1000deepcaffe.sims.npy'.format(vid);
	if not os.path.exists(deepcaffe_file):
		#raise Exception(
		#	"File {} is missing.".format(deepcaffe_file))
		with open(log_file, 'w') as fh:
			fh.write("[{}] File {} is missing!\n".format(datetime.now().strftime('%Y-%m-%d %H:%M:%S'), deepcaffe_file))	
		continue	
	
	sim_ar = np.load(deepcaffe_file)
	
	local_minima = argrelextrema(sim_ar, np.less)
	#print local_minima[0]
	#print sim_ar[local_minima[0]]
	
	#print (local_minima[0] - [3]) * [2] * fps 
	#frames = np.round(((local_minima[0] - [3]) * [2] * [fps] + [fps]) * (sim_ar[local_minima[0]] < threshold))
	frames = np.round(((local_minima[0] - [3]) * [2] * [fps] + [fps]))
	
	#adding the first and the final keyframes
	#frames = frames[frames>0]
	#frames = np.insert(frames, 0, 1)	# append first frame
	#frames = np.append(frames, math.floor(duration * fps))	# append last frame
	#frames = frames.astype(int)	# cast to type int
	
	infos_ = {}
	infos_['keyframes'] = local_minima[0]
	infos_['scores'] = sim_ar[local_minima[0]]
	infos_['frames'] = frames
	
	#append the first and final element
	infos_['keyframes'] = np.insert(infos_['keyframes'], 0, 1)
	infos_['keyframes'] = np.append(infos_['keyframes'], len(sim_ar))
	infos_['scores'] = np.insert(infos_['scores'], 0, 0)
	infos_['scores'] = np.append(infos_['scores'], 0)
	infos_['frames'] = np.insert(infos_['frames'], 0, 1)
	infos_['frames'] = np.append(infos_['frames'], math.floor(duration * fps))
	
	shot_infos[vid] = infos_
	
print 'saving output file...'	
sio.savemat(out_file, {'shot_infos': shot_infos})	
print 'done!'	
