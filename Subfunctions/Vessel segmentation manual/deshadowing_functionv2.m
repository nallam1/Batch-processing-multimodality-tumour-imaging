function [ D ] = deshadowing_functionv2( B, Depth,deshadowing_para )
for j=1:Depth-1
    %multiply each depth by an exponential that is based on the value itself 
B(j+1:Depth,:)=B(j+1:Depth,:).*repmat(exp(-B(j,:)/2^deshadowing_para),Depth-j,1);
end
D=B;
end



% function [ D ] = deshadowing_function( B, Depth )
% for j=1:Depth-1
%     %multiply each depth by an exponential that is based on the value itself 
% B(j+1:Depth,:)=B(j+1:Depth,:).*repmat(exp(-B(j,:)/2^15),Depth-j,1);
% end
% D=B;
% end