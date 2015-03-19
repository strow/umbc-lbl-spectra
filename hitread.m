function [line,hitran_version,hlist_qtips] = ...
            hitread(start,stop,strengthM,gasID,filename,iCO2);

%%    hlist_qtips tells you which HXX versions use the old qtips, and which
%%    use the new Lagrange stuff from the H04 database
% function line=hitreadNEW(start,stop,strengthM,gasID,filename,iCO2);
% this calls read_hitran, and adds on an extra field : LINCT which is
% the number of lines read in

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% warning .. need to agree with  %%%%
%%%%   qoldVSqnew_fast
%%%%   initializeABCDG_qtips
%%%% so do 
%%%%   grep -in 'length(intersect(hitran_version,hlist_qtips))' *.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% simple version, w/o symbolic link checking/making is hitread_no_symbolic.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% it differentiates and calls the right MEXED HITRAN readers
% >>>> when updating HITRAN versions, do a search for "UPDATE"

addpath /asl/matlib/aslutil
addpath /asl/matlib/read_hitr06/
addpath /home/sergio/SPECTRA/read_hitr06/

current_dir = pwd;

blah = findstr('/',filename);
%%look at the fourth occurence
hitran_version = filename(blah(4)+1:blah(4)+3);

% UPDATE
old_reader = {'h92','h96','h98','h2k'};
new_reader = {'h04','h08','h12'};

iOld = -1;
iNew = -1;
for ii = 1 : length(old_reader)
  if strcmp(old_reader(ii),hitran_version)
    iOld = +1;
  end
end
for ii = 1 : length(new_reader)
  if strcmp(new_reader(ii),hitran_version)
    iNew = +1;
  end
end
if iOld == -1 & iNew == -1
  error('whoops : have NOT been able to figure what HITRAN version you want!')
end

if iOld > 0
  %fprintf(1,'--> using old MEX reader for HITRAN version %s : %s\n',hitran_version,filename)
  %line = read_hitran(start,stop,strengthM,gasID,filename);
  fprintf(1,'--> using old MATLAB reader for HITRAN version %s : %s \n',hitran_version,filename)
  line = read_hitranOLD_H92_H2k(start,stop,strengthM,gasID,filename);
else
  fprintf(1,'--> using new MEX reader for HITRAN version %s : %s\n',hitran_version,filename)
  % cd /asl/matlab2012/read_hitr06
  % cd /asl/matlab/read_hitr06
  %%%% addpath /asl/matlab2012/read_hitr06
  % cd /home/sergio/SPECTRA/read_hitr06
  %%%% addpath /home/sergio/SPECTRA/read_hitr06
  line = read_hitran(start,stop,strengthM,gasID,filename);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
line.linct=length(line.wnum);

line.iso=line.iso';
line.wnum=line.wnum';
line.stren=line.stren';
line.tprob=line.tprob';

line.abroad=line.abroad';
line.sbroad=line.sbroad';

line.els=line.els';
line.abcoef=line.abcoef';
line.tsp=line.tsp';

if iOld == -1 & iNew == +1
  line.iusgq=line.iusgq';
  line.ilsgq=line.ilsgq';
end

line.gasid=line.igas';

if line.linct > 0
  line.igas=line.gasid(1);
end

cder = ['cd ' current_dir];
eval(cder)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% update the "mass.dat" symbolic link
%% make sure you point mass.dat --> massXY.dat if XY = 92,96,98,2k,04

iLinkMASS = -1;

% UPDATE
if hitran_version == 'h92'
  disp('oops : for mass.dat use H96 masses for H92');
  linker = '96';
elseif hitran_version == 'h96'
  linker = '96';
elseif hitran_version == 'h98'
  linker = '98';
elseif hitran_version == 'h2k'
  linker = '00';
  linker = '98';   %% yuk  
elseif hitran_version == 'h04'
  linker = '04';
elseif hitran_version == 'h08'
  linker = '08';
  %linker = '98';   %% yuk  
elseif hitran_version == 'h12'
  linker = '12';
end

symlinker = ['!/bin/ln -s mass' linker '.dat mass.dat']; 

ee = exist('mass.dat','file');
if ee == 0
  fprintf(1,'mass.dat DNE .. making VERS %s symbolic link! \n',linker);
  %fprintf(1,'symbolic link command : %s \n',symlinker);
  iLinkMASS = +1;  
  eval(symlinker);
else
  cd /home/sergio/SPECTRA
  randstr = [num2str(round(rand(1,1)*1e9)) '.' num2str(round(rand(1,1)*1e9))];
  frand   = ['ugh' randstr];
  frand   = mktemp('ugh');
  lser = ['!ls -lt mass.dat >& ' frand];
  eval(lser)
  fid = fopen(frand,'r');
  ugher = fscanf(fid,'%s');
  fclose(fid);
  rmer = ['!/bin/rm ' frand];
  eval(rmer);
  eee = strcmp('lrwxrwxrwx',ugher(1:10));
  if eee == 0
    error('oh oh mass.dat is NOT a symbolic link; do not want to delete it!!!')
  else
    %%check to see if the symbolic link is for the right version
    tata = findstr('->mass',ugher);
    oldvers = ugher(tata+6:tata+7);
    fff = strcmp(oldvers,linker);
    %% if fff == 1, the old version == current wanted version ==> do nothing!
    if fff == 0
      boo = ['mass' linker '.dat'];
      eex = exist(boo,'file');
      if eex ~= 2
        fprintf(1,'trying to make symbolic link to %s but file DNE \n',boo)
        error('return in hitread.m');
      else
        fprintf(1,'----> update VERS %s symbolic link for mass.dat! \n',linker)
        rmer = ['!/bin/rm mass.dat']; eval(rmer);
        eval(symlinker);
        iLinkMASS = +1;  
      end
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% update the "qtips.m" symbolic link if HITRAN versions are H92,96,98
%% if HITRAN versions is H2k, symbolically link to H98
%% else use the new f77 qtips code for H04 onwards
%% make sure you point qtips.m --> qtipsXY.dat  if XY = 92,96
%%               point qtips.m --> qtips98.dat  if XY = 98,2k
%%               point qtips.m --> qtips04.dat  if XY = 04

iLinkQTIPS = -1;  

% UPDATE
if hitran_version == 'h92'
  linker = '92';
elseif hitran_version == 'h96'
  linker = '96';
elseif hitran_version == 'h98'
  linker = '98';
elseif hitran_version == 'h2k'
  linker = '04';
  linker = '98';
  linker = '00';
elseif hitran_version == 'h04'
  linker = '04';
  %linker = '98';   %% yuk  
elseif hitran_version == 'h08'
  linker = '08';
  %linker = '98';   %% yuk  
elseif hitran_version == 'h12'
  linker = '12';
end

% UPDATE
all_hitran_versions = {'h92','h96','h98','h2k','h04','h08','h12'};

symlinker = ['!/bin/ln -s qtips' linker '.m qtips.m']; 

ee = exist('qtips.m','file');  

if (ee == 0)   %% ee == 0 ==> does not exist
  if (length(intersect(hitran_version,all_hitran_versions)) == 1)
    symlinker = ['!/bin/ln -s qtips' linker '.m qtips.m']; 
    fprintf(1,'qtips.m  DNE .. making VERS %s symbolic link! \n',linker);
    boo = ['qtips' linker '.m'];
    eex = exist(boo,'file');
    if eex ~= 2
      fprintf(1,'trying to make symbolic link to %s but file DNE \n',boo)
      error('return in hitread.m');
    else
      eval(symlinker);
      iLinkQTIPS = +1;  
    end
  end
end

%%%%%%%%%%%%%%%%%% ------------->> << ----------------------
%% the Hitran versions that can use old polynom qtips is hardcoded here
%hlist_qtips = {'h92','h96','h98','h2k','h04'};    %%these can use old qtips
% UPDATE
hlist_qtips = {'h92','h96','h98','h2k'};           %%these can use old qtips
hlist_qnew = {'h04','h08','h12'};                        %%these can use new lagrange

disp(' run8 will use old polynomial qtips for these HITRAN versions ');
for lll = 1 : length(hlist_qtips)
  fprintf(1,'  %s  ',hlist_qtips{lll})
end
fprintf(1,' \n')
disp(' run8 will use new lagrange qtips for these HITRAN versions ');
for lll = 1 : length(hlist_qnew)
  fprintf(1,'  %s  ',hlist_qnew{lll})
end
fprintf(1,' \n')
%%%%%%%%%%%%%%%%%% ------------->> << ----------------------

if (ee ~= 0) %% ee ~= 0 ==> exists; check to see if it is version we want
  if (length(intersect(hitran_version,all_hitran_versions)) == 1)
    cd /home/sergio/SPECTRA
    randstr= [num2str(round(rand(1,1)*1e9)) '.' num2str(round(rand(1,1)*1e9))];
    frand   = ['ugh' randstr];
    frand   = mktemp('ugh');
    lser = ['!ls -lt qtips.m >& ' frand];
    eval(lser)
    fid = fopen(frand,'r');
    ugher = fscanf(fid,'%s');
    fclose(fid);
    rmer = ['!/bin/rm ' frand];
    eval(rmer);
    eee = strcmp('lrwxrwxrwx',ugher(1:10));
    if eee == 0
      error('oops qtips.m is NOT a symbolic link; do not want to delete it!!!')
    else
      %%check to see if the symbolic link is for the right version
      tata = findstr('->qtips',ugher);
      oldvers = ugher(tata+7:tata+8);
      fff = strcmp(oldvers,linker);
      %% if fff == 1, the old version == current wanted version ==> do nothing!
      if fff == 0
        %% symbolic link is to a different version than current wanted version
        fprintf(1,'----> update VERS %s symbolic link for qtips.m ! \n',linker)
        rmer = ['!/bin/rm qtips.m']; eval(rmer);
        %fprintf(1,'symbolic link command : %s \n',symlinker);
        eval(symlinker);
        iLinkQTIPS = +1;  
      end
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% UPDATE
if (iLinkQTIPS == 1 | iLinkMASS == 1) & (iCO2 > 0)
  if strcmp('h92',hitran_version) 
    HITdir = 'H98/';
  elseif strcmp('h96',hitran_version) 
    HITdir = 'H98/';
  elseif strcmp('h98',hitran_version) 
    HITdir = 'H98/';
  elseif strcmp('h2k',hitran_version) 
    HITdir = 'H2K/';
  elseif strcmp('h04',hitran_version) 
    HITdir = 'H04/';
  elseif strcmp('h08',hitran_version) 
    HITdir = 'H08/';
  elseif strcmp('h12',hitran_version) 
    HITdir = 'H12/';
  else
    error('sorry .. could not figure out which dir to link CO2_FILES');
  end

  % may as well update the symlinks for CO2_MATFILES
  disp('----> updating CO2_MATFILES symbolic links')
  CO2matfilesdir0 = pwd; 
  CO2matfilesdir = pwd; 
  CO2matfilesdir = [CO2matfilesdir '/CO2_MATFILES/'];
  tempFname = [CO2matfilesdir 'link_hitco2.txt'];
  glist = textread(tempFname,'%s','delimiter','\n','whitespace','');
  cder = ['cd ' CO2matfilesdir]; eval(cder);
  for ii = 1 : length(glist)
    rmer = ['!/bin/rm ' glist{ii}];
    lner = ['!ln -s   ' HITdir glist{ii}  ' ' glist{ii}];
    eval(rmer);
    eval(lner);
  end
  cder = ['cd ' CO2matfilesdir0]; eval(cder);
end

cder = ['cd ' current_dir]; eval(cder);
