function configs = set_global_config()
	root_dir = '/net/per610a/export/das11f/plsang/codes/summax-pooling-journal';
	configs.logdir = sprintf('%s/log', root_dir);
	configs.sgelogdir = sprintf('%s/sgelog', root_dir);
	configs.local_script_dir = sprintf('%s/local_scripts', root_dir);
	configs.src_dir = root_dir;
end
