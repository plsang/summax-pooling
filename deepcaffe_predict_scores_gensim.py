### almost same with deepcaffe_predict.py
### difference: output scores without sorted scores

import os
import numpy as np
import matplotlib.pyplot as plt
import time
import logging
import pandas as pd
import re
import glob
from os.path import basename
import time
import subprocess

caffe_root = '/net/per610a/export/das11f/plsang/deepcaffe/caffe-rc' 
nc = 1000

import sys
sys.path.insert(0, caffe_root + '/python')

import caffe

if (len(sys.argv) < 5):
	print sys.argv[0] + " <dataset> <partition> <start video> <end video> ";
	exit();

dataset = sys.argv[1]
partition = sys.argv[2]
start_video = int(sys.argv[3])
end_video = int(sys.argv[4])


REPO_DIRNAME = caffe_root
						   
# Set the right path to your model definition file, pretrained model weights,
# and the image you would like to classify.
MODEL_FILE = '{}/models/bvlc_reference_caffenet/deploy.prototxt'.format(REPO_DIRNAME)
PRETRAINED = '{}/models/bvlc_reference_caffenet/bvlc_reference_caffenet.caffemodel'.format(REPO_DIRNAME)

net = caffe.Classifier(MODEL_FILE, PRETRAINED,
                       mean=np.load(caffe_root + '/python/caffe/imagenet/ilsvrc_2012_mean.npy'),
                       channel_swap=(2,1,0),
                       raw_scale=255,
                       image_dims=(256, 256))

net.set_phase_test()
net.set_mode_cpu()

default_args = {
	'model_def_file': (
		'{}/models/bvlc_reference_caffenet/deploy.prototxt'.format(REPO_DIRNAME)),
	'pretrained_model_file': (
		'{}/models/bvlc_reference_caffenet/bvlc_reference_caffenet.caffemodel'.format(REPO_DIRNAME)),
	'mean_file': (
		'{}/python/caffe/imagenet/ilsvrc_2012_mean.npy'.format(REPO_DIRNAME)),
	'class_labels_file': (
		'{}/data/ilsvrc12/synset_words.txt'.format(REPO_DIRNAME)),
}
for key, val in default_args.iteritems():
	if not os.path.exists(val):
		raise Exception(
			"File for {} is missing. Should be at: {}".format(key, val))
			
default_args['image_dim'] = 227
default_args['raw_scale'] = 255.
default_args['gpu_mode'] = False

with open(default_args['class_labels_file']) as f:
	labels_df = pd.DataFrame([
		{
			'synset_id': l.strip().split(' ')[0],
			#'name': ' '.join(l.strip().split(' ')[1:]).split(',')[0]
			'name': ' '.join(l.strip().split(' ')[1:])
		}
		for l in f.readlines()
	])
labels = labels_df.sort('synset_id')['name'].values

root_dir = '/net/per610a/export/das11f/plsang';
root_dir = '/net/per900a/raid0/plsang';

# dataset = 'youcook'
keyframe_dir = '{}/{}/keyframes/{}'.format(root_dir, dataset, partition);	
output_dir = '{}/{}/feature/deepcaffe/{}'.format(root_dir, dataset, partition);
	
def classify_image(image_file):
	try:
		input_image = caffe.io.load_image(image_file)
		scores = net.predict([input_image], oversample=True).flatten()
		
		#indices = (-scores).argsort()[:nc]
		#indices = range(0, len(scores))[:nc]
		
		#predictions = labels[indices]

		
		# meta = [
			# (p, '%.6f' % scores[i])
			# for i, p in zip(indices, predictions)
		# ]
		#logging.info('result: %s', str(meta))
				
		return scores;

	except Exception as err:
		#logging.info('Classification error: %s', err)
		return (False, 'Something went wrong when classifying the '
					   'image. Maybe try another one?')

def get_video_list(dataset):
    return {
		'trecvidmed10': [vid for vid in os.listdir(keyframe_dir) if re.search('HVC\d+', vid)],
		'trecvidmed11': [vid for vid in os.listdir(keyframe_dir) if re.search('HVC\d+', vid)],
        }[dataset]
		
if __name__=="__main__":
	

	videos = get_video_list(dataset)
	
	#print ', '.join(videos)
	
	for ii in range(start_video, end_video):
		vid = videos[ii]
		
		#if vid != 'HVC128378':
		#	continue
			
		print ' {}/{} Extracting deep caffe feature for video [{}]...'.format(ii, end_video - start_video, vid)
		
		kfs = glob.glob("{}/{}/*.jpg".format(keyframe_dir, vid))
		output_vdir = '{}/{}'.format(output_dir, vid)
		
		if not os.path.exists(output_vdir):
			os.makedirs(output_vdir)
		
		scores = np.zeros((len(kfs), nc))
		sims = np.zeros((len(kfs)-1))
		
		output_scores_file = '{}/{}.{}deepcaffe.scores.npy'.format(output_vdir, vid, nc)
		output_sim_file = '{}/{}.{}deepcaffe.sims.npy'.format(output_vdir, vid, nc)
		if not os.path.exists(output_scores_file) or not os.path.exists(output_sim_file):
			raise Exception( 'File [{},{}] already exists'.format(output_sim_file, output_sim_file) );
		
		sims = np.load(output_sim_file)
		output_sim_txtfile = '{}/{}.{}deepcaffe.sims.txt'.format(output_vdir, vid, nc)
		if os.path.exists(output_sim_txtfile):
			continue
			
		with open(output_sim_txtfile, 'w') as fh:
			for sim in sims:
				fh.write('{} '.format(sim))	
			fh.write('\n')
		
			