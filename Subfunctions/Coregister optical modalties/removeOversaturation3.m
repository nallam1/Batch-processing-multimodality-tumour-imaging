function [Normalized_2DFrm_divided]= removeOversaturation3(Frm2D_divided,OSremoval)
%% by Nader A.
% Takes 2D frame divided into fringes and puts it into a vector (1D matrix), 
% extracting maximum intensity values as permitted and removing top 
% however much percent of pixels as determined by OSremoval
%,Normalization_factor,Numpix,NumPixToRemove,AscendingOrderCut
AscendingOrder=sort(Frm2D_divided(:));
Numpix=length(AscendingOrder);
NumPixToRemove=floor(length(AscendingOrder)*OSremoval);%to be removed from top
AscendingOrderCut=AscendingOrder(1:end-NumPixToRemove);
Normalization_factor=max(AscendingOrderCut);
if Normalization_factor~=0
    Normalized_2DFrm_divided=Frm2D_divided/Normalization_factor;
    Normalized_2DFrm_divided(Normalized_2DFrm_divided>1)=1;% over saturated pixels are now 1
else
  Normalized_2DFrm_divided=Frm2D_divided;
end

end