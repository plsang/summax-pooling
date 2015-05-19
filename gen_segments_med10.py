
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

partition = 'test'
	
video_dir = '/net/per900a/raid0/plsang/dataset/MED10_Resized';

feat_dir = '/net/per900a/raid0/plsang/trecvidmed10/feature/deepcaffe' + '/' + partition

out_dir = '/net/per900a/raid0/plsang/trecvidmed10/metadata/deepcaffe' + '/' + partition

if not os.path.exists(out_dir):
	os.makedirs(out_dir)
			
videos = [vid for vid in os.listdir(feat_dir) if re.search('HVC\d+', vid)]

#threshold to filter out similarity which considered as scene cut
threshold = 0.05

#print len(videos)
total_segment = 0

for vid in videos:
	#if vid != 'HVC1099':
	#	continue
		
	index = videos.index(vid);
	if not index % 10:
		print index, ' '
	video_file = video_dir + '/' + vid + '.mp4'
	
	output_file = out_dir + '/' + vid + '.txt'
	
	if os.path.exists(output_file):
		print 'File [{}] already exists'.format(output_file);
		continue
			
	fps = get_video_fps(video_file)
	duration = get_video_length(video_file)
	
	
	if not duration:
		raise Exception(
			"Could not get video length for video {}.".format(vid))
	
	#print fps, vid, math.floor(duration * fps)
	
	deepcaffe_file = feat_dir + '/' + vid + '/' + '{}.1000deepcaffe.sims.npy'.format(vid);
	if not os.path.exists(deepcaffe_file):
		raise Exception(
			"File {} is missing.".format(deepcaffe_file))
	
	sim_ar = np.load(deepcaffe_file)
	
	local_minima = argrelextrema(sim_ar, np.less)
	#print local_minima[0]
	#print sim_ar[local_minima[0]]
	
	#print (local_minima[0] - [3]) * [2] * fps 
	frames = np.round(((local_minima[0] - [3]) * [2] * [fps] + [fps]) * (sim_ar[local_minima[0]] < threshold))
	frames = frames[frames>0]
	frames = np.insert(frames, 0, 1)	# append first frame
	frames = np.append(frames, math.floor(duration * fps))	# append last frame
	frames = frames.astype(int)	# cast to type int
	
	#print frames
	with open(output_file, 'w') as fh:
		for frame in frames:
			fh.write('{} '.format(frame))	
		fh.write('\n')		
	
	total_segment += len(frames) - 1
	#break

print 'total segment: ', total_segment	


