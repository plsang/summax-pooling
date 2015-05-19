function gen_sge_code(script_name, pattern, total_segments, num_job, start_num)
	
	set_env;
	
	script_dir = '/net/per610a/export/das11f/plsang/codes/summax-pooling-journal';
	
	sge_sh_file = sprintf('%s/%s.sh', script_dir, script_name);
	
	
	[file_dir, file_name] = fileparts(sge_sh_file);
	output_dir = [script_dir, '/', script_name];

	if ~exist(output_dir, 'dir'),
		mkdir(output_dir);
		%change_perm(output_dir);
	end
	
	% error_dir = sprintf('%s/error-log', output_dir);
	% if exist(error_dir, 'file') ~= 7,
		% mkdir(error_dir);
		% %change_perm(error_dir);
	% end
	
	output_file = sprintf('%s/%s.qsub.sh', output_dir, file_name);
	fh = fopen(output_file, 'w');
	
	% gen <num_job> logaric space between two points: 1 and total_segments
	job_idxs = round(logspace(log10(1), log10(total_segments), num_job));
	
	start_idx = 1;
	for end_idx = job_idxs(2:end),
		
		if end_idx < start_idx,
			continue;
		end
		
		params = sprintf(pattern, start_idx, end_idx);
		fprintf(fh, 'qsub -e /dev/null -o /dev/null %s %s\n', sge_sh_file, params);
		%error_file = sprintf('%s/%s.error.s%06d_e%06d.log', error_dir, script_name, start_idx, end_idx);
		
		%fprintf(fh, 'qsub -e %s -o /dev/null %s %s\n', error_file, sge_sh_file, params);
		
		start_idx = end_idx+1;
	end
	
	cmd = sprintf('chmod +x %s', output_file);
	system(cmd);
	
	fclose(fh);
end