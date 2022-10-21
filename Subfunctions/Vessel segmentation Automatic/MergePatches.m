function [Merged_XD]=MergePatches(PatchesPatched_X_1_D)
%% Merged_XD is generated X dimensions stitched together volume from processing     
%         clearvars SubStack_Re
%         %% IMAGINARY
%          Merged_XD=[];%zeros([DimsDataFull_pix(1),DimsDataFull_pix(2),DimsDataFull_pix(4)],'int16');%12 from right and 12 from left as explaned below
%         depth_image=DimsDataFull_pix(1);
%         Widthx=DimsDataFull_pix(2);
%         BscansPerY=DimsDataFull_pix(3);
%         Lengthy=DimsDataFull_pix(4);
Merged_XD=imrotate3(fliplr([PatchesPatched_X_1_D{end:-1:1}]),90,[0,1,0]);
%         for ind=length(PatchesPatched_X_1_D):-1:1
%             Merged_XD=[Merged_XD PatchesPatched_X_1_D{ind}];
%             %SubStack=PatchesPatched_X_1_D{ind};%_Im{ind}=reshape(LinearData_Re{ind},depth_image, Widthx, BscansPerY, Lengthy);
% %             if ind==1 
% %                 Merged_XD(1:depth_image,(1:(Widthx-12)),:,:)=PatchesPatched_X_1_D{ind};%(1:depth_image,(1:(Widthx-12)),:,:); %Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
% %             elseif ind==length(LinearData_Re)
% %                 Merged_XD(1:depth_image,((ind-1)*(Widthx-12))+(1:(Widthx-12)),:,:)=PatchesPatched_X_1_D{ind};%(1:depth_image,(13:Widthx),:,:)%Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
% %             else
% %                 Merged_XD(1:depth_image,((ind-1)*(Widthx-12))+(13:(Widthx-12)),:,:)=PatchesPatched_X_1_D{ind};%(1:depth_image,(13:(Widthx-12)),:,:)%Usually stitches together taking away des 12 derniers et 12 premiers pixels de chaque partition centrales et seulement 12 derniers de la premièrre, 12 premiers de la dernière
% %             end
%         end
        

end
