function varargout = xyGateAmpTuner(varargin)
% tune xy gate amplitude: X, X/2, -X/2, X/4, -X/4, Y, Y/2, -Y/2, Y/4, -Y/4
% 
% <_f_> = xyGateAmpTuner('qubit',_c&o_,'gateTyp',_c_,...
%		'AENumPi',<_i_>,'tuneRange',<_f_>,...  % insert multiple Idle gate(implemented by two pi rotations) to Amplify Error or not
%       'gui',<_b_>,'save',<_b_>)
% _f_: float
% _i_: integer
% _c_: char or char string
% _b_: boolean
% _o_: object
% a&b: default type is a, but type b is also acceptable
% []: can be an array, scalar also acceptable
% {}: must be a cell array
% <>: optional, for input arguments, assume the default value if not specified
% arguments order not important as long as the form correct pairs.
    
    % Yulin Wu, 2017/1/8
    import data_taking.public.xmon.rabi_amp1
	
	NUM_RABI_SAMPLING_PTS = 30;
	MIN_VISIBILITY = 0.3;
	AE_NUM_PI = 11; % must be an positive odd integer
	
	args = qes.util.processArgs(varargin,{'AE',false,'AENumPi',AE_NUM_PI,'tuneRange',0.05,'gui',false,'save',true});
    args.AENumPi = round(args.AENumPi);
    if mod(args.AENumPi,2) ==0 || args.AENumPi <= 0
        error('AENumPi not a positive odd integer.');
    end
	if args.tuneRange <= 0 || args.tuneRange >= 1
		throw(MException('QOS_xyGateAmpTuner:IllegalArgument',...
				'tuneRange range not withing (0,1))');
	end
	
	qubits = args.qubits;
	if ~iscell(qubits)
		qubits = {qubits};
	end
	
	numQs = numel(qubits);
	allf01s = nan(1,numQs);
    for ii = 1:numQs
        if ischar(qubits{ii})
            qubits{ii} = sqc.util.qName2Obj(qubits{ii});
        end
		F = qubits{ii}.r_iq2prob_fidelity;
		vis = F(1)+F(2)-1;
		if vis < 0.2
			throw(MException('QOS_xyGateAmpTuner:visibilityTooLow',...
				sprintf('%s visibility(%0.2f) too low, run xyGateAmpTuner at low visibility might produce wrong results, thus not supported.', ...
					qubits{ii}.name, vis)));
		end
		qubits{ii}.r_iq2prob_intrinsic = true;
    end

	switch args.gateTyp
		case {'X','Y'}
% 			maxAmp = da.vpp/2;
		case {'X/2','-X/2','X2m','X2p','Y/2','-Y/2','Y2m','Y2p'}
% 			maxAmp = da.vpp/4;
        case {'X/4','-X/4','X4m','X4p','Y/4','-Y/4','Y4m','Y4p'}
% 			maxAmp = da.vpp/8;
		otherwise
			throw(MException('QOS_xyGateAmpTuner:unsupportedGataType',...
				sprintf('gate %s is not supported, supported types are %s',args.gateTyp,...
				'X Y X/2 -X/2 X2m X2p X/4 -X/4 X4m X4p Y/2 -Y/2 Y2m Y2p Y/4 -Y/4 Y4m Y4p')));
    end
    
    QS = qes.qSettings.GetInstance();
	switch args.gateTyp
        case {'X','Y'}
            gateAmpSettingsKey ='g_XY_amp';
        case {'X/2','X2p','-X/2','X2m','Y/2','Y2p','-Y/2','Y2m'}
            gateAmpSettingsKey ='g_XY2_amp';
        case {'X/4','X4p','-X/4','X4m','Y/4','Y4p','-Y/4','Y4m'}
            gateAmpSettingsKey ='g_XY4_amp';
        otherwise
            throw(MException('QOS_xyGateAmpTuner:unsupportedGataType',...
                sprintf('gate %s is not supported, supported types are %s',args.gateTyp,...
                'X Y X/2 -X/2 X2m X2p X/4 -X/4 X4m X4p Y/2 -Y/2 Y2m Y2p Y/4 -Y/4 Y4m Y4p')));
    end
	amps = cell(1,numQs);
	for ii = 1:numQs
		da = qes.qHandle.FindByClassProp('qes.hwdriver.hardware',...
                        'name', qubits{ii}.channels.xy_i.instru);
		daChnl = da.GetChnl(qubits{ii}.channels.xy_i.chnl);
		currentGateAmp = qubits{ii}.(gateAmpSettingsKey); % QS.loadSSettings({q.name,gateAmpSettingsKey});
		% amps{ii} = linspace(0.95*gateAmp,min(daChnl.vpp,1.05*gateAmp),NUM_RABI_SAMPLING_PTS*3);
		amps{ii} = linspace((1-args.tuneRange)*currentGateAmp,...
				min(daChnl.vpp,(1+args.tuneRange)*currentGateAmp),NUM_RABI_SAMPLING_PTS*3);
	end

	e = rabi_amp1('qubit',qubits,'biasAmp',0,'biasLonger',0,'xyDriveAmp',amps,...
		'detuning',0,'numPi',numPi0,'driveTyp',args.gateTyp,'gui',false,'save',false);
	
	data = e.data{1};
	data = cell2mat(data(:));
	
	allGateAmps = nan(1,numQs);
	for ii = 1:numQs
	q = qubits{ii};
    P = data(:,ii);
	
	rP = range(P);
	P0 = min(P);
	P1 = max(P);
	if rP < MIN_VISIBILITY
		throw(MException('QOS_xyGateAmpTuner:visibilityTooLow',...
				sprintf('visibility(%0.2f) too low, run xyGateAmpTuner at low visibility might produce wrong result, thus not supported.', rP)));
	elseif rP < 5/sqrt(q.r_avg)
		throw(MException('QOS_xyGateAmpTuner:rAvgTooLow',...
				'readout average number %d too small.', q.r_avg));
    end
    
    gateAmp = findsPkLoc(amps,P);
	allGateAmps(ii) = gateAmp;
	if isempty(gateAmp)
		throw(MException('QOS_xyGateAmpTuner:gateAmpNotFound',...
				'%s gateAmp for qubit %s not found', args.gateTyp, q.name));
	end
    
	if args.gui
		h = qes.ui.qosFigure(sprintf('XY Gate Tuner | %s: %s', q.name, args.gateTyp),true);
		ax = axes('parent',h);
		plot(ax,amps,P,'-b');
		hold(ax,'on');
        if args.AE
           plot(ax,amps_ae,P_ae);
        end
%         ylim = get(ax,'YLim');
        ylim = [0,1];
        plot(ax,[gateAmp,gateAmp],ylim,'--r');
		xlabel(ax,'xy drive amplitude');
		ylabel(ax,'P|1>');
        if args.AE
            legend(ax,{[sprintf('data(%d',numPi0),'\pi)'],...
                [sprintf('data(AE:%0.0f',args.AENumPi),'\pi)'],...
                sprintf('%s gate amplitude',args.gateTyp)});
        else
            legend(ax,{[sprintf('data(%d',numPi0),'\pi)'],sprintf('%s gate amplitude',args.gateTyp)});
        end
        set(ax,'YLim',ylim);
        drawnow;
	end
	if ischar(args.save)
        args.save = false;
        choice  = questdlg('Update settings?','Save options',...
                'Yes','No','No');
        if ~isempty(choice) && strcmp(choice, 'Yes')
            args.save = true;
        end
    end
    if args.save
        QS.saveSSettings({q.name,gateAmpSettingsKey},gateAmp);
    end
	end
	
	varargout{1} = gateAmp;
end

function xp = findsPkLoc(x,y)
    rng = range(y);
    [pks,locs,~,~] = findpeaks(y,'MinPeakHeight',2*rng/3,...
        'MinPeakProminence',rng/2,'MinPeakDistance',numel(x)/4,...
        'WidthReference','halfprom');
    
    if ~isempty(pks)
        [locs,idx] = sort(locs,'ascend');
        pks = pks(idx);

        maxIdx = locs(1);
        if numel(pks) > 3
            throw(MException('QOS_xyGateAmpTuner:tooManyOscCycles',...
                    'too many oscillation cycles or data SNR too low.'));
        end
        dy = pks(1)-y;
    else
        [mP,maxIdx] = max(y);
        dy = mP-y;
    end

	idx1 = find(dy(maxIdx:-1:1)>rng/3,1,'first');
	if isempty(idx1)
		idx1 = 1;
	else
		idx1 = maxIdx-idx1+1;
	end
	
	idx2 = find(dy(maxIdx:end)>rng/4,1,'first');
	if isempty(idx2)
		idx2 = numel(x);
	else
		idx2 = maxIdx+idx2-1;
    end
%	 [~, gateAmp, ~, ~] = toolbox.data_tool.fitting.gaussianFit.gaussianFit(...
%		 amps(idx1:idx2),P(idx1:idx2),maxP,amps(maxIdx),amps(idx2)-amp(idx1));

	% gateAmp = roots(polyder(polyfit(amps(idx1:idx2),P(idx1:idx2),2)));
    warning('off');
	p = polyfit(x(idx1:idx2),y(idx1:idx2),2);
    warning('on');
	if mean(abs(polyval(p,x(idx1:idx2))-y(idx1:idx2))) > range(y(idx1:idx2))/4
		throw(MException('QOS_xyGateAmpTuner:fittingFailed','fitting error too large.'));
	end
	xp = roots(polyder(p));

    if xp < x(idx1) || xp > x(idx2)
		throw(MException('QOS_xyGateAmpTuner:xyGateAmpTuner',...
				'gate amplitude probably out of range.'));
    end
end