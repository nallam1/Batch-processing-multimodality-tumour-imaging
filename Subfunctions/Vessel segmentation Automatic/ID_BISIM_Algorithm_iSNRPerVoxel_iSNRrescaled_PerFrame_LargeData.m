function [minBISIM,Alpha1_F,Alpha2_F,iSNRFramey,vessels_processed_binary]=ID_BISIM_Algorithm_iSNRPerVoxel_iSNRrescaled_PerFrame_LargeData(iSNRFramey,FrameD3Dy,NumAlphaVals,BISIM_size_zVOIpix,BISIM_size_xVOIpix,RangeZ_toSample,RangeX_toSample,RangeZ_VOI_window,RangeX_VOI_window,AlphasRangeY)%RangeOfDThresh%Patch_stack_Complex,
    %% by Nader A.
    % iSNR computation at frame y
     %noise per column (A-scan)
     
%      FrameStructy=rescale(FrameStructy); % if not already rescaled by Oversaturation removal (e.g., if set to 0 os removal), equivalent
%           Time_Var_noise=mean(var(FrameStructy((end-iSNR_size_zVOIpix):end,:,:),0,3),1);%mean(,'all');%mean(var(double(Patch_stack_Re((end-iSNR_zNumVOIs):end,:,:,y))+Im1*double(Patch_stack_Im((end-iSNR_zNumVOIs):end,:,:,y)),0,3),'all');
%           mean_Time_Var_noise=mean(Time_Var_noise,'all');
%           FrameStructy(FrameStructy<mean_Time_Var_noise)=mean_Time_Var_noise;%these are the noisiest regions
          %OR rescale(iSNRFramey) so it is well within range [0,1]??
          %Take mean of max of time averaged signals along A-scans within certain depth
%            Time_Mean_Signal=squeeze(mean(FrameStructy(:,:,:),3));%Time_Mean_Signal=mean(mean(double(Patch_stack_Re(20:round(DimsDataPatch_pix(1)/4),:,:,y))+Im1*double(Patch_stack_Im(20:round(DimsDataPatch_pix(1)/4),:,:,y)),3),'all');
          %Time Max? instead of mean since it can mostly only drop from rotating
          %scatterers? (phasor time variation) but average to remove white
          %noise contribution
          %iSNRFullFramey=Time_Var_noise./Time_Mean_Signal;
               % [D3D{PatchCount}(:,:,y)]=removeOversaturation2(D3D{PatchCount}(:,:,y),0.003);--no
               % real visible difference
%                 iSNRFramey=Time_Var_noise./Time_Mean_Signal;%abs(Time_Var_noise./Time_Mean_Signal);%mean(Time_Var_noise./Time_Mean_Signal,'all');
                 %To achieve highest D-threshold of 1, for the current frame with given iSNR 
                    %alphaMiny=acotd(1/iSNRFramey{PatchCount}(y));
                    %AlphasRangeY=acotd(RangeOfDThresh/iSNRFramey);
                     iSNRFramey=rescale(iSNRFramey,'InputMax',median(iSNRFramey,'all')*2.34);%since D3D all terms well within 0 to 1 within first decimal place unlike iSNR
            %iSNR never high enough to allow alpha to make difference
            % Replication Padding
                D3D_Patch_Repli_y=padarray(FrameD3Dy,[floor(BISIM_size_zVOIpix/2),floor(BISIM_size_xVOIpix/2)],'replicate','pre');%padarray(squeeze(D3D_Patch(:,:,y)),[round(BISIM_zNumVOIs/2),round(BISIM_xNumVOIs/2)],'replicate','both');
                iSNRFramey_Reply_y=padarray(iSNRFramey,[floor(BISIM_size_zVOIpix/2),floor(BISIM_size_xVOIpix/2)],'replicate','pre');
        
                D3D_Patch_Repli_y=padarray(D3D_Patch_Repli_y,[ceil(BISIM_size_zVOIpix/2)-1,ceil(BISIM_size_xVOIpix/2)-1],'replicate','post');
                iSNRFramey_Reply_y=padarray(iSNRFramey_Reply_y,[ceil(BISIM_size_zVOIpix/2)-1,ceil(BISIM_size_xVOIpix/2)-1],'replicate','post'); %to be immune to odd/even
            
            vector_struct=zeros(NumAlphaVals,length(RangeZ_toSample),length(RangeX_toSample),2);%zeros(90,size(D3D_Patch_Repli_y,1),size(D3D_Patch_Repli_y,2),2);--For speed
            D3D_Patch_Repli_thresh=zeros(size(D3D_Patch_Repli_y,1),size(D3D_Patch_Repli_y,2));
                    %zeros(NumAlphaVals,size(D3D_Patch_Repli_y,1),size(D3D_Patch_Repli_y,2));
            %AlphasRangeY=zeros(size(D3D_Patch_Repli_y,1),size(D3D_Patch_Repli_y,2),NumAlphaVals);%for every (z,x) position compute range of 90 (numAlphas) to skim throguh?
            %FrameMeaniSNR=mean(iSNRFramey,'all'); --sometimes iSNR goes to
            %inf
            
%             FrameMedianiSNR=median(iSNRFramey(:,:),'all');
%             
%             AlphasRangeY=RangeOfAlhaThreshFunc(acotd(max(FrameD3Dy,[],'all')/FrameMedianiSNR),acotd(min(FrameD3Dy(FrameD3Dy>0),[],'all')/FrameMedianiSNR));
%              try
%                 AlphasRangeY=RangeOfAlhaThreshFunc(acotd(max(FrameD3Dy,[],'all')/FrameMedianiSNR),acotd(min(FrameD3Dy,[],'all')/FrameMedianiSNR));
%             catch
%                 AlphasRangeY=RangeOfAlhaThreshFunc(acotd(max(FrameD3Dy,[],'all')/FrameMedianiSNR),90);
%             end            %AlphasRangeY=RangeOfAlhaThreshFunc(acotd(1/FrameMeaniSNR),acotd(0/FrameMeaniSNR));%single representative alpha range for entire frame but different then before since now not single representative iSNR value for entire frame (not multiple alpha ranges to maintain contrast I think)
%             fprintf('y=%d, BISIM for multiple alpha_t computation, each at multiple (z,x) coordinates ...\n',y);
            
            for alpha_t_ind=1:NumAlphaVals
                %Iterating through decorrelation thresholds based on
                %sloping of ID curve
%                 fprintf('y=%d, alpha_t=%d, BISIM computation at multiple (z,x) coordinates ...\n',y,alpha_t);
               
                    FrameOfDecorrelation_thresh=cotd(AlphasRangeY(alpha_t_ind)).*iSNRFramey_Reply_y(:,:);%iSNR;%iSNRFullFramey%iSNR(zVOI,xVOI,yVOI);
                
                
                D3D_Patch_Repli_thresh(:,:)=single(D3D_Patch_Repli_y(:,:)>FrameOfDecorrelation_thresh(:,:));%double(D3D_Patch_Repli_y(:,:).*(D3D_Patch_Repli_y(:,:)>Decorrelation_thresh));
%alpha_t_ind,
%                 for x=1:DimsDataPatch_pix(2)%TOO SLOOOOOOWW
%                 for z=1:DimsDataPatch_pix(1)
                
            for x=1:length(RangeX_toSample)
                for z=1:length(RangeZ_toSample)
                    %Computation of structural vector at every (z,x) voxel
                    %based on square window of surrounding voxels for given
                    %binarized B-scan frame
%                     RangeX_VOI_window=((-floor(BISIM_size_xVOIpix/2)):ceil(BISIM_size_xVOIpix/2)-1);
%                     RangeZ_VOI_window=((-floor(BISIM_size_zVOIpix/2)):ceil(BISIM_size_zVOIpix/2)-1);
%                     RangeX_VOI=(x+floor(BISIM_size_xVOIpix/2))+RangeX_VOI_window;
%                     RangeZ_VOI=(z+floor(BISIM_size_zVOIpix/2))+RangeZ_VOI_window;
                    RangeX_VOI=(RangeX_toSample(x)+floor(BISIM_size_xVOIpix/2))+RangeX_VOI_window;
                    RangeZ_VOI=(RangeZ_toSample(z)+floor(BISIM_size_zVOIpix/2))+RangeZ_VOI_window;
%                     if mod(BISIM_size_zVOIpix,2)==0
%                         RangeZ_VOI=(z-1)+((-round(BISIM_size_zVOIpix/2)+1):round(BISIM_size_zVOIpix/2));
%                         RangeX_VOI=(x)+((-round(BISIM_size_xVOIpix/2)+1):round(BISIM_size_xVOIpix/2)); 
%                     else
%                         RangeZ_VOI=(z+floor(BISIM_size_zVOIpix/2))+((-floor(BISIM_size_zVOIpix/2)):ceil(BISIM_size_zVOIpix/2)-1);
%                         RangeX_VOI=(x)+((-round(BISIM_size_xVOIpix/2)+1):round(BISIM_size_xVOIpix/2)); 
                    [Zgrid,Xgrid]=meshgrid(RangeZ_VOI_window,RangeX_VOI_window);
                    vector_struct(alpha_t_ind,z,x,1)=sum(D3D_Patch_Repli_thresh(RangeZ_VOI,RangeX_VOI).*Zgrid,'all');%projects along each direction
                    vector_struct(alpha_t_ind,z,x,2)=sum(D3D_Patch_Repli_thresh(RangeZ_VOI,RangeX_VOI).*Xgrid,'all');%vector_struct(alpha_t,z,x,2)=sum(D3D_Patch_Repli_thresh(alpha_t,:,:).*Ygrid,'all');
                end    %alpha_t_ind,
            end
            end
            
            
            % Computing difference between vectors for all alpha_t values
            

%             fprintf('\nDetermining optimal BISIM for current patch at y=%d\n',y)
            Diff_vector_struct=zeros(NumAlphaVals,NumAlphaVals);
            for M=1:NumAlphaVals
                for L=M:NumAlphaVals %(filling a triangle essentially)
                    if M~=L
                        Diff_vector_struct(M,L)=sum(sqrt((vector_struct(M,:,:,1)-vector_struct(L,:,:,1)).^2+(vector_struct(M,:,:,2)-vector_struct(L,:,:,2)).^2),'all');
                    end
                end
            end
             %Computng BISIM for the single frame y (based on different
            %combinartions of alpha1 and alpha2 instead of k means
            %clustering
            %classes
            BISIM=zeros(NumAlphaVals-2,NumAlphaVals-2);
            for alpha1_ind=2:NumAlphaVals-1%88
                for alpha2_ind=2:NumAlphaVals-1%(alpha1+1):89
            RangeClass1=(1):(alpha1_ind);
            RangeClass2=(alpha1_ind+1):(alpha2_ind);
            RangeClass3=(alpha2_ind+1):(NumAlphaVals);            %V(alpha1,alpha2,1)
            V(1)=sum(Diff_vector_struct(RangeClass1,RangeClass1),'all');%/2;--if do not choose to fill triangle method
            %only sums within class 1, full sum at the end does not look at
            %excluded differences
            V(2)=sum(Diff_vector_struct(RangeClass2,RangeClass2),'all');
            V(3)=sum(Diff_vector_struct(RangeClass3,RangeClass3),'all');
            
            BISIM(alpha1_ind,alpha2_ind)=sum(V)/sum([length(RangeClass1)^2,length(RangeClass2)^2,length(RangeClass3)^2]);
                end
            end
                [minBISIM,LinIndx]=min(BISIM(2:(NumAlphaVals-1),2:(NumAlphaVals-1)),[],'all','linear');%index counts the 1:89 (must include 1)
                [~,cols]=size(BISIM(2:(NumAlphaVals-1),2:(NumAlphaVals-1)));%rows
                alpha_ind=2:(NumAlphaVals-1);
                
                if mod(LinIndx,cols)==0
                    ColIndx=floor(LinIndx/cols);
                    RowIndx=NumAlphaVals-2;%corresponds to length
                else
                    ColIndx=floor(LinIndx/cols)+1;
                    RowIndx=mod(LinIndx,cols);
                end
                alpha2_ind=alpha_ind(ColIndx);
                alpha1_ind=alpha_ind(RowIndx);
                Alpha1_F=AlphasRangeY(alpha1_ind);
                Alpha2_F=AlphasRangeY(alpha2_ind);
                    %fprintf('******\nIn y=%d for considered patch %d, Optimal alpha values: alpha1=%d and alpha2=%d\n******\n',y,PatchCount,Alpha1_F,Alpha2_F);
                    
                    TrueAlphaT=AlphasRangeY(alpha1_ind);
                    FrameOfDecorrelation_thresh=cotd(TrueAlphaT).*iSNRFramey;%iSNR;

                        vessels_processed_binary=(FrameD3Dy>FrameOfDecorrelation_thresh);%D3D{PatchCount}(:,:,y).*(D3D{PatchCount}(:,:,y)>Decorrelation_thresh);
end
%             for alpha1=2:88
%                 for alpha2=(alpha1+1):89
%                     if 1<M && 1<L && M<alpha1 && L<alpha1  
%                         V(alpha1,alpha2,1)=sum(Diff_vector_struct(%the Bisim for class 1
        %toc            %based on k means clustering
% %             ClassesCoord=zeros(90,3,2);%For all values of M (the reference alpha T) stores the 3 separating classes (not exactly corresponding to alpha 1 and 2) based on the difference in vector value from the reference M vector value 
% %                 %or Otsu's method?
% %             for M=1:90
% %                 Diff_vector_struct=zeros(89,1);
% %                 for L=1:90
% %                     if M~=L
% %                         Diff_vector_struct(L,1)=sum(sqrt((vector_struct(M,:,:,1)-vector_struct(L,:,:,1)).^2+(vector_struct(M,:,:,2)-vector_struct(L,:,:,2)).^2),'all');
% %                         Diff_vector_struct(L,2)=L;
% %                     end
% %                 end
% %                 %Identifying three clusters for 3 classes see "Automatic 3D adaptive vessel segmentation based on linear relationship between intensity and complex-decorrelation in optical coherence tomography angiography"
% %                 %all for single frame y
% %                   [idx,ClassesCoord(M,:,:)] = kmeans(Diff_vector_struct,3);
% %                    %take the mean after each 3 classes obtained to ensure
% %                    %best choice, or maybe randomly choose index M from
% %                    %which to compute best values separating 3 classes
% %             end
% %             %Determined alpha1 and alpha2 values
% %             alpha1=mean(median([ClassesCoord(:,1,2),ClassesCoord(:,2,2)]));
% %             alpha2=mean(median([ClassesCoord(:,2,2),ClassesCoord(:,3,2)]));