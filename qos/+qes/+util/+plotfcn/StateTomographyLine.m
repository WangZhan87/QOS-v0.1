function StateTomographyLine(P,Title)
    % plots state density matrix
    
% Copyright 2017 Yulin Wu, USTC
% mail4ywu@gmail.com/mail4ywu@icloud.com

    if nargin < 2
        Title = '';
    end

    h = qes.ui.qosFigure('State Tomography',false);
    ax = axes('parent',h);
    
    numQs = round(log(size(P,1))/log(3));
    
    switch numQs
        case 1
            plot(ax, P(:,1),'-sk','LineWidth',1);
            hold(ax,'on');
            plot(ax, P(:,2),'-sb','LineWidth',1);
            hold(ax,'off');
            set(ax,'YLim',[-0.02,1.02],'YTick',[0,0.25,0.5,0.75,1],...
                'XTick',[1,2,3],'XTickLabel',...
                {'X','Y','Z'});
            grid(ax,'on');
            legend(ax,{'P|0>','P|1>'});
            ylabel('P');
            title(Title);
        case 2
            plot(ax, P(:,1),'-sk','LineWidth',1);
            hold(ax,'on');
            plot(ax, P(:,2),'-sb','LineWidth',1);
            plot(ax, P(:,3),'-sg','LineWidth',1);
            plot(ax, P(:,4),'-sr','LineWidth',1);
            hold(ax,'off');
            set(ax,'YLim',[-0.02,1.02],'YTick',[0,0.25,0.5,0.75,1],...
                'XTick',1:9,'XTickLabel',...
                {'q2_Xq1_X','q2_Xq1_Y','q2_Xq1_Z','q2_Yq1_X','q2_Yq1_Y','q2_Yq1_Z','q2_Zq1_X','q2_Zq1_Y','q2_Zq1_Z'});
            grid(ax,'on');
            grid(ax,'on');
            % legend(ax,{'P|q2_0q1_0>','P|q2_0q1_1>','P|q2_1q1_0>','P|q2_1q1_1>'});
            legend(ax,{'P|0_{q2}0_{q1}>','P|0_{q2}1_{q1}>','P|1_{q2}0_{q1}>','P|1_{q2}1_{q1}>'});
            ylabel('P');
            title(Title);
        otherwise
            error('more than 2 qubits tomography data not supported.');
    end
    
end