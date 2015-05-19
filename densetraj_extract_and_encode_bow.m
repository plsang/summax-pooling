function [ code_sum, code_max ] = densetraj_extract_and_encode_bow( video_file, start_frame, end_frame, descriptor, codebook, kdtree, enc_type )
%EXTRACT_AND_ENCODE Summary of this function goes here

    % densetraj = '/net/per900a/raid0/plsang/tools/dense_trajectory_release/release/DenseTrack_FULL';
	% densetraj = '/net/per900a/raid0/plsang/software/dense_trajectory_release_v1.1/release/DenseTrack';
	% densetraj = '/net/per900a/raid0/plsang/software/dense_trajectory_release_v1.1/release/DenseTrack_Org';
    % Set up the mpeg audio decode command as a readable stream
    densetraj = '/net/per900a/raid0/plsang/tools/dense_trajectory_release/release/DenseTrack_MBH';
    
    cmd = [densetraj, ' ', video_file, ' -S ', num2str(start_frame), ' -E ', num2str(end_frame)];

    % open pipe
    p = popenr(cmd);

    if p < 0
      error(['Error running popenr(', cmd,')']);
   end
	
   feat_dim = 192;
   full_dim = 199;		
	
    BLOCK_SIZE = 50000;                          % initial capacity (& increment size)
    %listSize = BLOCK_SIZE;                      % current list capacity
    X = zeros(feat_dim, BLOCK_SIZE);
    listPtr = 1;
    
    %tic

    code_sum = zeros(size(codebook, 2), 1);
    
    code_max = zeros(size(codebook, 2), 1);
    
    while true,

      % Get the next chunk of data from the process
      Y = popenr(p, full_dim, 'float');
	  
      if isempty(Y), break; end;

	  if length(Y) ~= full_dim,
			msg = ['wrong dimension [', num2str(length(Y)), '] when running [', cmd, '] at ', datestr(now)];
			%log(msg);
			continue;                                    
	  end
	  
      %X = [X Y(8:end)]; % discard first 7 elements
      X(:, listPtr) = Y(8:end);
      listPtr = listPtr + 1; 
      
      if listPtr > BLOCK_SIZE,
          % encode
          if strcmp(enc_type, 'vq'),        
                code_ = vqencode(X, codebook, kdtree);
          elseif strcmp(enc_type, 'kcb'),        
              code_ = kcbencode(X, codebook, kdtree);
          end
          
          code_max = max(code_max, max(code_, [], 2));
          
          code_sum = code_sum + sum(code_, 2);
          
          listPtr = 1;
          X(:,:) = 0;
          
      end
    
    end

    if (listPtr > 1)
        
        X(:, listPtr:end) = [];   % remove unused slots
        
        if strcmp(enc_type, 'vq'),        
            code_ = vqencode(X, codebook, kdtree);
        elseif strcmp(enc_type, 'kcb'),        
            code_ = kcbencode(X, codebook, kdtree);
        end
        
        code_max = max(code_max, max(code_, [], 2));
          
        code_sum = code_sum + sum(code_, 2);

    end
    
    % convert to full matrix
    code_max = full(code_max);
    code_sum = full(code_sum);
    
    % Close pipe
    popenr(p, -1);

end
