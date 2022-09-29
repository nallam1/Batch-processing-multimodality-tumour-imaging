function D3D=ComplexDecorrelationFaster7_Tall(ReImStack,DimsDataPatch_pix,zVOI_pix,TallorNot,tstart)%Re_VOI,Im_VOI,M,T)
%% by Nader A.
%% Compute complex decorrelation of given ROI
% Re_VOI: Real Spatiotemporal 4D data   
% Im_VOI: Imaginary Spatiotemporal 4D data    
% M: Dimensions of VOI    
% T: Numbery of B scans per y-step (repeats over time)
D3D=single(zeros(DimsDataPatch_pix(1),DimsDataPatch_pix(2),DimsDataPatch_pix(4)));
%% Replication Padding
ReImStack_Repli=cast([repmat(ReImStack(1,:,:,:),floor(zVOI_pix/2),1,1,1);ReImStack;repmat(ReImStack(end,:,:,:),ceil(zVOI_pix/2),1,1,1)],'single');%tall();
%ReImStack_Repli=tall(cast([repmat(ReImStack(1,:,:,:),floor(zVOI_pix/2),1,1,1);ReImStack;repmat(ReImStack(end,:,:,:),ceil(zVOI_pix/2),1,1,1)],'single'));%double([repmat(ReStack(1,:,:,:),floor(zVOI_pix/2),1,1,1);ReStack;repmat(ReStack(end,:,:,:),ceil(zVOI_pix/2),1,1,1)]);%double([repmat(ReStack(1,:,:,:),round(zVOI_pix/2)-1,1,1,1);ReStack;repmat(ReStack(end,:,:,:),round(zVOI_pix/2),1,1,1)]);%zeros(Re_VOI
%ImStack_Repli=cast([repmat(ImStack(1,:,:,:),floor(zVOI_pix/2),1,1,1);ImStack;repmat(ImStack(end,:,:,:),ceil(zVOI_pix/2),1,1,1)],'single');%zeros(Re_VOI
%% Compute decorrelation per en face/transverse cross-section in depth
%  w_z=[ones(zVOI_pix,DimsData_pix(2),DimsData_pix(3),DimsData_pix(4));zeros(DimsData_pix(1),DimsData_pix(2),DimsData_pix(3),DimsData_pix(4))];%[ones(zVOI_pix,DimsData_pix(2),DimsData_pix(3),DimsData_pix(4));zeros(DimsData_pix(1)-zVOI_pix,DimsData_pix(2),DimsData_pix(3),DimsData_pix(4))];%3D spatial window centered around every target voxel at depth z along all A-scans over time, 1 axial layer at a time
%  disp(size(w_z)) 
 disp('Computing complex decorrelation signal')

clearvars ReImStack %ReStack ImStack
% clear global Main_stack_Re 
% clear global Main_stack_Im
prod_t1_t2=squeeze(zeros(size(ReImStack_Repli,1),DimsDataPatch_pix(2),DimsDataPatch_pix(3)-1,DimsDataPatch_pix(4)));%squeeze(single(zeros(gather(size(ReImStack_Repli,1)),DimsDataPatch_pix(2),DimsDataPatch_pix(3)-1,DimsDataPatch_pix(4))));%tall();
prod_sum_t1_t1__t2_t2=squeeze(zeros(size(ReImStack_Repli,1),DimsDataPatch_pix(2),DimsDataPatch_pix(3)-1,DimsDataPatch_pix(4)));%squeeze(single(zeros(gather(size(ReImStack_Repli,1)),DimsDataPatch_pix(2),DimsDataPatch_pix(3)-1,DimsDataPatch_pix(4))));%tall();
fprintf('First intermediate steps stored in memory for speed...\n');
Im1=sqrt(-1);
toc(tstart)
if DimsDataPatch_pix(3)==2
    prod_t1_t2(:,:,:)=squeeze(ReImStack_Repli(:,:,1,:).*conj(ReImStack_Repli(:,:,2,:)));%squeeze(a.*c+b.*d-Im1*double(a.*d+b.*c));Should be -a*d +b*c %squeeze(ReStack_Repli(:,:,1,:).*ImStack_Repli(:,:,2,:));
    prod_sum_t1_t1__t2_t2(:,:,:)=squeeze(ReImStack_Repli(:,:,1,:).*conj(ReImStack_Repli(:,:,1,:))+ReImStack_Repli(:,:,2,:).*conj(ReImStack_Repli(:,:,2,:)));%squeeze(abs(a+Im1*double(b)).^2+abs(c+Im1*double(d)).^2);%squeeze(ReStack_Repli(:,:,1,:).*ImStack_Repli(:,:,1,:)+ReStack_Repli(:,:,2,:).*ImStack_Repli(:,:,2,:));
    
    clearvars ReImStack_Repli ReStack_Repli ImStack_Repli
    
    for z=1:DimsDataPatch_pix(1)%parfor z=1:DimsDataPatch_pix(1)%size(ReStack,1)%y=1:size(Re_VOI,4) %sending large data to each worker?
        fprintf('D3D at Depth... %d of %d\n',z,DimsDataPatch_pix(1));
        
        D3D(z,:,:)=squeeze(sqrt(1-(abs(sum(prod_t1_t2(z:(z-1+zVOI_pix),:,:),1)))./(0.5*sum(prod_sum_t1_t1__t2_t2(z:(z-1+zVOI_pix),:,:),1))));%);%sqrt(1-(squeeze(sum(squeeze(abs(sum(prod_t1_t2(z:(z-1+zVOI_pix),:,:,:),1))),2))./squeeze(sum(squeeze(0.5*sum(prod_sum_t1_t1__t2_t2(z:(z-1+zVOI_pix),:,:,:),1)),2))));
    end%gather(
    %tocBytes(gcp)
    %toc
    toc
    disp([toc])

else
    for t=1:(DimsDataPatch_pix(3)-1)
    toc(tstart)
    %     a=ReStack_Repli(:,:,1,:);
    %     b=ImStack_Repli(:,:,1,:);
    %     c=ReStack_Repli(:,:,2,:);
    %     d=ImStack_Repli(:,:,2,:);
        time1=ReImStack_Repli(:,:,1,:);%+Im1*ImStack_Repli(:,:,1,:),'single');
        time2=ReImStack_Repli(:,:,2,:);%cast(%+Im1*ImStack_Repli(:,:,2,:),'single');
            prod_t1_t2(:,:,t,:)=squeeze(time1.*conj(time2));%squeeze(a.*c+b.*d-Im1*double(a.*d+b.*c));Should be -a*d +b*c %squeeze(ReStack_Repli(:,:,1,:).*ImStack_Repli(:,:,2,:));
            prod_sum_t1_t1__t2_t2(:,:,t,:)=squeeze(time1.*conj(time1)+time2.*conj(time2));%squeeze(abs(a+Im1*double(b)).^2+abs(c+Im1*double(d)).^2);%squeeze(ReStack_Repli(:,:,1,:).*ImStack_Repli(:,:,1,:)+ReStack_Repli(:,:,2,:).*ImStack_Repli(:,:,2,:));

        ReImStack_Repli(:,:,1,:)=[];%every time clears the time layer just processed
        %ImStack_Repli(:,:,1,:)=[];
    end
clearvars ReImStack_Repli ReStack_Repli ImStack_Repli
%tic
%ticBytes(gcp)
 %parfor--too slow since lots of overhead from sending large dataset to all
 %workers
 toc(tstart)
for z=1:DimsDataPatch_pix(1)%parfor z=1:DimsDataPatch_pix(1)%size(ReStack,1)%y=1:size(Re_VOI,4) %sending large data to each worker?
fprintf('D3D at Depth... %d of %d\n',z,DimsDataPatch_pix(1));

D3D(z,:,:)=squeeze(sqrt(1-(sum(abs(sum(prod_t1_t2(z:(z-1+zVOI_pix),:,:,:),1)),3))./sum(0.5*sum(prod_sum_t1_t1__t2_t2(z:(z-1+zVOI_pix),:,:,:),1),3)));%);%sqrt(1-(squeeze(sum(squeeze(abs(sum(prod_t1_t2(z:(z-1+zVOI_pix),:,:,:),1))),2))./squeeze(sum(squeeze(0.5*sum(prod_sum_t1_t1__t2_t2(z:(z-1+zVOI_pix),:,:,:),1)),2))));
end%gather(
%tocBytes(gcp)
%toc
%toc
% disp([toc])
toc(tstart)
end
if TallorNot==1
D3D=tall(D3D);
end
end


%along time dimension
        
%           NumeratorPreTempAve(:,t,:)=squeeze(sum(circshift(w_z,z-1).*squeeze(ReStack_Repli(:,:,t,:).*ImStack_Repli(:,:,t+1,:)),1));%circularshift window into view%ReStack_Apod(z+(-round(zVOI_pix/2):round(zVOI_pix/2)),:,:,:)
%           DenominatorPreTempAve(:,t,:)=squeeze(0.5*sum(circshift(w_z,z-1).*squeeze(ReStack_Repli(:,:,t,:).*ImStack_Repli(:,:,t,:)+ReStack_Repli(:,:,t+1,:).*ImStack_Repli(:,:,t+1,:)),1));     
    
%Calculate all the products ahead of time and just call them
% NumeratorPostTempAve(:,:)=squeeze(sum(NumeratorPreTempAve,2));% mean since w is weight
% DenominatorPostTempAve(:,:)=squeeze(sum(DenominatorPreTempAve,2));    