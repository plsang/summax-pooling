function [ segments, segment_infos, video_infos ] = load_segments( proj_name, szPat, kf_dir_name )
%LOAD_SEGMENTS Summary of this function goes here
%   Detailed explanation goes here
    videolst = sprintf('/net/per900a/raid0/plsang/%s/metadata/%s/%s.%s.lst', proj_name, kf_dir_name, proj_name, szPat);
    fh = fopen(videolst);
    infos = textscan(fh, '%s %*q %s %*q %s');
    fclose(fh);
    
    videos = infos{1};
    
    pats = infos{3};
    
	long_videos = {'HVC4248', 'HVC1379', 'HVC918', 'HVC5510', 'HVC5506', 'HVC1215'}; % MED 10
	
    segments = [];
    for ii = 1:length(videos),
        video = videos{ii};
		
		if any(ismember(long_videos, video) == 1),
            continue;
        end
		
        pat = pats{ii};
        mfile = sprintf('/net/per900a/raid0/plsang/%s/metadata/%s/%s/%s.prg', proj_name, kf_dir_name, pat, video);
       
        fh = fopen(mfile);
        this_segments = textscan(fh, '%s');
        this_segments = this_segments{1};
        segments = [segments; this_segments];
        fclose(fh);
    end
	
	%% update: Jul 5, 2013 -- creat infos struct
	video_infos = struct;
	segment_infos = zeros(2, length(segments));
	
	pattern =  '(?<video>\w+)\.\w+\.frame(?<start>\d+)_(?<end>\d+)';
	for ii = 1:length(segments),
		segment = segments{ii};    
		info = regexp(segment, pattern, 'names');
		start_frame = str2num(info.start);
        end_frame = str2num(info.end);
		if ~isfield(video_infos, info.video),
			video_infos.(info.video) = [start_frame, end_frame];
		else
			video_infos.(info.video) = [video_infos.(info.video), start_frame, end_frame]; 
		end	
		segment_infos(:, ii) = [start_frame; end_frame];
	end
	
	% update Nov 26: sort descending to segment length
	[segment_infos, idx] = sort(segment_infos, 2, 'descend');
	segments = segments(idx(2, :));
	
	
end

