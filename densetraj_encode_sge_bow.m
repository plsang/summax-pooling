function [ output_args ] = densetraj_encode_sge_bow( proj_name, szPat, enc_type, start_seg, end_seg )
	% using fix length segment
    % setting
    set_env;
	
    % encoding type
    %enc_type = 'kcb';
	
    codebook_size = 4000;
    descriptor = 'mbh';
	segment_length = 450;
	traj_length = 15;
	segann_method = 1; % 0: equal length, 1: using shot detection
	sim_threshold = 0.5;
	
	vr_threshold = 95;
	vr_info_dir = sprintf('/net/per900a/raid0/plsang/dataset/MED10_Resized_meta/sbd-t%d', vr_threshold);
	
	segment_ann = sprintf('dt.%s.bow%d.%s', descriptor, codebook_size, enc_type);
	 
    root_dir = '/net/per610a/export/das11f/plsang';
	switch proj_name
		case 'trecvidmed10'
			video_dir = '/net/per900a/raid0/plsang/dataset/MED10_Resized';
			info_file = '/net/per900a/raid0/plsang/trecvidmed10/metadata/common/trecvidmed10.mat';
		case 'trecvidmed11'
			if strcmp(szPat, 'devel'),
				video_dir = '/net/per900a/raid0/plsang/dataset/MED11_Resized/MED11DEV';
			elseif strcmp(szPat, 'test'),
				video_dir = '/net/per900a/raid0/plsang/dataset/MED11_Resized/MED11TEST';
			else
				error('Unknown input patition!');
			end
			info_file = sprintf('/net/per900a/raid0/plsang/%s/metadata/common/%s_%s.mat', proj_name, proj_name, szPat);
		otherwise
			error('Unknown dataset!');
	end
	
	shot_info_file = sprintf('/net/per900a/raid0/plsang/%s/metadata/common/%s_%s_shotinfo.mat', proj_name, proj_name, szPat);
	if segann_method == 1,
		fprintf('Loading shot infos...\n');
		load(shot_info_file, 'shot_infos');
	end
	
	fea_dir = sprintf('%s/%s/feature', root_dir, proj_name);
	
	
	fprintf('Loading infos...\n');
	load(info_file, 'infos');
	
	fprintf('Loading segment metadata...\n');
	segments = load_segments( proj_name, szPat, 'keyframe-100000' );
	
	videos = fieldnames(infos);
	
	if segann_method == 0,
		feature_ext = sprintf('densetrajectory.%s.cb%d.%s.segments%d', descriptor, codebook_size, enc_type, segment_length);
	elseif segann_method == 1,
		feature_ext = sprintf('densetrajectory.%s.cb%d.%s.shot%0.3f', descriptor, codebook_size, enc_type, sim_threshold);
	elseif segann_method == 2,
		feature_ext = sprintf('densetrajectory.%s.cb%d.%s.sbd%d', descriptor, codebook_size, enc_type, vr_threshold);
	end
	
	output_sum_dir = sprintf('%s/%s/%s.sumpool/%s', fea_dir, segment_ann, feature_ext, szPat) ;
    output_max_dir = sprintf('%s/%s/%s.maxpool/%s', fea_dir, segment_ann, feature_ext, szPat) ;
	
    if ~exist(output_sum_dir, 'file'),
        mkdir(output_sum_dir);
    end
	
	if ~exist(output_max_dir, 'file'),
        mkdir(output_max_dir);
    end
	
	codebook_file = sprintf('%s/%s/feature/bow.codebook.devel/densetrajectory.%s/data/codebook.kmeans.%d.mat', root_dir, proj_name, descriptor, codebook_size);
	
    codebook_ = load(codebook_file, 'codebook');
    codebook = codebook_.codebook;
	
	kdtree = vl_kdtreebuild(codebook);
	
    if start_seg < 1,
        start_seg = 1;
    end
    
    if end_seg > length(segments),
        end_seg = length(segments);
    end
   
	pattern =  '(?<video>\w+)\.\w+\.frame(?<start_f>\d+)_(?<end_f>\d+)';
	
    count_not_exist = 0;
    count_not_done = 0;
	
    for ii = start_seg:end_seg,
		segment = segments{ii};
		
        info = regexp(segment, pattern, 'names');
		
        video = info.video;
        
        output_sum_file = [output_sum_dir, '/', video, '/', video, '.mat'];
        output_max_file = [output_max_dir, '/', video, '/', video, '.mat'];
        if exist(output_sum_file, 'file') && exist(output_max_file, 'file'),
            fprintf('Output file for video [%s] already exist. Skipped!!\n', video);
            continue;
        end
        
        video_file = [video_dir, '/', video, '.mp4'];
        
        start_frame = 1;
        end_frame = infos.(video);
        
        fprintf(' [%d --> %d --> %d] Extracting & Encoding for [%s]...\n', start_seg, ii, end_seg, video);
        
		if segann_method == 0,
			code_sum = zeros(codebook_size, length(start_frame:segment_length:end_frame));
			code_max = zeros(codebook_size, length(start_frame:segment_length:end_frame));
			
			seg_idx = 1;
			
			for jj=start_frame:segment_length:end_frame,
				start_f = jj;
				
				% from second segment, minus 14 frames
				if start_f > 1,
					start_f = start_f - traj_length + 1;
				end
				
				end_f = jj + segment_length - 1;
				if end_f > end_frame,
					end_f = end_frame;
				end
				
				[code_sum(:,seg_idx), code_max(:,seg_idx)] = densetraj_extract_and_encode_bow(video_file, start_f, end_f, descriptor, codebook, kdtree, enc_type); %important
				
				seg_idx = seg_idx + 1;
			end
			
		elseif segann_method == 1,
            
            if ~isfield(shot_infos, video),
                count_not_exist = count_not_exist + 1;
            else
                count_not_done = count_not_done + 1;
            end
            
            continue;
            
			frame_idx = shot_infos.(video).scores < sim_threshold;
			frame_infos = shot_infos.(video).frames(frame_idx);
			code_sum = zeros(codebook_size, length(frame_infos) - 1);
			code_max = zeros(codebook_size, length(frame_infos) - 1);
			
			seg_idx = 1;
			for jj=1:length(frame_infos) -1,
				start_f = frame_infos(jj);
				
				% from second segment, minus 14 frames
				if start_f > 1,
					start_f = start_f - traj_length + 1;
				end
				
				if start_f < 1,
					start_f = 1;
				end
				
				end_f = frame_infos(jj+1) - 1;
				if end_f > end_frame,
					end_f = end_frame;
				end
				
				[code_sum(:,seg_idx), code_max(:,seg_idx)] = densetraj_extract_and_encode_bow(video_file, start_f, end_f, descriptor, codebook, kdtree, enc_type);
				
				seg_idx = seg_idx + 1;
			end
		elseif segann_method == 2,	%shot boundary detection
			
			shotinfo_file = sprintf('%s/%s.txt', vr_info_dir, video);
			fh = fopen(shotinfo_file, 'r');
			str = textscan(fh, '%s');
			fclose(fh);
			str = str{1};
			str = str(5:end);
			frame_infos = cellfun(@(x) str2num(x), str);
			
			code_sum = zeros(codebook_size, length(frame_infos) - 1);
			code_max = zeros(codebook_size, length(frame_infos) - 1);
			
			seg_idx = 1;
			for jj=1:length(frame_infos) -1,
				start_f = frame_infos(jj);
				
				% from second segment, minus 14 frames
				if start_f > 1,
					start_f = start_f - traj_length + 1;
				end
				
				if start_f < 1,
					start_f = 1;
				end
				
				end_f = frame_infos(jj+1) - 1;
				if end_f > end_frame,
					end_f = end_frame;
				end
				
				[code_sum(:,seg_idx), code_max(:,seg_idx)] = densetraj_extract_and_encode_bow(video_file, start_f, end_f, descriptor, codebook, kdtree, enc_type);
				
				seg_idx = seg_idx + 1;
			end
			
		end
		
        par_save(output_sum_file, code_sum); % MATLAB don't allow to save inside parfor loop
        par_save(output_max_file, code_max); % MATLAB don't allow to save inside parfor loop
		
    end
	
    fprintf(' count_not_exist = %d. count_not_done = %d \n', count_not_exist, count_not_done);
	quit;

end

function par_save( output_file, code )
     output_dir = fileparts(output_file);
     if ~exist(output_dir, 'file'),
         mkdir(output_dir);
     end
     save( output_file, 'code');
end

% if two consecutive frames is too narrow, extend it
function X = normalize_frames(frames)
	for ii=1:length(frames) - 1,
		if frames(ii) + 15 >= frames(ii+1),
			frames(ii+1) = [];
			X = normalize_frames(frames);
			return;
		end
	end
	X = frames;
end