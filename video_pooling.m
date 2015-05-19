function video_pooling(proj_name, szPat)
    
	root_dir = '/net/per610a/export/das11f/plsang';
	video_dir = '/net/per900a/raid0/plsang/dataset/MED10_Resized';
	fea_dir = sprintf('%s/%s/feature', root_dir, proj_name);
   
    enc_type = 'kcb';
    codebook_size = 4000;
    descriptor = 'mbh';
    segment_length = 450; % frames;
    traj_length = 15;
    dimred = 128;
	segnorm = 0;
	segann_method = 0; % 0: equal length, 1: using shot detection
	sim_threshold = 0.05;
	
	segment_ann = sprintf('dt.%s.bow%d.%s', descriptor, codebook_size, enc_type);
	
    if segann_method == 0,
		feature_ext = sprintf('densetrajectory.%s.cb%d.%s.segments%d', descriptor, codebook_size, enc_type, segment_length);
	elseif segann_method == 1,
		feature_ext = sprintf('densetrajectory.%s.cb%d.%s.shot%0.3f', descriptor, codebook_size, enc_type, sim_threshold);
	end
	
	output_sum_dir = sprintf('%s/%s/%s.sumpool/%s', fea_dir, segment_ann, feature_ext, szPat) ;
    output_max_dir = sprintf('%s/%s/%s.maxpool/%s', fea_dir, segment_ann, feature_ext, szPat) ;
    
    segments = load_segments(proj_name, szPat, 'keyframe-100000');
    
    %lengths = [15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165, 180, 195, 210];
	lengths = [30, 60, 90, 120, 150, 180, 210];
    
    parfor ii = 1:length(segments),
        segment = segments{ii};
        
        fprintf(' [%d/%d] Video pooling for segment [%s]...\n', ii, length(segments), segment);
        
        pattern =  '(?<video>\w+)\.\w+\.frame(?<start>\d+)_(?<end>\d+)';
        info = regexp(segment, pattern, 'names');
        
        output_sum_file = [output_sum_dir, '/', info.video, '/', info.video, '.mat'];
        output_max_file = [output_max_dir, '/', info.video, '/', info.video, '.mat'];
        if ~exist(output_sum_file, 'file') || ~exist(output_max_file, 'file'),
            error('Output file for segment [%s] does not exist. Skipped!!\n', output_sum_file);
        end
        
        code_sum = load(output_sum_file);
        code_sum = code_sum.code;
        
        code_max = load(output_max_file);
        code_max = code_max.code;
        
		if segnorm == 1,
			code_sum = norm_matrix(code_sum);
			code_max = norm_matrix(code_max);
		end
        
		
		code_sum_ = code_sum(:, ~any(isnan(code_sum), 1));
        code_sum_sum = sum(code_sum_, 2);
		
		code_max_ = code_max(:, ~any(isnan(code_max), 1));
        code_max_max = max(code_max_, [], 2);
        
        output_sum_sum_dir = sprintf('%s/%s/%s.agg.sumsum/%s', fea_dir, segment_ann, feature_ext, szPat) ;
		if segnorm == 1,
			output_sum_sum_dir = sprintf('%s/%s/%s.agg.segnorm.sumsum/%s', fea_dir, segment_ann, feature_ext, szPat) ;
		end
        par_save(output_sum_sum_dir, info.video, code_sum_sum);
 
        output_max_max_dir = sprintf('%s/%s/%s.agg.maxmax/%s', fea_dir, segment_ann, feature_ext, szPat) ;
		if segnorm == 1,
			output_max_max_dir = sprintf('%s/%s/%s.agg.segnorm.maxmax/%s', fea_dir, segment_ann, feature_ext, szPat) ;
		end
        par_save(output_max_max_dir, info.video, code_max_max);
        
        %% sum - max
        for jj=1:length(lengths),
            num_seg = ceil(size(code_sum, 2)/jj); % number of segments
            code_sum_jj = zeros(codebook_size, num_seg);
            code_max_jj = zeros(codebook_size, num_seg);
            
            for kk=1:num_seg,
                start_idx = (kk-1)*jj+1;
                end_idx = kk*jj;
                if end_idx > size(code_sum, 2),
                    end_idx = size(code_sum, 2);
                end
				code_sum_jj_ = code_sum(:, start_idx:end_idx);
				code_sum_jj_ = code_sum_jj_(:, ~any(isnan(code_sum_jj_), 1));
                code_sum_jj(:, kk) = sum(code_sum_jj_, 2);
				
				code_max_jj_ = code_max(:, start_idx:end_idx);
				code_max_jj_ = code_max_jj_(:, ~any(isnan(code_max_jj_), 1));
                code_max_jj(:, kk) = max(code_max_jj_, [], 2);
				
                %code_max_jj(:, kk) = max(code_max(:, start_idx:end_idx), [], 2);
            end
            
            code_sum_max = max(code_sum_jj, [], 2);
            code_max_sum = sum(code_max_jj, 2);
            
            %code_sum_sum = sum(code_sum_jj, 2);
            %code_max_max = max(code_max_jj, [], 2);
            
            output_sum_max_dir = sprintf('%s/%s/%s.agg.summax%d/%s', fea_dir, segment_ann, feature_ext, lengths(jj), szPat) ;
			output_max_sum_dir = sprintf('%s/%s/%s.agg.maxsum%d/%s', fea_dir, segment_ann, feature_ext, lengths(jj), szPat) ;
			
            if segnorm == 1,
				output_sum_max_dir = sprintf('%s/%s/%s.agg.segnorm.summax%d/%s', fea_dir, segment_ann, feature_ext, lengths(jj), szPat) ;
				output_max_sum_dir = sprintf('%s/%s/%s.agg.segnorm.maxsum%d/%s', fea_dir, segment_ann, feature_ext, lengths(jj), szPat) ;
			end
			
            %saving
            par_save(output_sum_max_dir, info.video, code_sum_max);
            par_save(output_max_sum_dir, info.video, code_max_sum);
            
        end
        
    end
    

end

function X = norm_matrix(X),
    for ii=1:size(X, 2),
        if any(X(:,ii) ~= 0), 
            X(:,ii) = X(:,ii) / norm(X(:,ii), 2);
        end
    end
end
        
function par_save( output_dir, video, code )

     output_file = [output_dir, '/', video, '/', video, '.mat'];
     
     base_dir = fileparts(output_file);
     if ~exist(base_dir, 'file'),
         mkdir(base_dir);
     end
     
     save( output_file, 'code');
 end
