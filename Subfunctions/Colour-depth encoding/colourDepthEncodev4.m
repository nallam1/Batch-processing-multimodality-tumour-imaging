function DepthEncodedIm= colourDepthEncodev4(BinaryVolume,width_x,width_y,SaveLocationAndName,zPixScaleInPhysDims_um,cmap)
    %zPixScaleInPhysDims: The issue is that this must account for both air
    %and tissue (let's say first vessel is at 100pix, this includes a few
    %pixels in air and another few in tissue--> so true pixel scale is the
    %weighted average which is impractical so maybe compromise is to just use the average)
    
    x=size(BinaryVolume,2);
    y=size(BinaryVolume,3);
   
    Maxdepth=size(BinaryVolume,1);
    DepthEncodedIm=zeros([x,y]);%[y,x]); 
   % BinaryVolumeTemp=permute(BinaryVolume,[1,3,2]);%flip(flip(permute(BinaryVolume,[1,3,2]),2),3);
%parfor z=1:depth
    zShown=zeros([x,y]);%[y,x]);
%     zPixScaleApparentInTissue=7.74/1000; %0.60 um error from measurement of borosilicate glass in Feb 2021
%     zPixScaleAsWouldAppearInAir=zPixScaleApparentInTissue*1.4;%Use in air
%     since this is comparable to scale in transverse plane (not distorted
%     by Snell's law
parfor ypos=1:y
 for xpos=1:x
VesselVoxAtDepth= find(BinaryVolume(:,xpos,ypos),1,'first');%BinaryVolumeTemp
     if isempty(VesselVoxAtDepth)
         zShown(xpos,ypos)=Maxdepth;%*1000;%Multiply to make background in depth%Maxdepth-Maxdepth;%0;%Maxdepth;%
     else
         zShown(xpos,ypos)=VesselVoxAtDepth;%Maxdepth-VesselVoxAtDepth;%zPixScaleAsWouldAppearInAir*(%VesselVoxAtDepth;%-1*VesselVoxAtDepth+Maxdepth;%-1*VesselVoxAtDepth;
     end
 end
end
% c=colormap('hot');
% 
% c(:,1)=c(end:-1:1,1);
% c(:,2)=c(end:-1:1,2);
% c(:,3)=c(end:-1:1,3);
% DepthEncodedIm=ind2rgb(zShown,c);%imrotate(ind2rgb(zShown,c),180);
DepthEncodedIm=-imrotate(zShown,90);
%to fix visualizarion too tired
% imagesc(squeeze(mean(vessels_processed,3)))
%% Figure to visualize
            set(figure,'Position',[100,100,800,600],'visible','on');
            fs=60%18%70;  
            % imagesc(width_x,width_y,(projection),[0.2*10^6 3.3*10^6])%,[600 1900]); 
            %imagesc(width_x,width_y,DepthEncodedIm)%,[800 1600]);
            %imagesc(DepthEncodedIm)%,[800 1600]);
            imagesc(DepthEncodedIm)%fliplr(DepthEncodedIm))
            colormap(cmap)%colormap 'hot'; 
            % title(['AIP, mouse ' mouse ', nrcOCT' ],'FontWeight','Bold','FontSize',fs); 
            %title(['AIP, nrcOCT' ],'FontWeight','Bold','FontSize',fs); 
            
            xticks([1,x/2,x])
            xticklabels([round(0), round(width_x/2,1),round(width_x,1)])
             xlabel('Width_x [mm]','FontWeight','Bold','FontSize',fs-10);
           
            yticks([1,y/2,y])
            yticklabels([round(0), round(width_y/2,1),round(width_y,1)])
             ylabel('Width_y [mm]','FontWeight','Bold','FontSize',fs-10);
            axis tight; set(gca,'FontWeight','Bold','FontSize',fs-11);
             caxis([-Maxdepth,0])%[1,Maxdepth])%max(zShown(zShown<Maxdepth),[],'all')]
            %colormap 'hot'; 
           
            hcb1=colorbar; 
            set(hcb1,'FontSize',fs-50,'LineWidth',1,'TickLength',0.01);%-5
            set(gcf,'PaperUnits','inches','PaperPosition',[0 0 26 23])
            TicksDepth=linspace(min(DepthEncodedIm,[],'all'),0,3);%[0:.2/zPixScaleAsWouldAppearInAir:max(zShown(zShown<Maxdepth),[],'all')];
            for ind=1:length(TicksDepth)
                TicksDepthLabels{ind}=sprintf('%.2f',(1*TicksDepth(ind)*zPixScaleInPhysDims_um/1000));%round((-1*TicksDepth(end-(ind-1)))*zPixScaleAsWouldAppearInAir/1000,2));
            end
            TicksDepthLabels{end}='0';
            c=colorbar('Ticks',TicksDepth,...
            'TickLabels',TicksDepthLabels,'FontSize',fs-30)%-3)%40)
                c.Label.String = 'Depth [mm]';
                c.Label.FontSize = fs-10;
            %%    
    %title('svOCT')%('Post-processed svOCT (en-face)')
        saveas(gcf,[SaveLocationAndName,'_Image.png'],'png')%[SaveLocation '/DepthEncoded Post-processedVasculature map.png'],'png')
        figure, imagesc(DepthEncodedIm)
            xticklabels({})
            yticklabels({})
            xticks([])
            yticks([])
        saveas(gcf,[SaveLocationAndName,'_ImageNoLabels.png'],'png')
        save([SaveLocationAndName,'.mat'],'DepthEncodedIm','-v7.3')
% VTD2=imresize3(VTD,[Dims(1),Dims(2),Dims(2)]);
% figure, imagesc(imrotate(squeeze(sum(VTD2,1)),90))
% colormap 'hot'
% yticks([1,Dims(2)/2,Dims(2)])
% xticks([1,Dims(2)/2,Dims(2)])
% xlabel('Width_x [mm]','FontWeight','Bold','FontSize',fs);
% ylabel('Width_y [mm]','FontWeight','Bold','FontSize',fs);
% axis tight; set(gca,'FontWeight','Bold','FontSize',fs-1);
% set(gcf,'PaperUnits','inches','PaperPosition',[0 0 26 23])
% title('M24-1x30Gy (day 0^-)')%('
% xticklabels([0,3,6])
% yticklabels([0,3,6])
% title(['1x30Gy (day 14)'])%('
% saveas(gcf,'M29-1x30Gy (day 14).png')
end
