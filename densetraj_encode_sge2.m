function [ output_args ] = densetraj_encode_sge2( proj_name, segment_ann, szPat, start_seg, end_seg )
	% using segment from shot boundary detection
    
    % setting
    set_env;
    
	
    % encoding type
    enc_type = 'kcb';
    codebook_size = 256;
    descriptor = 'mbh';
    
    bow_encoding = 0;	
	fc_encoding = 1;	
	dimred = 128;
	segment_length = 450;
	threshold = 0.05; 
	traj_length = 15;
	
    root_dir = '/net/per610a/export/das11f/plsang';
	video_dir = '/net/per900a/raid0/plsang/dataset/MED10_Resized';
	fea_dir = sprintf('%s/%s/feature', root_dir, proj_name);
	meta_dir = sprintf('/net/per900a/raid0/plsang/trecvidmed10/metadata/deepcaffe_%.3f/%s', threshold, szPat);
	
	fprintf('Loading segment metadata...\n');
	segments = load_segments( proj_name, szPat, segment_ann );
	
	feature_ext = sprintf('densetrajectory.mbh.cb%d.%s.t%.3f', codebook_size, enc_type, threshold);
	if dimred > 0,
		feature_ext = sprintf('%s.pca', feature_ext);
	end
	
	output_sum_dir = sprintf('%s/%s/%s.sumpool/%s', fea_dir, segment_ann, feature_ext, szPat) ;
    %output_max_dir = sprintf('%s/%s/%s.maxpool/%s', fea_dir, segment_ann, feature_ext, szPat) ;
	
    if ~exist(output_sum_dir, 'file'),
        mkdir(output_sum_dir);
    end
	
	% if ~exist(output_max_dir, 'file'),
        % mkdir(output_max_dir);
    % end
	
	codebook_gmm_file = sprintf('%s/%s/feature/bow.codebook.devel/densetrajectory.%s/data/codebook.gmm.%d.mat', root_dir, proj_name, descriptor, codebook_size);
	low_proj = [];
	
	if dimred > 0,
		codebook_gmm_file = sprintf('%s/%s/feature/bow.codebook.devel/densetrajectory.%s/data/codebook.gmm.%d.%d.mat', root_dir, proj_name, descriptor, codebook_size, dimred);
		low_proj_file = sprintf('%s/%s/feature/bow.codebook.devel/densetrajectory.%s/data/lowproj.%d.%d.mat', root_dir, proj_name, descriptor, dimred, 192);
		low_proj_ = load(low_proj_file, 'low_proj');
		low_proj = low_proj_.low_proj;
	end
    codebook_ = load(codebook_gmm_file, 'codebook');
    codebook = codebook_.codebook;
	
    if start_seg < 1,
        start_seg = 1;
    end
    
    if end_seg > length(segments),
        end_seg = length(segments);
    end
    
   
	pattern =  '(?<video>\w+)\.\w+\.frame(?<start_f>\d+)_(?<end_f>\d+)';
	
	
    for ii = start_seg:end_seg,
        segment = segments{ii};
                        
        info = regexp(segment, pattern, 'names');
        
        output_sum_file = [output_sum_dir, '/', info.video, '/', segment, '.mat'];
        %output_max_file = [output_max_dir, '/', info.video, '/', segment, '.mat'];
        if exist(output_sum_file, 'file'),
            fprintf('Output file for segment [%s] already exist. Skipped!!\n', segment);
            continue;
        end
        
        video_file = [video_dir, '/', info.video, '.mp4'];
        
		meta_file = sprintf('%s/%s.txt', meta_dir, info.video);
		fh = fopen(meta_file, 'r');
		infos = textscan(fh, '%d');
		infos = infos{1};
		fclose(fh);
		
        start_frame = str2num(info.start_f);
        end_frame = str2num(info.end_f);
        
        fprintf(' [%d --> %d --> %d] Extracting & Encoding for [%s]...\n', start_seg, ii, end_seg, segment);
        
        %code_sum = zeros(2*dimred*codebook_size, length(start_frame:segment_length:end_frame));
		code_sum = zeros(2*dimred*codebook_size, codebook_size, length(infos) - 1);
        %code_max = zeros(codebook_size, length(start_frame:segment_length:end_frame));
        
		
        seg_idx = 1;
        
        for jj=1:length(infos) -1,
            start_f = infos(jj);
            
            % from second segment, minus 14 frames
            if start_f > 1,
                start_f = start_f - traj_length + 1;
            end
			
			if start_f < 1,
                start_f = 1;
            end
            
            end_f = infos(jj+1) - 1;
            if end_f > end_frame,
                end_f = end_frame;
            end
            
            %[code_sum(:,seg_idx), code_max(:,seg_idx)] = densetraj_extract_and_encode_mbh(video_file, start_f, end_f, descriptor, codebook, kdtree, enc_type); %important
			code_sum(:,seg_idx) = densetraj_extract_and_encode(video_file, descriptor, codebook, low_proj, start_f, end_f); %important
            
            seg_idx = seg_idx + 1;
        end
        
        par_save(output_sum_file, code_sum); % MATLAB don't allow to save inside parfor loop
        %par_save(output_max_file, code_max); % MATLAB don't allow to save inside parfor loop
              
        %msg = sprintf(' +++ finish encoding for [%s]', segment);
        %log(msg);
    end
	
	quit;

end

function par_save( output_file, code )
     output_dir = fileparts(output_file);
     if ~exist(output_dir, 'file'),
         mkdir(output_dir);
     end
     save( output_file, 'code');
end


