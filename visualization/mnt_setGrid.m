function mnt= mnt_setGrid(mnt, displayMontage, varargin)
%MNT_SETGRID - Define a new eletrode grid layout for an electrode montage
%
%Synposis:
% MNT= mnt_setGrid(MNT, DISPLAYMONTAGE, <OPTS>)
%
%Input:
% MNT:            struct for electrode montage, see setElectrodeMontage
% DISPLAYMONTAGE: a template grid., 'small', 'medium', 'large',
%                 or any *.mnt file in EEG_CFG_DIR,                  
%                 or a string defining the montage (see example)
% OPTS:           struct or property/value list of optional field:
%  .CenterClab  - label of channel to be positioned at (0,0)
%
%Output:
% MNT: updated struct for electrode montage
%
%Example:
% grd= sprintf('legend,Fz,scale\n,C3,Cz,C4\nP3,Pz,P4');
% mnt= mnt_setGrid(mnt, grd);
%
% JohannesHoehne 2014 - added template mnts as hard-coded option
% 
%See also: mnt_setElectrodePositions, getGrid.


props = {'CenterClab',   'Cz',   'CHAR'};

if nargin==0,
  mnt= props; return
end
opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if ~exist('displayMontage', 'var'), displayMontage='medium'; end
if ~isstruct(mnt),
  mnt= struct('clab', {mnt});
end

switch displayMontage %catch the templates
    case 'small'
        displayMontage = sprintf([...
            'EOGh,F3,F1,Fz,F2,F4,EOGv\n' ...
            'FC5,FC3,FC1,FCz,FC2,FC4,FC6\n' ...
            'C5,C3,C1,Cz,C2,C4,C6\n' ...
            'CP5,CP3,CP1,CPz,CP2,CP4,CP6\n'...
            'T5,P3,P1,Pz,P2,P4,T6\n' ...
            'EMGl,scale,O1,Oz,O2,legend,EMGr']);
    case 'medium'
        displayMontage = sprintf(['EOGh,F5,F3,F1,Fz,F2,F4,F6,EOGv\n' ...
            'FT7,FC5,FC3,FC1,FCz,FC2,FC4,FC6,FT8\n'...
            '<,CFC7,CFC5,CFC3,CFC1,CFC2,CFC4,CFC6,CFC8\n' ...
            'T7,C5,C3,C1,Cz,C2,C4,C6,T8\n' ...
            '<,CCP7,CCP5,CCP3,CCP1,CCP2,CCP4,CCP6,CCP8\n'...
            'TP7,CP5,CP3,CP1,CPz,CP2,CP4,CP6,TP8\n'...
            'P7,P5,P3,P1,Pz,P2,P4,P6,P8\n'...
            'EMGl,scale,PO7,O1,Oz,O2,PO8,legend,EMGr']);
    case 'large'
        displayMontage = sprintf(['EOGh,Fp1,AFp1,AFz,AFp2,Fp2,EOGv\n' ...
'F9,F7,AF7,FAF5,AF3,FAF1,_\n' ...
'_,FAF2,AF4,FAF6,AF8,F8,F10\n' ...
' F5,F3,F1,Fz,F2,F4,F6\n' ...
'FT9,FFC9,FFC7,FFC5,FFC3,FFC1,_\n' ...
'_,FFC2,FFC4,FFC6,FFC8,FFC10,FT10\n' ...
'FC5,FC3,FC1,FCz,FC2,FC4,FC6\n' ...
'CFC9,FT7,CFC7,CFC5,CFC3,CFC1,legend\n' ...
'_,CFC2,CFC4,CFC6,CFC8,FT8,CFC10\n' ...
'C5,C3,C1,Cz,C2,C4,C6\n' ...
'TP9,TP7,T7,CCP7,CCP5,CCP3,CCP1\n' ...
'CCP2,CCP4,CCP6,CCP8,T8,TP8,TP10\n' ...
'CP5,CP3,CP1,CPz,CP2,CP4,CP6\n' ...
'P9,PCP9,P7,PCP7,PCP5,PCP3,PCP1\n' ...
'PCP2,PCP4,PCP6,PCP8,P8,PCP10,P10\n' ...
'P5,P3,P1,Pz,P2,P4,P6\n' ...
'PO9,PPO9,PPO5,PPO1,PPO2,PPO6,PPO10\n' ...
'PO7,PO3,OPO1,POz,OPO2,PO4,PO8\n' ...
'EMGl,O9,O1,Oz,O2,O10,EMGr']);
end

grid= mntutil_getGrid(displayMontage);
if ~any(ismember(strtok(mnt.clab), grid,'legacy')),
  return;
end

%w_cm= warning('query', 'bci:missing_channels');
%warning('off', 'bci:missing_channels');
clab= cat(2, strtok(mnt.clab), {'legend','scale'});
nChans= length(clab);
mnt.box= zeros(2, nChans);
mnt.box_sz= ones(2, nChans);
[c0,r0]= getIndices(opt.CenterClab, grid);
if isnan(c0), 
  c0=0; r0=0; 
end
for ei= 1:nChans,
  [ci,ri]= getIndices(clab{ei}, grid);
  if length(ci)>1,
    warning('channel %s appDrawEars multiple times in the grid layout', clab{ei});
  end
  if isnan(ri),
    mnt.box(:,ei)= [NaN; NaN];
  else
    if isequal(grid{ri,1},'<'),
      cc= c0+0.5;
    else
      cc= c0;
    end
    for ii= 1:length(ci),  %% loop is needed for the case that one channel appear multiple times in the grid
      mnt.box(:,ei)= [ci(ii)-cc; -(ri(ii)-r0)];
    end
  end
end
%warning(w_cm);
mnt.scale_box= mnt.box(:,end);
mnt.scale_box_sz= mnt.box_sz(:,end);
mnt.box= mnt.box(:,1:end-1);
mnt.box_sz= mnt.box_sz(:,1:end-1);



function [ci,ri]= getIndices(lab, grid)

nRows= size(grid,1);
ii= util_chanind(grid, lab);
if isempty(ii),
  ci= NaN;
  ri= NaN;
else    
  ci= 1+floor((ii-1)/nRows);
  ri= ii-(ci-1)*nRows;
end
