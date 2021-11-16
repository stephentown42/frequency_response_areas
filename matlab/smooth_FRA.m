function smoothed_FRA = smooth_FRA(FRA)
% function z = smoothFRA(FRA)
            
    [m,n] = size(FRA);

    % Create a sliding window
    s = [0.25 0.5 0.25;
        0.5  1   0.5;
        0.25 0.5 0.25];    
    s = s/sum(s(:)); %normalise the window
    
    % Create padded version of FRA
    z = FRA.Variables;
    
    p = [z(:,1), z, z(:,n)];    
    p = [p(1,:); p; p(end-1,:)];     % This faithfully replicates old code, but I'm not sure why it's not p(end,:) at the end    
    
    % Smooth and remove padding
    z2 = conv2(p,s,'same'); 
    
    % Package using the same table as before
    smoothed_FRA = FRA;
    smoothed_FRA.Variables = z2(2:m+1,2:n+1);

