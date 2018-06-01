%% JPA bringup
import data_taking.public.jpa.*
%%
jpaBringupADDA('jpa','impa1',...
    'signalAmp',[3.5e3],'signalFreq',[6.4e9:40e6:7.1e9],...
    'signalPower',22,'signalSbFreq',300e6,'signalFc',[],...
    'signalLn',6000,'rAvg',700,...
    'biasAmp',[0],'pumpAmp',[logspace(log10(1000),log10(30000),15)],...
    'pumpFreq',[2*6.73563e+09],'pumpPower',[17.8],... // 6.73563e+09 = (freq_q6 + freq_q7)/2
    'notes','','gui',true,'save',true);
%%
data=jpaBringupNA('jpaName','impa1',...
    'startFreq',6.4e9,'stopFreq',7.2e9,...
    'numFreqPts',201,'avgcounts',10,...
    'NAPower',-20,'bandwidth',3e3,...
    'pumpFreq',[2*6.82e9],'pumpPower',[0:0.20:10],...
    'bias',[180e-6],...
    'notes','','gui',true,'save',true);
%%
amplification('jpa','impa1',...
    'startFreq',6.4e9,'stopFreq',7.2e9,...
    'numFreqPts',301,'avgcounts',10,...
    'NAPower',-20,'bandwidth',3e3,...
    'pumpFreq',[2*6.823e9],'pumpPower',[4.4],...
    'biasAmp',[120:0.5:150]*1e-6,...
    'notes','','gui',true,'save',true);
%%
delt=1.0;
if exist('Data','var') && numel(Data)==1 % Analyse loaded data
    Data = Data{1,1};
    bias = SweepVals{1,1}{1,1};
    freqs = Data{1,1}(2,:);
else % Analyse fresh data
    Data = data.data{1};
    bias = data.sweepvals{1,1}{1,1};
    freqs = Data{1,1}(2,:);
end
meshdata=NaN(numel(bias),numel(freqs));
for II=1:numel(bias)
    meshdata(II,:)=Data{II,1}(1,:);
end
ANG=unwrap(angle(meshdata'));
figure(11);imagesc(bias,freqs,abs(meshdata'));  set(gca,'ydir','normal');xlabel('JPA bias');ylabel('Freq'); title('|S21|')
slop=(mean(ANG(end,:))-mean(ANG(1,:)))/(freqs(end)-freqs(1))*delt;
slops=meshgrid(slop*(freqs-freqs(1)),ones(1,numel(bias)))';
ANGS=mod(ANG-slops-(ANG(1,end))+pi,2*pi);
figure(12);imagesc(bias,freqs,ANGS);  set(gca,'ydir','normal');xlabel('JPA bias');ylabel('Freq');colorbar;title('unwraped phase')
%%
data=data_taking.public.jpa.s21_BiasPwrpPwrs_networkAnalyzer('jpaName','impa1',...
    'startFreq',4e9,'stopFreq',8e9,...
    'numFreqPts',4001,'avgcounts',1,...
    'NAPower',-20,'bandwidth',10e3,...
    'pumpFreq',14e9,'pumpPower',-30:0.5:10,...
    'bias',0,...
    'notes','Check JPA alive','gui',true,'save',true);