% when using screen (it unsets environment variables...)
% not working
% system('export LD_LIBRARY_PATH=/net/per900b/raid0/ledduy/usr.local/lib:/net/per900a/raid0/plsang/usr.local/lib:/usr/local/lib:$LD_LIBRARY_PATH');

% vlfeat
run('/net/per900a/raid0/plsang/tools/vlfeat-0.9.16/toolbox/vl_setup');

addpath('/net/per610a/export/das11f/plsang/codes/kaori-secode-vsd/learning/support');

addpath('/net/per610a/export/das11f/plsang/codes/common/enceval-toolkit-1.1');

% libsvm
addpath('/net/per900a/raid0/plsang/tools/libsvm-3.17/matlab');

addpath('/net/per610a/export/das11f/plsang/codes/common');

% mfcc - kmail
addpath('/net/per900a/raid0/plsang/tools/mfcc-kamil');

% voicebox
addpath('/net/per900a/raid0/plsang/tools/voicebox');

% rastamat
addpath('/net/per900a/raid0/plsang/software/rastamat');

% lib gmm-fisher
addpath('/net/per900a/raid0/plsang/tools/gmm-fisher-kaori/matlab');

% gist descriptor
% addpath('/net/per900a/raid0/plsang/software/gistdescriptor');

%featpipem_addpaths