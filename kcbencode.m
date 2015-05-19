function [ code ] = kcbencode( feats, codebook, kdtree, pool_type )
%KCBENCODE Summary of this function goes here
%   Detailed explanation goes here

     norm_type = 'none';
     max_comps = 500;
     num_nn = 5;
     sigma = 0.2; % sigma = 1/(sqrt(2*beta)), beta = 10 in LCS paper [Liu-ICCV2011]
     kcb_type = 'unc';
            
     % setup encoder
     
     %kdtree = vl_kdtreebuild(codebook);
     
     % note: out put is a 4000xNumFeats matrix
    if max_comps ~= 1
        % using ann...
        code = featpipem.lib.KCBEncode(feats, codebook, num_nn, ...
        sigma, kdtree, max_comps, kcb_type, true);
    else
        % using exact assignment...
        code = featpipem.lib.KCBEncode(feats, codebook, num_nn, ...
        sigma, [], [], kcb_type, true);
    end
    
    % Normalize -----------------------------------------------------------
    
    %if strcmp(norm_type, 'l1')
    %    code = code / norm(code,1);
    %end
    %if strcmp(norm_type, 'l2')
    %    code = code / norm(code,2);
    %end
    
    %if strcmp(pool_type, 'max')
    %    code = sum(code, 2);     % 4000x1
    %elseif strcmp(pool_type, 'sum')
    %    code = max(code, [], 2); % 4000x1
    %end
end

