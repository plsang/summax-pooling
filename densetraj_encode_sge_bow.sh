# Written by Duy Le - ledduy@ieee.org
# Last update Jun 26, 2012
#!/bin/sh
# Force to use shell sh. Note that #$ is SGE command
#$ -S /bin/sh
# Force to limit hosts running jobs
#$ -q all.q@@bc3hosts,all.q@@bc4hosts,all.q@bc211.hpc.vpl.nii.ac.jp,all.q@bc212.hpc.vpl.nii.ac.jp,all.q@bc213.hpc.vpl.nii.ac.jp,all.q@bc214.hpc.vpl.nii.ac.jp
# Log starting time
date 
# for opencv shared lib
export LD_LIBRARY_PATH=/net/per610a/export/das11f/plsang/usr/lib:/net/per900a/raid0/plsang/usr.local/lib64:/net/per900a/raid0/plsang/software/ffmpeg-2.0/release-shared/lib:/net/per900a/raid0/plsang/software/gcc-4.8.1/release/lib:/net/per900a/raid0/plsang/software/opencv-2.4.6.1/release/lib:/net/per900a/raid0/plsang/usr.local/lib:/net/per900a/raid0/plsang/software/openmpi-1.6.5/release-shared/lib:/usr/local/lib:$LD_LIBRARY_PATH
# Log info of the job to output file  *** CHANGED ***
echo [$HOSTNAME] [$JOB_ID] [matlab -nodisplay -r "densetraj_encode_sge_bow( '$1', '$2', '$3', $4, $5)"]
# change to the code dir  --> NEW!!! *** CHANGED ***
cd /net/per610a/export/das11f/plsang/codes/summax-pooling-journal
# Log info of current dir
pwd
# Command - -->  must use " (double quote) for $2 because it contains a string  --- *** CHANGED ***
# LD_PRELOAD="/net/per900a/raid0/plsang/usr.local/lib/libstdc++.so.6" matlab -nodisplay -r "densetraj_encode_sge( '$1', '$2', '$3', $4, $5 )"
matlab -nodisplay -r "densetraj_encode_sge_bow( '$1', '$2', '$3', $4, $5)"
# Log ending time
date

