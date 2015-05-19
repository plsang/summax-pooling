
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
 
def get_video_length(video_file):
	cmd = 'ffmpeg -i {} 2>&1 | sed -n "s/.*Duration: \\([^,]*\\), .*/\\1/p"'.format(video_file);
	
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

out_dir = '/net/per900a/raid0/plsang/' + dataset + '/metadata/common'

out_file = '{}/{}_{}.mat'.format(out_dir, dataset, partition);

if not os.path.exists(out_dir):
	os.makedirs(out_dir)
			
videos = [vid for vid in os.listdir(video_dir) if re.search('HVC\d+', vid)]

log_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), os.path.basename(__file__) + '.log')

infos = {}
for vid in videos:
	
	index = videos.index(vid);
	if not index % 10:
		print index, ' '
	video_file = video_dir + '/' + vid

	fps = get_video_fps(video_file)
	duration = get_video_length(video_file)
	#if not duration:
	#	raise Exception(
	#		"Could not get video length for video {}.".format(vid))
			
	frame_num = math.floor(fps * duration);
	
	vidkey = vid[:-4] # REMOVE EXTENSION
	infos[vidkey] = frame_num
	
print 'saving output file...'	
sio.savemat(out_file, {'infos': infos})	
print 'done!'	
	
	