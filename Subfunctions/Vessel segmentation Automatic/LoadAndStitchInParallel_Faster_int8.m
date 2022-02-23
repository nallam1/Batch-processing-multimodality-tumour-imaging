function [FullStackComponent]=LoadAndStitchInParallel_Faster_int8(ind,Gfilename,depth_image, Widthx, BscansPerY, Lengthy,TimeRepsToUse,NumPatches)
    %% by Nader A.
    %% LOADING LINEAR DATA
    di=[];di=fopen(Gfilename,'r');
        LinearData_ReorIm=fread(di,'int16=>int8');%try 'int16=>int8' for speed? instead of 'int16=>int16' source and loaded 
    fclose(di); %fclose(di2);
    %toc cannot have toc here
    %% SHAPING MATRIX
        FullStackComponent=single(reshape(LinearData_ReorIm,depth_image, Widthx, BscansPerY, Lengthy));%Try without single?
        %toc
    %% EXTRACTING REQUIRED INFO FROM MATRIX
        if TimeRepsToUse>BscansPerY
            TimeRepsToUse=BscansPerY; %single(single(Main_stack_Re)+sqrt(-1)*single(Main_stack_Im));%imrotate3(fliplr(),90,[0,1,0]);
            %FullStackComponent=single(single(Main_stack_Re(:,:,1:TimeRepsToUse,:))+sqrt(-1)*single(Main_stack_Im(:,:,1:TimeRepsToUse,:)));%imrotate3(fliplr(),90,[0,1,0]);            
        end
    
        if ind==1
            FullStackComponent=FullStackComponent(1:depth_image,(1:(Widthx-12)),1:TimeRepsToUse,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
        elseif ind==NumPatches%length(LinearData_Re)
            FullStackComponent=FullStackComponent(1:depth_image,(13:Widthx),1:TimeRepsToUse,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
        else%middle
            FullStackComponent=FullStackComponent(1:depth_image,(13:(Widthx-12)),1:TimeRepsToUse,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
        end
    
end
    
    