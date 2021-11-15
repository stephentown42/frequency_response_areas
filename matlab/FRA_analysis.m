classdef FRA
    %FRA Helper FRA functions to be used in WARP and neuropixel here

    %calculate the mean spontaneous rate and calculate a threshold based on spontaneous
    %rate+20% of max rate during stimulus-spontaneous rate.                      
    % >>> srate=mean(spon,'all')+(1/5*(max(max(spikes))))

    methods (Static)
        
        function z = smoothFRA(z)
            
            % Do some smoothing
            %                         % Create a sliding window
            s = [0.25 0.5 0.25;
                0.5  1   0.5;
                0.25 0.5 0.25];
            s          = s/sum(s(:)); %normalise the window
            [m,n]      = size(z);
            p          = [];
            p(:,1)     = z(:,1);
            p(:,2:n+1) = z;
            p(:,n+2)   = z(:,n);
            p(2:m+1,:) = p(1:m,:);
            p(1,:)     = p(1,:);
            p(m+2,:)   = p(m,:);
            z2     = conv2(p,s,'same'); %smooth
            z = z2(2:m+1,2:n+1);%remove the padding
        end
        
        function [bounds,CF,Q10,Q30] = calculateFRAbounds(spikes,nFreqs,nLevel,freqs,srate)
            % Then do the bounds
            bounds=[];
            for ii=1:nFreqs
                for jj=1:nLevel
                    if spikes(jj,ii)<srate & jj <nLevel
                        %no response, move on to next level
                    elseif spikes(jj,ii)>=srate & jj==1
                        %response at lowest level, move onto next to see if real
                        % elseif jj<5 & spikes(jj+4,ii)<srate & spikes(jj+5)<srate
                    elseif spikes(jj,ii)>=srate & jj>1 & spikes(jj-1,ii)>=srate & jj<nLevel-2 & spikes(jj+1,ii)>=srate & spikes(jj+2,ii)>srate
                        bounds(ii)=jj-1;
                        break
                        %if the response is there at 4 (for finer sampling) consequetive levels, set bounds
                        %for the level it first appeared at
                    elseif spikes(jj,ii)>=srate & jj==nLevel-1 & spikes(jj-1,ii)>=srate & jj>nLevel-2 & spikes(jj+1,ii)>=srate
                        bounds(ii)=jj-1;
                        break
                    elseif spikes(jj,ii)>=srate & jj==nLevel & spikes(jj-1,ii)>=srate
                        bounds(ii)=jj-1;
                        break
                        %if this is the highest level and there is a response here and
                        %at level-1 set bounds to level first appeared at
                    elseif spikes(jj,ii)>=srate & jj==nLevel
                        bounds(ii)=nLevel;
                        %if there is only a response at the highest level take this
                        %level
                    elseif jj==nLevel & spikes(jj,ii)<srate % & spikes(jj-1,ii)<srate
                        bounds(ii)=nLevel+1;
                        %if there are no responses then bounds =nlevels+1;
                    end
                end
            end
            
            for ii=2:length(bounds)-1
                if bounds(ii-1)==nLevel+1 && bounds(ii+1)==nLevel+1 & bounds(ii)<4
                    bounds(ii)=nLevel+1;
                end
            end
            
            % If it is at the floor /max(7) then make it +1 so
            % that it is off the plot - only applicable if using imagesc to plot -
            % don't need it for contourf
            % for currBound = 1:length(bounds)
            %     if bounds(currBound) == 7
            %         bounds(currBound) = 8;
            %     end
            % end
            
            
            
            % calculate the CF
            if ~isempty(bounds)
                if length(unique(bounds))==1
                    CF = NaN; % If flat no CF
                else
                    CF = freqs(find(bounds==min(bounds)));
                end
            else
                CF = NaN;
            end
            if length(CF)>1
                % Will need to take the logarithmic weighted
                % mean
                Idx = find(bounds==min(bounds));
                if unique(diff(Idx))==1
                    % Do a logarthmic weighted mean if they are
                    % all together.
                    CF = exp(mean(log(freqs(Idx))));
                    
                else
                    CF = NaN;
                end
            end
            
            
            if ~isnan(CF)
                % Calculate Q10 and Q30
                Idx = find(bounds==min(bounds));
                Q10start = Idx(1);
                if Q10start ~= 1
                    while bounds(Q10start-1) == min(bounds)+1
                        Q10start = Q10start-1;
                        if bounds(Q10start) == max(bounds) || Q10start == 1
                            break
                        end
                    end
                end
                Q10end = Idx(end);
                if Q10end ~= numel(bounds)
                    while bounds(Q10end+1) == min(bounds)+1
                        Q10end = Q10end+1;
                        if bounds(Q10end) == max(bounds) || Q10end == numel(bounds)
                            break
                        end
                    end
                end
                
                Q30start = Q10start;
                if Q30start ~= 1
                    while bounds(Q30start-1) <= min(bounds)+3
                        Q30start = Q30start-1;
                        if bounds(Q30start) == max(bounds) || Q30start == 1
                            break
                        end
                    end
                end
                Q30end = Q10end;
                if Q30end ~= numel(bounds)
                    while bounds(Q30end+1) <= min(bounds)+3
                        Q30end = Q30end+1;
                        if bounds(Q30end) == max(bounds) || Q30end == numel(bounds)
                            break
                        end
                    end
                end
                Q10 = freqs([Q10start Q10end]);
                Q30 = freqs([Q30start Q30end]);
                
                
            else
                Q10 = nan(1,2);
                Q30 = nan(1,2);
                %                 figure;plot(bounds); hold on; plot([Q10start Q10end],[min(bounds)+1 min(bounds+1)])
            end
        end
    end
end
