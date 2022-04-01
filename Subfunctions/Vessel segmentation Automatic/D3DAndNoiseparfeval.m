function [iSNR,D3D]=D3DAndNoiseparfeval(CompSigRepliPatch,iSNR_size_zVOIpix,DimsDataPatch_pix) %meanstruct,NoiseFloorPerAscanAllFrames
%% by Nader A.
%meanstruct=single(squeeze(mean(abs(CompSigRepliPatch),3)));%rescale low sigal to noise floor before mean or fter may not make a huge difference--either way low SNR region
%NoiseFloorPerAscanAllFrames=single(squeeze(mean(var(abs(CompSigRepliPatch((end-iSNR_size_zVOIpix):end,:,:,:)),0,3),1)));
iSNR=single(squeeze(mean(mean(var(abs(CompSigRepliPatch((end-iSNR_size_zVOIpix+1-ceil(iSNR_size_zVOIpix/2)):end-ceil(iSNR_size_zVOIpix/2),:,:,:)),0,3),1),2)))./single(shiftdim(squeeze(mean(abs(CompSigRepliPatch((1+floor(iSNR_size_zVOIpix/2):end-ceil(iSNR_size_zVOIpix/2)),:,:,:)),3)),2));%single(mean(squeeze(mean(var(abs(CompSigRepliPatch((end-iSNR_size_zVOIpix):end,:,:,:)),0,3),1)),2))./single(squeeze(mean(abs(CompSigRepliPatch),3)));
iSNR=shiftdim(iSNR,1);
 prod_t1_t2=single(squeeze(zeros(size(CompSigRepliPatch,1),size(CompSigRepliPatch,2),size(CompSigRepliPatch,3)-1,size(CompSigRepliPatch,4))));%squeeze(single(zeros(gather(size(ReImStack_Repli,1)),DimsDataPatch_pix(2),DimsDataPatch_pix(3)-1,DimsDataPatch_pix(4))));%tall();
 prod_sum_t1_t1__t2_t2=single(squeeze(zeros(size(CompSigRepliPatch,1),size(CompSigRepliPatch,2),size(CompSigRepliPatch,3)-1,size(CompSigRepliPatch,4))));%squeeze(single(zeros(gather(size(ReImStack_Repli,1)),DimsDataPatch_pix(2),DimsDataPatch_pix(3)-1,DimsDataPatch_pix(4))));%tall();

    for t=1:(size(CompSigRepliPatch,3)-1)
%         time1=ReImStack_Replipatch{X}(:,:,1,:);%+Im1*ImStack_Repli(:,:,1,:),'single');
%         time2=ReImStack_Replipatch{X}(:,:,2,:);%cast(%+Im1*ImStack_Repli(:,:,2,:),'single');
            prod_t1_t2(:,:,t,:)=squeeze(CompSigRepliPatch(:,:,1,:).*conj(CompSigRepliPatch(:,:,2,:)));%squeeze(a.*c+b.*d-Im1*double(a.*d+b.*c));Should be -a*d +b*c %squeeze(ReStack_Repli(:,:,1,:).*ImStack_Repli(:,:,2,:));
            prod_sum_t1_t1__t2_t2(:,:,t,:)=squeeze(CompSigRepliPatch(:,:,1,:).*conj(CompSigRepliPatch(:,:,1,:))+CompSigRepliPatch(:,:,2,:).*conj(CompSigRepliPatch(:,:,2,:)));%squeeze(abs(a+Im1*double(b)).^2+abs(c+Im1*double(d)).^2);%squeeze(ReStack_Repli(:,:,1,:).*ImStack_Repli(:,:,1,:)+ReStack_Repli(:,:,2,:).*ImStack_Repli(:,:,2,:));
        CompSigRepliPatch(:,:,1,:)=[];
    end
    clearvars CompSigRepliPatch
D3D=single(zeros(DimsDataPatch_pix(1),DimsDataPatch_pix(2),DimsDataPatch_pix(4)));
    for z=1:DimsDataPatch_pix(1)%size(CompSigRepliPatch,1)parfor z=1:DimsDataPatch_pix(1)%size(ReStack,1)%y=1:size(Re_VOI,4) %sending large data to each worker?
        %fprintf('D3D at Depth... %d of %d\n',z,DimsDataPatch_pix(1));
        D3D(z,:,:)=squeeze(sqrt(1-(sum(abs(sum(prod_t1_t2(z:(z-1+iSNR_size_zVOIpix),:,:,:),1)),3))./sum(0.5*sum(prod_sum_t1_t1__t2_t2(z:(z-1+iSNR_size_zVOIpix),:,:,:),1),3)));%);%sqrt(1-(squeeze(sum(squeeze(abs(sum(prod_t1_t2(z:(z-1+zVOI_pix),:,:,:),1))),2))./squeeze(sum(squeeze(0.5*sum(prod_sum_t1_t1__t2_t2(z:(z-1+zVOI_pix),:,:,:),1)),2))));
    end
end


