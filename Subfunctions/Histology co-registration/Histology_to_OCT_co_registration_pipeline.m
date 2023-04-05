%% Histology to OCT co-registration
    %% File loading
        FilesDirectory='F:\LSPN and DSWC paper up to Feb 28 2023\Histology mice 1122H1M5 and H1M7'%'C:\Users\nader\Downloads\D\Histology mice 1122H1M5 and H1M7'%'C:\Users\nader\Downloads\Histology mice 1122H1M5 and H1M7'
        cd(FilesDirectory)
        Hist_Img_Filenames={'Crop1_H1M5 HE.tif' 'Crop1_H1M5 Lyve1.tif'}%{'Crop1_H1M5 HE.tif' 'Crop1_H1M5 Lyve1.tif' 'Crop2_H1M5 HE.tif' 'Crop2_H1M5 Lyve1.tif'}%{'H1M5 HE.svs','H1M5 Lyve1.svs'}
        Hist_Img={};
        NumImages=length(Hist_Img_Filenames);
        CropNumsTemp1=strsplit(strjoin([Hist_Img_Filenames],' '),'Crop')
%         CropNumsTemp2=strsplit(strjoin([CropNumsTemp1],' '),'_')
%         CropNumsTemp3=strsplit(CropNumsTemp2,' ')
        for a=2:length(CropNumsTemp1)
            CropNums(a-1)=str2double(CropNumsTemp1{a}(1))
        end
        
        for Image=1:2%1:NumImages
            Hist_Img{Image}=imread(fullfile(FilesDirectory,Hist_Img_Filenames{Image}));
%             [Hist_Img{Image},Hist_ImgMap{Image}]=rgb2ind(imread(fullfile(FilesDirectory,Hist_Img_Filenames{Image})));
%             Hist_Img{Image}=ind2gray(Hist_Img{Image})
        end
%         %% Cropping out individual tissue sections from 3 sections on same slide
%         figure, imagesc(Hist_Img{1})
%         %use crop tool and save manually
% %NEVERmind, after cropping hard to save as svs I think and manage that many-
% %files --did in ImageJ
%% 1) Multiple histology sections co-registration
    %% Co-registration
        Transformations=cell(NumImages,1)
%         Hist_Img_reg{1}=Hist_Img{1};%FixedRef=Hist_Img{1};
%         Transformations=cells(NumImages,1);
        %Skip=0
        Hist_Img_reg=cell(NumImages,1);%im2gray(Hist_Img);
        SatisfiedCoreg{1}=0;
        Hist_Img_reg{1}=Hist_Img{1};%rgb2gray(Hist_Img{1});
        ind=2;%starting from second histology image
        a=2; %section looked at in scan
        while ind<=NumImages
            Hist_Img_reg{ind}=Hist_Img{ind};%rgb2gray(Hist_Img{ind});
            while SatisfiedCoreg{1}==0 || isempty(SatisfiedCoreg{1})
            SatisfiedCoreg{1}=[]; %Whether co-registration good enough
            %MovingTemp=Hist_Img{ind};
            if ~exist(fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_HistMovingpoints.mat']))
                [mp,fp] = cpselect(Hist_Img{ind},Hist_Img_reg{1},Wait=true);
                if ~isempty(mp)
                    save(fullfile(FilesDirectory,['Crop'  char(num2str(CropNums(a))) '_HistMovingpoints.mat']),'mp','-v7.3')
                    save(fullfile(FilesDirectory,['Crop'  char(num2str(CropNums(a))) '_HistFixedpoints.mat']),'fp','-v7.3')
                end
            else
                load(fullfile(FilesDirectory,['Crop'  char(num2str(CropNums(a))) '_HistMovingpoints.mat']))
                load(fullfile(FilesDirectory,['Crop'  char(num2str(CropNums(a))) '_HistFixedpoints.mat']))
            end

            Transformations{ind} = fitgeotrans(mp,fp,"lwm",12);%"pwl")%"affine");
%             Transformations{ind} = images.geotrans.PiecewiseLinearTransformation2D(mp,fp)

            CoordinateSystemFixed = imref2d(size(Hist_Img{1}));
            Hist_Img_reg{ind}= imwarp(Hist_Img{ind},Transformations{ind},OutputView=CoordinateSystemFixed);
%             [Hist_Img_reg{ind},Transformations{ind}]=imregister(rgb2gray(Hist_Img{ind}),Hist_Img_reg{1},"pwl")%"affine")
            %Transformations{ind}=
            close gcf
            figure, imshowpair(Hist_Img_reg{1},Hist_Img_reg{ind}) %visualization
                while isempty(SatisfiedCoreg{1}) % Asking user if satisfied with visualization
                    opts.WindowStyle = 'normal';
                    SatisfiedCoreg= {str2double(inputdlg('Alignment okay? Yes=1, No=0 (default is yes)\n','Satisfactory?',1,{''},opts))};%,1)
                        if isempty(SatisfiedCoreg{1}) || isnan(SatisfiedCoreg{1})
                            SatisfiedCoreg{1}=1;
                        elseif SatisfiedCoreg{1}~=1 && SatisfiedCoreg{1}~=0
                            SatisfiedCoreg{1}=[];
                        end
                end
                if SatisfiedCoreg==1
                    CoregisteredHistology=Hist_Img_reg{ind};
                    save(fullfile(FilesDirectory,['registered_' Hist_Img_Filenames{ind}]),'CoregisteredHistology');
%imwrite(Hist_Img_reg{ind},fullfile(FilesDirectory,['registered_' Hist_Img_Filenames{ind} '.svs']));
                    ind=ind+1;
                end
            close gcf
            end
        end
%% 2) OCT B-scan identification ex-vivo
    clearvars Hist_Img
        OCT_ExVivoFilepath_Mark=fullfile(FilesDirectory,'1122H1M5_bareskin\Ex-vivo','st3D_H1M5_exVivo_Mark.mat')
        addpath(genpath(fileparts(OCT_ExVivoFilepath_Mark)))
        OCT_ExVivo_Mark=matfile(OCT_ExVivoFilepath_Mark)
        OCT_ExVivoFileInfo_Mark=whos('-file', OCT_ExVivoFilepath_Mark)%OCT_ExVivo)
        
%         OCT_ExVivoFilepath_NoMark=fullfile(FilesDirectory,'1122H1M5_bareskin\Ex-vivo','st3D_H1M5_exVivo_NoMark.mat')
%         addpath(genpath(fileparts(OCT_ExVivoFilepath_NoMark)))
%         OCT_ExVivo_NoMark=matfile(OCT_ExVivoFilepath_NoMark)
%         OCT_ExVivoFileInfo=whos('-file', OCT_ExVivoFilepath_NoMark)%OCT_ExVivo)

       %% Defining dimensions and visualization of pre-removal B-scan identifier (fiducial tool VI)
        BscanWidthx=1152;
        NumBscans=2400;
        %figure, imshow3D(OCT_ExVivo_Mark.(x.name))
        EnFaceIVmarker=squeeze(sum(OCT_ExVivo_Mark.(OCT_ExVivoFileInfo_Mark.name),1));
        figure, imagesc(EnFaceIVmarker)
        colormap 'gray'
        Starting_B_scan=0;%Based on top view -- I am calling first B-scan 0
        mmPerpixY=9/NumBscans;
        mmPerpixX=9/BscanWidthx;
        %% Defining B-scan positions identifier manually based on acquisition
            %Making the IV-mark trace
        h(1)=drawpolyline( 'InteractionsAllowed','all')%Top of top line
        h(2)=drawpolyline( 'InteractionsAllowed','all')%Bottom of top line
        h(3)=drawpolyline( 'InteractionsAllowed','all')%Top of mid line
        h(4)=drawpolyline( 'InteractionsAllowed','all')%Bottom of mid line
        h(5)=drawpolyline( 'InteractionsAllowed','all')%Top of bottomline
        h(6)=drawpolyline( 'InteractionsAllowed','all')%Bottom of bottom line
        %Vertical is x
        %Horizontal is y
        %% Digitizing trace of VI B-scan positions identifier
        for line=1:2:5 %COMPARING LINES IN PAIRS
            minY(line)=ceil(min([h(line).Position(1,1),h(line+1).Position(1,1)],[],'all')); %limiting to min of considered part of VI
                minY(line+1)=minY(line);
            maxY(line)=floor(max([h(line).Position(end,1),h(line+1).Position(end,1)],[],'all')); %limiting to max of considered part of VI
                maxY(line+1)=maxY(line);
        end
        for line=1:6
            for indx=1:(size(h(line).Position,1)-1)%for all points drawn for the given line          
                slope(indx)=(h(line).Position(indx+1,2)-h(line).Position(indx,2))/(h(line).Position(indx+1,1)-h(line).Position(indx,1));%for interpolating lines
                InterceptXTransAxis(indx)=h(line).Position(indx,2)-slope(indx)*h(line).Position(indx,1);
                %Will not extrapolate lines beyond confines of where they
                %are actually traced as VI marks on histology do not
                %necessarily extend either
                if indx==1%
                    rangey=minY(line):ceil(h(line).Position(indx+1,1));%1:floor(h(line).Position(indx+1,1)); %everywhere below minY will be assigned a value of 0 by default in the matrix
                elseif indx==(size(h(line).Position,1)-1)%final point
                    rangey=ceil(h(line).Position(indx,1)):maxY(line);%ceil(h(line).Position(indx,1)):size(tempst,2);
                else%in between if 4 or more vertices
                    rangey=(ceil(h(line).Position(indx,1))+1):ceil(h(line).Position(indx+1,1));%floor(h(line).Position(indx,1)):ceil(h(line).Position(indx+1,1));
                end
                xUpDownPosition(line,rangey)=slope(indx)*[rangey]+InterceptXTransAxis(indx);
                %xUpDownPosition(line,(rangey(end):maxY))=0;
            end
        end
            % Defining IV mark lines
            TopMidLine=[mean([xUpDownPosition(1,:);xUpDownPosition(2,:)],1)';zeros(NumBscans-max(maxY)-1,1)];
                ThicknessTopLine_mm=mmPerpixX*[diff([xUpDownPosition(1,:);xUpDownPosition(2,:)],1)';zeros(NumBscans-max(maxY)-1,1)];%Should be roughly 500um
            MidMidLine=[mean([xUpDownPosition(3,:);xUpDownPosition(4,:)],1)';zeros(NumBscans-max(maxY)-1,1)];
                ThicknessMidLine_mm=mmPerpixX*[diff([xUpDownPosition(3,:);xUpDownPosition(4,:)],1)';zeros(NumBscans-max(maxY)-1,1)];%Should be roughly 500um
            BotMidLine=[mean([xUpDownPosition(5,:);xUpDownPosition(6,:)],1)';zeros(NumBscans-max(maxY)-1,1)];
                ThicknessBotLine_mm=mmPerpixX*[diff([xUpDownPosition(5,:);xUpDownPosition(6,:)],1)';zeros(NumBscans-max(maxY)-1,1)];%Should be roughly 500um                
        for BscanPos=1:NumBscans
%             if BscanPos==325
%                 pause on
%                 pause()
%                 1
%             end
            if TopMidLine(BscanPos)~=0 && MidMidLine(BscanPos)~=0 && BotMidLine(BscanPos)~=0 %points beyond the VI markinh
                OCT_PointsSeparationBasedOnMidLines_mm(BscanPos,1:2)=mmPerpixX*[MidMidLine(BscanPos)-TopMidLine(BscanPos),BotMidLine(BscanPos)-MidMidLine(BscanPos)];
            else
                OCT_PointsSeparationBasedOnMidLines_mm(BscanPos,1:2)=NaN;
            end
        end
                %OCT_PointsSeparationBasedOnMidLines_mm=mmPerpixX*[TopMidLine'-MidMidLine',MidMidLine'-BotMidLine'];
        OCT_PointsSeparationBasedOnThicknessLines_mm=OCT_PointsSeparationBasedOnMidLines_mm-(1/2)*[ThicknessTopLine_mm+ThicknessMidLine_mm,ThicknessMidLine_mm+ThicknessBotLine_mm];
        OCT_PointsSeparationBasedOnPartialThicknessLines_mm=OCT_PointsSeparationBasedOnMidLines_mm-(2/3)*[ThicknessTopLine_mm+ThicknessMidLine_mm,ThicknessMidLine_mm+ThicknessBotLine_mm];
        OCT_PointsSeparationBasedOnMidLines_mm(OCT_PointsSeparationBasedOnMidLines_mm<0)=0;
        OCT_PointsSeparationBasedOnThicknessLines_mm(OCT_PointsSeparationBasedOnThicknessLines_mm<0)=0;
        OCT_PointsSeparationBasedOnPartialThicknessLines_mm(OCT_PointsSeparationBasedOnPartialThicknessLines_mm<0)=0;
        %OCT_PointsSeparation_mm(OCT_PointsSeparation_mm<0)=0;
        %% Defining B-scan positions identifier automatically based on design 
        RangeY=Starting_B_scan:(NumBscans-1);%Based on image
            xDotposition_perBscan_mm(:,1)=tand(0)*RangeY*mmPerpixY;
            SlopeMet1_conversion= tand(18)*mmPerpixY;
            SlopeMet2_conversion=3.296/NumBscans;%*9/NumBscans
            xDotposition_perBscan_mm(:,2)=mean([SlopeMet1_conversion,SlopeMet2_conversion])*RangeY;%tand(18)*RangeY*mmPerpixY;%3.296/NumBscans*RangeY;%cotd(18)*(1*RangeY-0.092);
            xDotposition_perBscan_mm(:,3)=mean([SlopeMet1_conversion,SlopeMet2_conversion])*(-RangeY+2*2400);%tand(18)*mmPerpixY*(-RangeY+2*2400);%3.296/NumBscans*(-RangeY+2*NumBscans);%-cotd(18)*(1*RangeY-6.399);
        OCT_PointsSeparation_mm=[((xDotposition_perBscan_mm(:,2)-0.25)-(xDotposition_perBscan_mm(:,1)+0.25)) , ((xDotposition_perBscan_mm(:,3)-0.25)-(xDotposition_perBscan_mm(:,2)+0.25))];%accounting for width of lines%[abs((xDotposition_perBscan_mm(:,1)+0.25)-(xDotposition_perBscan_mm(:,2)-0.25)) , abs((xDotposition_perBscan_mm(:,2)+0.25)-(xDotposition_perBscan_mm(:,3)-0.25))];%accounting for width of lines
        OCT_PointsSeparation_mm(OCT_PointsSeparation_mm<0)=0;
        %% Visualization
        figure, imagesc(EnFaceIVmarker)
        colormap 'gray', hold on
        plot(1:2400,TopMidLine,'r',1:2400,MidMidLine,'r',1:2400,BotMidLine,'r')
    %% Calculating ,B-scan identifier from histology
%         Hist_Img_regBinary=Hist_Img_reg{1};
        Hist_PointsSeparationStraight_mm=[2.205 , 1.704];
        Hist_PointsSeparationFlattened_mm= [2.3126+2*0.03077 , 1.6617];
    %% Identifying and extracting corresponding B-scan from OCT
        OCT_PointsSeparation_mm=OCT_PointsSeparationBasedOnPartialThicknessLines_mm;%OCT_PointsSeparationBasedOnMidLines_mm;%OCT_PointsSeparationBasedOnThicknessLines_mm;;%OCT_PointsSeparationBasedOnPartialThicknessLines_mm
        for BscanNum=1:NumBscans %finding closest corresponding 
            DifferenceStraightLR(BscanNum,:)=abs(Hist_PointsSeparationStraight_mm-OCT_PointsSeparation_mm(BscanNum,:));
            DifferenceFlattenedLR(BscanNum,:)=abs(Hist_PointsSeparationFlattened_mm-OCT_PointsSeparation_mm(BscanNum,:));
            DifferenceStraightRL(BscanNum,:)=abs(fliplr(Hist_PointsSeparationStraight_mm)-OCT_PointsSeparation_mm(BscanNum,:));
            DifferenceFlattenedRL(BscanNum,:)=abs(fliplr(Hist_PointsSeparationFlattened_mm)-OCT_PointsSeparation_mm(BscanNum,:));
        end
            ClosestBscanStraightLR_Sum =min(find(sum(DifferenceStraightLR,2)==min(sum(DifferenceStraightLR,2))));
            ClosestBscanFlattenedLR_Sum =min(find(sum(DifferenceFlattenedLR,2)==min(sum(DifferenceFlattenedLR,2))));
                ClosestBscanStraightLR_1 =min(find(DifferenceStraightLR==min(DifferenceStraightLR(:,1))));
                ClosestBscanFlattenedLR_1 =min(find(DifferenceFlattenedLR==min(DifferenceFlattenedLR(:,1))));
                ClosestBscanStraightLR_2 =min(floor(find(DifferenceStraightLR==min(DifferenceStraightLR(:,2)))/2));
                ClosestBscanFlattenedLR_2 =min(floor(find(DifferenceFlattenedLR==min(DifferenceFlattenedLR(:,2)))/2));
            ClosestBscanStraightRL_Sum =min(find(sum(DifferenceStraightRL,2)==min(sum(DifferenceStraightRL,2))));
            ClosestBscanFlattenedRL_Sum =min(find(sum(DifferenceFlattenedRL,2)==min(sum(DifferenceFlattenedRL,2))));
                ClosestBscanStraightRL_1 =min(find(DifferenceStraightRL==min(DifferenceStraightRL(:,1))));%counting is linear
                %a=[2 4 6 8 7 5]b=[ 6 4 3 4 5 5]
                % c=[a' b']
                % find(c==max(c))
                % find(c==max(c(:,1)))
                % find(c==max(c(:,2)))
                % c==max(c(:,1))
                % find(ans)
                % c==min(c(:,2))
                % find(c==min(c(:,2)))

                ClosestBscanFlattenedRL_1 =min(find(DifferenceFlattenedRL==min(DifferenceFlattenedRL(:,1))));
                ClosestBscanStraightRL_2 =min(floor(find(DifferenceStraightRL==min(DifferenceStraightRL(:,2)))/2));
                ClosestBscanFlattenedRL_2 =min(floor(find(DifferenceFlattenedRL==min(DifferenceFlattenedRL(:,2)))/2));
OCTAndHist_BscanNum=table(ClosestBscanStraightLR_Sum, ClosestBscanFlattenedLR_Sum, ClosestBscanStraightRL_Sum, ClosestBscanFlattenedRL_Sum, ClosestBscanStraightLR_1 , ClosestBscanStraightLR_2 , ClosestBscanStraightRL_1 , ClosestBscanStraightRL_2 , ClosestBscanFlattenedLR_1 , ClosestBscanFlattenedLR_2 , ClosestBscanFlattenedRL_1 , ClosestBscanFlattenedRL_2 )
%writetable(OCTAndHist_BscanNum,['Crop' char(num2str(CropNums(1))) '_OCTAndHist_BscanNum2_PartThick.xlsx'])
Closeness=[min(sum(DifferenceStraightLR,2)),min(sum(DifferenceFlattenedLR,2)),min(sum(DifferenceStraightRL,2)),min(sum(DifferenceFlattenedRL,2))];
ClosestBscan=OCTAndHist_BscanNum(1,Closeness==min(Closeness)).(1)
% Straight- Distance between points on histology sections taken as straight lines not accounting for bends and distortions
% Flattened- Distance between points on histology sections taken as straight lines accounting for bends and distortions
% LR assuming the histology points are oriented Left to right (parallel to  B-scan) --in the future this can be addressed via different colour marking according to the side
% RL assuming the histology points are oriented right to Left (anti-parallel to B-scan)
% _1 minimizing difference between histology set of points and B-scan VI marker set of points based on left-most measurement
% _2 minimizing difference between histology set of points and B-scan VI marker set of points based on right-most measurement

% ClosenessOrder=sort(Closeness)
%CHierarchyOfGuesses=table(Closeness,'VariableNames',{'ClosestBscanStraightLR_Sum', 'ClosestBscanFlattenedLR_Sum', 'ClosestBscanStraightRL_Sum', 'ClosestBscanFlattenedRL_Sum'})
%%Detect inflection point?
%         %%
%         save(fullfile(FilesDirectory,'OCTHistClosestBscanStraight.mat'),'ClosestBscanStraight','-v7.3')
%         save(fullfile(FilesDirectory,'OCTHistClosestBscanFlattened.mat'),'ClosestBscanFlattened','-v7.3')    
%             
%% 3) OCT B-scan rigid transform co-registration to histology
BscanExVivo= OCT_ExVivo_Mark.(OCT_ExVivoFileInfo_Mark.name)(:,:,ClosestBscan);%removeOversaturation4(OCT_ExVivo_Mark.(x.name)(:,:,ClosestBscan),0.3);
CODE_Coreg='Hist-ExVivoBscan';
DirectoryCoregistrationData=fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_' CODE_Coreg]);
% ImageFixed=BscanExVivo
% ImageToBeCoregistered=Hist_Img_reg{1};
if exist(fullfile(DirectoryCoregistrationData,sprintf('registered_%s.mat',CODE_Coreg)))
    PreviouslyAlignedFound=1;
else
    PreviouslyAlignedFound=0;
end

TryAutomatic=0;

[transform2D_CoregHistExvivoBscan,RfixedExvivoBscan,~]=CoReg_Modalities(CODE_Coreg,DirectoryCoregistrationData,BscanExVivo,Hist_Img_reg{1},TryAutomatic,PreviouslyAlignedFound,0,[]);%7,12);
% clearvars SatisfiedCoreg    
% 
% SatisfiedCoreg{1}=0;
%     while SatisfiedCoreg{1}==0 || isempty(SatisfiedCoreg{1})
%             SatisfiedCoreg{1}=[] %Whether co-registration good enough
%             %MovingTemp=Hist_Img{ind};
%             if ~exist(fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_ExVivoBscanMovingpoints.mat']))
%                 [mp,fp] = cpselect(BscanExVivo,Hist_Img_reg{1},Wait=true);
%                 if ~isempty(mp)
%                     save(fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_ExVivoBscanMovingpoints.mat']),'mp','-v7.3')
%                     save(fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_ExVivoBscanFixedpoints.mat']),'fp','-v7.3')
%                 end
%             else
%                 load(fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_ExVivoBscanMovingpoints.mat']))
%                 load(fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_ExVivoBscanFixedpoints.mat']))
%             end

%             Transformations=fitgeotrans(mp,fp,"similarity");%Rigid transform + scaling
%             CoordinateSystemFixed = imref2d(size(Hist_Img_reg{1}));
%             ExVivoBscan_reg= imwarp(BscanExVivo,Transformations,OutputView=CoordinateSystemFixed);
% %             [Hist_Img_reg{ind},Transformations{ind}]=imregister(rgb2gray(Hist_Img{ind}),Hist_Img_reg{1},"affine")
%             %Transformations{ind}=
%             close gcf
%             figure, imshowpair(ExVivoBscan_reg,Hist_Img_reg{1}) %visualization
%                 while isempty(SatisfiedCoreg{1}) % Asking user if satisfied with visualization
%                     SatisfiedCoreg= str2double(inputdlg('Alignment okay? Yes=1, No=0 (default is yes)\n','Satisfactory?'));%,1)
%                         if isempty(SatisfiedCoreg{1})
%                             SatisfiedCoreg{1}=1;
%                         elseif SatisfiedCoreg{1}~=1||SatisfiedCoreg{1}~=0
%                             SatisfiedCoreg{1}=[];
%                         end
%                 end
%                 if SatisfiedCoreg{1}==1
%                     save(fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_registered_OCTExVivo.mat']),"ExVivoBscan_reg");
%                     ind=ind+1;
%                 end
%     end
%% 3) OCT B-scan identification in-vivo + affine transform co-registration to ex-vivo OCT 
OCT_InVivoFilepath=fullfile(FilesDirectory,'1122H1M5_bareskin\January 6, 2023','st3D_H1M5_InVivo.mat')
        OCT_InVivo=matfile(OCT_InVivoFilepath)
        addpath(genpath(fileparts(OCT_InVivoFilepath)));
        OCT_InVivoFileInfo=whos('-file', OCT_InVivoFilepath)% must be in directory

% InVivo3D= OCT_inVivo.(x.name);%(:,:,ClosestBscan);%Straight
CODE_Coreg='ExVivoBscan-InVivoBscan';
DirectoryCoregistrationData=fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_' CODE_Coreg]);
% ImageFixed=BscanInVivo
% ImageToBeCoregistered=BscanExVivo;
% if exist(fullfile(DirectoryCoregistrationData,sprintf('registered_%s.mat',CODE_Coreg)))
%     PreviouslyAlignedFound=1;
% else
%     PreviouslyAlignedFound=0;
% end
% Co-registration not based on control points, rather simply rotation and
% translation (similarity transform) to remove window
num_contoured_slices=2;
ScanNames={'Ex-vivo';'In-vivo'};
Matfiles={OCT_ExVivo_Mark,OCT_InVivo};
Filepaths={OCT_ExVivoFilepath_Mark,OCT_InVivoFilepath};
VarNames={OCT_ExVivoFileInfo_Mark.name,OCT_InVivoFileInfo.name};

AutoProcess=1;%If files from previous attempts exist it will use them
autoLineDector=0;%Try automatic line detector
OSremoval=0.00;
        % Physical to pix conversions
            umPerPix_For200PixDepthInAir=10.8336;%empirically determined through measurements of borosillicate glass of known dimensions and refractive index at 1320nm, 1.503            
            umPerPix_For200PixDepthInTissue=7.738282833;
            GlassThickness_200PixDepth=80*2/5;%empirically determined average glass thickness is 18 when the volume on our nrcOCT is rescaled to 200pixels in depth
            ReferencePixDepth=200;%observation above based on 200 pix depth rescaling, do not change
            DataCroppedNotResizedInDepth=1;%%If not resized no difference in pixel scale from original at 500pixels
for ind=2:2
    %% Window delineation for window mask definition
    mask_3DWindow=WindowRemoverOCT_Coreg_Ex_vivo__In_vivo(Matfiles{ind},VarNames{ind},num_contoured_slices,ScanNames{ind},DirectoryCoregistrationData,AutoProcess,autoLineDector,OSremoval,GlassThickness_200PixDepth,DataCroppedNotResizedInDepth,ReferencePixDepth);%,umPerPix_For200PixDepth);%             [mask_3D_NoGlass_NotCoreg]= ContouringFunctionFilesLoadedOrMatFile7_batchProc(num_contoured_slices_Top,[MouseName,' ',Timepoint],stOCTLateralCoregistered,vessels_processed_binaryLateralCoregistered,DimsVesselsRaw3D, fullfile(GlassRemovalDraft,'zline_GlassTop.mat'),fullfile(GlassRemovalDraft,'zline_GlassBot.mat'),fullfile(saveFolder,'mask_3D_YesGlassUnrotated.mat'),fullfile(saveFolder,'mask_3D_NoGlassUnrotated.mat'),saveFolder,GlassRemovalDraft,AutoProcess,OSremoval);
    %% Applying window mask to remove window
    StOCT_RotatedShifted=Matfiles{ind}.(VarNames{ind});
        %try tall matrices for efficiency or doing struct on its own save then offload memory, etc.
            %mask_3D_NoGlass=imresize3(mask_3D_NoGlass,DimsVesselsRaw3D);
            FloorOmissionMask=mask_3DWindow;
            ylim=size(StOCT_RotatedShifted,3);
            xlim=size(StOCT_RotatedShifted,2);
            zlim=size(StOCT_RotatedShifted,1);
                parfor yInd=1:ylim%going through all B-scans
                    for xInd=1:xlim%going through each A-scan
                        %Determine z-shift required
                        zShiftReq=-(find(mask_3DWindow(:,xInd,yInd)>0,1,'first')-1)%level of bottom of glass marked
                        StOCT_RotatedShifted(:,xInd,yInd)=circshift(StOCT_RotatedShifted(:,xInd,yInd),zShiftReq,1);
                        %StructureRotatedShifted(zlim-(zShiftReq-1):zlim,xInd,yInd)=0;
                        FloorOmissionMask(:,xInd,yInd)=circshift(mask_3DWindow(:,xInd,yInd),zShiftReq,1);
                    end
                end
%% since top containing window chamber window component is now wrapped around to the bottom, that needs to be remove
            StOCT_RotatedShifted=double(StOCT_RotatedShifted).*double(FloorOmissionMask);
            save(fullfile(DirectoryCoregistrationData,ScanNames{ind},'RawStruct_RotShift.mat'),'StOCT_RotatedShifted','-v7.3');
end            
% TryAutomatic=0;
% [transform2D_CoregExvivoInvivoBscan,RfixedInvivoBscan,~]=CoReg_Modalities(CODE_Coreg,DirectoryCoregistrationData,BscanInVivo,BscanExVivo,TryAutomatic,PreviouslyAlignedFound,0,[]);%7,12);

% SatisfiedCoreg{1}=0;
%     while SatisfiedCoreg{1}==0 || isempty(SatisfiedCoreg{1})
%             SatisfiedCoreg{1}=[] %Whether co-registration good enough
%             %MovingTemp=Hist_Img{ind};
%             if ~exist(fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_InVivoBscanMovingpoints.mat']))
%                 [mp,fp] = cpselect(BscanExVivo,ExVivoBscan_reg,Wait=true);
%                 if ~isempty(mp)
%                     save(fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_InVivoBscanMovingpoints.mat']),'mp','-v7.3')
%                     save(fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_InVivoBscanFixedpoints.mat']),'fp','-v7.3')
%                 end
%             else
%                 load(fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_InVivoBscanMovingpoints.mat']))
%                 load(fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_InVivoBscanFixedpoints.mat']))
%             end
% 
%             Transformations=fitgeotrans(mp,fp,"similarity");%Rigid transform + scaling
%             CoordinateSystemFixed = imref2d(size(ExVivoBscan_reg));
%             InVivoBscan_reg= imwarp(BscanExVivo,Transformations,OutputView=CoordinateSystemFixed);
% %             [Hist_Img_reg{ind},Transformations{ind}]=imregister(rgb2gray(Hist_Img{ind}),Hist_Img_reg{1},"affine")
%             %Transformations{ind}=
%             close gcf
%             figure, imshowpair(InVivoBscan_reg,ExVivoBscan_reg) %visualization
%                 while isempty(SatisfiedCoreg{1}) % Asking user if satisfied with visualization
%                     SatisfiedCoreg= str2double(inputdlg('Alignment okay? Yes=1, No=0 (default is yes)\n','Satisfactory?'));%,1)
%                         if isempty(SatisfiedCoreg{1})
%                             SatisfiedCoreg{1}=1;
%                         elseif SatisfiedCoreg{1}~=1||SatisfiedCoreg{1}~=0
%                             SatisfiedCoreg{1}=[];
%                         end
%                 end
%                 if SatisfiedCoreg{1}==1
%                     save(fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_registered_OCTInVivo.mat']),"InVivoBscan_reg");
%                     ind=ind+1;
%                 end
%     end
%% Co-registration of histology
for stain=1:2
    CoregisteredHistology_ExVivo{stain}=imwarp(imwarp(Hist_Img_reg{stain},transform2D_CoregHistExvivoBscan{1}),transform2D_CoregHistExvivoBscan{2},'OutputView',RfixedExvivoBscan);
end
    %%
    CoregisteredHistology_ExVivo_InVivo{1}=CoregisteredHistology_ExVivo{1};
    CoregisteredHistology_ExVivo_InVivo{2}=CoregisteredHistology_ExVivo{2};
    load(fullfile(DirectoryCoregistrationData,'Ex-vivo','mask3D_WindowExc_NoRotTransYet.mat'));%MaskWindowExVivo
    
    
    for xInd=1:size(CoregisteredHistology_ExVivo_InVivo,2)%going through each A-scan
        %Determine z-shift required
        zShiftReq=-(find(mask_3D_NoGlass(:,xInd,ClosestBscan)>0,1,'first')-1);%level of bottom of glass marked
        CoregisteredHistology_ExVivo_InVivo{1}(:,xInd,:)=circshift(CoregisteredHistology_ExVivo_InVivo{1}(:,xInd,:),zShiftReq,1);
        CoregisteredHistology_ExVivo_InVivo{2}(:,xInd,:)=circshift(CoregisteredHistology_ExVivo_InVivo{2}(:,xInd,:),zShiftReq,1);
        %StructureRotatedShifted(zlim-(zShiftReq-1):zlim,xInd,yInd)=0;
        FloorOmissionMask(:,xInd,ClosestBscan)=circshift(mask_3D_NoGlass(:,xInd,ClosestBscan),zShiftReq,1);
    end
    
    CoregisteredHistology_ExVivo_InVivo{1}=uint8(double(CoregisteredHistology_ExVivo_InVivo{1}).*double(FloorOmissionMask(:,:,ClosestBscan)));
    CoregisteredHistology_ExVivo_InVivo{2}=uint8(double(CoregisteredHistology_ExVivo_InVivo{1}).*double(FloorOmissionMask(:,:,ClosestBscan)));
    %% Loading in vivo final
    load(fullfile(DirectoryCoregistrationData,'In-vivo','RawStruct_RotShift.mat'));
    %%
    DirectoryCoregistrationData=fullfile(FilesDirectory,['Crop' char(num2str(CropNums(a))) '_AllInAll']);
    if ~exist(DirectoryCoregistrationData,'dir')
        mkdir(DirectoryCoregistrationData);
    end
    figure,imshow(imrotate(Hist_Img_reg{1},-90)), saveas(gcf,char(fullfile(DirectoryCoregistrationData,sprintf('SingleHistSectStain.png'))),'png');
    figure,imshowpair(BscanExVivo, CoregisteredHistology_ExVivo,'montage'), saveas(gcf,char(fullfile(DirectoryCoregistrationData,sprintf('SingleHistSectStain_ExVivoOCT.png'))),'png');
    figure,imshowpair(squeeze(StOCT_RotatedShifted(:,:,ClosestBscan)), CoregisteredHistology_ExVivo_InVivo,'montage'), saveas(gcf,char(fullfile(DirectoryCoregistrationData,sprintf('SingleHistSectStain_ExVivoOCT_InVivoOCT.png'))),'png'); 
    %tiledlayout('flow')
% nexttile,imshow(imrotate(Hist_Img_reg{1},-90))
% nexttile,imshowpair(BscanExVivo, CoregisteredHistology_ExVivo,'montage')
% nexttile,imshowpair(BscanInVivo, CoregisteredHistology_ExVivo_InVivo,'montage')
%%
figure, imfusion(InVivoBscan_reg,Hist_Img_reg{1})%H&E
figure, imfusion(InVivoBscan_reg,Hist_Img_reg{2})%LYVE1
