function count_mean_segment_vr(threshold)
	dataset = 'trecvidmed10';
	kf_dir_name = 'keyframe-100000';
	
	total_devel_shot = count_mean_segment_vr_(dataset, kf_dir_name, 'devel', threshold);
	total_test_shot = count_mean_segment_vr_(dataset, kf_dir_name, 'test', threshold);
	
	total_devel_duration = 202377.17;
	total_test_duration = 209906.43;
	
	mean_devel = total_devel_duration/total_devel_shot;
	mean_test = total_test_duration/total_test_shot;
	
	fprintf('mean devel: %f,  mean test = %f', mean_devel, mean_test);
	
	log_file = sprintf('/net/per900a/raid0/plsang/dataset/MED10_Resized_meta/sbd-t%d.log', threshold);
	fh = fopen(log_file, 'a');
	fprintf(fh, 'dataset: %s\n', dataset);
	fprintf(fh, 'devel: total_shot, total_duration, mean_shot: %d, %f, %f \n', total_devel_shot, total_devel_duration, mean_devel);
	fprintf(fh, 'test: total_shot, total_duration, mean_shot: %d, %f, %f \n', total_test_shot, total_test_duration, mean_test);
	fclose(fh);
	
end


function total_shot = count_mean_segment_vr_(proj_name, kf_dir_name, szPat, threshold)
	% proj_name = 'trecvidmed10';
	% kf_dir_name = 'keyframe-100000';
	% szPat = 'devel';
	
	videolst = sprintf('/net/per900a/raid0/plsang/%s/metadata/%s/%s.%s.lst', proj_name, kf_dir_name, proj_name, szPat);
    fh = fopen(videolst);
    infos = textscan(fh, '%s %*q %s %*q %s');
    fclose(fh);
    videos = infos{1};
	
	%sbd infos
	shotinfo_dir = sprintf('/net/per900a/raid0/plsang/dataset/MED10_Resized_meta/sbd-t%d', threshold);
	
	total_shot = 0;
	for ii=1:length(videos),
		video = videos{ii};
		
		shotinfo_file = sprintf('%s/%s.txt', shotinfo_dir, video);
		fh = fopen(shotinfo_file, 'r');
		str = textscan(fh, '%s');
		fclose(fh);
		%keyboard
		num_shot = length(str{1}) - 5;
		total_shot = total_shot + num_shot;
		
	end
	fprintf('partition: %s.  total_shot: %d\n', szPat, total_shot);
	
end