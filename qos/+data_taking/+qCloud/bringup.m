gui = true;
save = true;
iq2ProbNumSamples = 2e4;
correctf01DelayTime = 1e-6;
AENumPi = 21;
gAmpTuneRange = 0.03;

qubitGroups = {{'q1','q4','q7','q10'},...
               {'q2','q5','q8','q11'},...
               {'q3','q6','q9'}};

setQSettings('r_avg',2000);
%% single qubit gates
for ii = 1:numel(qubitGroups)
    tuneup.iq2prob_01_parallel('qubits',qubitGroups{ii},'numSamples',iq2ProbNumSamples,'gui',gui,'save',save);
    tuneup.correctf01byPhase('qubits',qubitGroups{ii},'delayTime',correctf01DelayTime,'gui',gui,'save',save);
    tuneup.xyGateAmpTuner_parallel('qubits',qubitGroups{ii},'gateTyp','X/2','AENumPi',AENumPi,'tuneRange',gAmpTuneRange,'gui',gui,'save',save);
end

%%
czQSets = {{{'q1','q2'};{'q1','q4','q10'};{'q2','q5','q8','q11'};{'q6'}},...
           {{'q3','q2'};{'q4','q10'};{'q2','q5','q8','q11'};{'q3','q6'}},...
           {{'q3','q4'};{'q4','q10'};{'q2','q5','q8','q11'};{'q3','q6'}},...
           {{'q5','q4'};{'q4','q10'};{'q2','q5','q8','q11'};{'q6'}},...
           {{'q5','q6'};{'q4','q10'};{'q2','q5','q8','q11'};{'q6'}},...
           {{'q7','q6'};{'q4','q7','q10'};{'q2','q5','q8','q11'};{'q6'}},...
           {{'q7','q8'};{'q4','q7','q10'};{'q2','q5','q8','q11'};{'q6'}},...
           {{'q9','q8'};{'q4','q10'};{'q2','q5','q8','q11'};{'q6','q9'}},...
           {{'q9','q10'};{'q4','q10'};{'q2','q5','q8','q11'};{'q6','q9'}},...
           {{'q11','q10'};{'q4','q10'};{'q2','q5','q8','q11'};{'q6'}},...
          };
numCZs = [10,10,10,10,10,10,10,10,10,10,10];
PhaseTolerance = 0.03;
      
for ii = 1:numel(czQSets)
    for jj = 2:numel(czQSets{ii})
        tuneup.czDynamicPhase_parallel('controlQ',czQSets{ii}{1}(1),'targetQ',czQSets{ii}{1}(2),'dynamicPhaseQs',czQSets{ii}{jj},...
            'numCZs',numCZs,'PhaseTolerance',PhaseTolerance,...
            'gui',gui,'save',save);
    end
end