function med2012_video_pooling(feat_name, feat_dim)
	filename='/net/per610a/export/das11f/plsang/trecvidmed/metadata/med12/medmd_2012.mat';
    fprintf('Loading meta file <%s>\n', filename);
    load(filename, 'MEDMD');
	
	root_fea_dir = '/net/per610a/export/das11f/plsang/trecvidmed/feature/med.pooling.seg4';
    fea_dir = sprintf('%s/%s', root_fea_dir, feat_name);
	
	output_dir = '/net/per610a/export/das11f/plsang/trecvidmed/feature/summax.pooling';
	
	num_aggs = [2, 4, 8, 16, 32, 64];  %% 8, 16, 32, 64, 128, 256 s
	
	for num_agg = num_aggs,
	
		fprintf('Gen sum-max pooling with num_agg = %d, seg_len = %d \n', num_agg, 4*num_agg);
		
		output_fdir = sprintf('%s/%s.summax%d', output_dir, feat_name, 4*num_agg);
		
		for ii=1:length(MEDMD.clips),
			if ~mod(ii, 100), fprintf('%d ', ii); end;
			
			video_id = MEDMD.clips{ii};
			feat_pat = MEDMD.info.(video_id).loc;
			
			output_file = sprintf('%s/%s', output_fdir, feat_pat(1:end-4));
			if exist(output_file, 'file'), 	fprintf('File %s existed \n', output_file);  continue; end;
			
			feat_file = sprintf('%s/%s.mat', fea_dir, feat_pat(1:end-4));
			load(feat_file, 'code');
			total_unit_seg = size(code, 2);
			idxs = 1:num_agg:total_unit_seg;
			featMat_ = zeros(feat_dim, length(idxs));
			remove_last_seg = 0;
			for jj=1:length(idxs),
				start_idx = idxs(jj);
				end_idx = start_idx + num_agg - 1;
				if end_idx > total_unit_seg, end_idx = total_unit_seg; end;
				code_ = code(:, start_idx:end_idx);
				
				if any(any(isnan(code_), 1)),
					code_ = code_(:, ~any(isnan(code_), 1));
				end
				
				if isempty(code_) && end_idx == total_unit_seg,
					remove_last_seg = 1;
					break;
				end
				
				featMat_(:, jj) = sum(code_, 2);
				clear code_;
			end
			
			if remove_last_seg,
				fprintf('Last seg of video <%s> contains NaN. Removing...\n', feat_pat);
				featMat(start_idx:end, :) = [];
			end
			
			featMat_ = l2_norm_matrix(featMat_);
			
			code = max(featMat_, [], 2);
			
			if ~exist(fileparts(output_file), 'file'),
				mkdir(fileparts(output_file));
			end
			
			save(output_file, 'code');
			
		end
		
	end
	
end

function X = l2_norm_matrix(X),
    for ii=1:size(X, 2),
        if any(X(:,ii) ~= 0), 
            X(:,ii) = X(:,ii) / norm(X(:,ii), 2);
        end
    end
end    
