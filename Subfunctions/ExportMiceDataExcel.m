function ExportMiceDataExcel
% Based on https://www.mathworks.com/matlabcentral/answers/158415-saving-a-structure-to-excel
% https://www.mathworks.com/matlabcentral/answers/409104-convert-a-struct-to-excel-file
DirectoryVesselsData ='H:\SBRT project March-June 2021'
GrossResponseDir=fullfile(DirectoryVesselsData,'GrossResponseMetrics');
MiceTumourResponseDataFile=fullfile(GrossResponseDir,'LongitudinalGrossTumourResponseMetrics.mat');
        if exist(MiceTumourResponseDataFile,'file')
            load(MiceTumourResponseDataFile);
        end











% a.b.c.d = rand(16,1);
% a.b.c.e = rand(16,1);
% my_last_field = fieldnames(a.b.c);
% % write the last field values in a single matrix
% L = numel(my_last_field);
% my_data = zeros(16,L);
% for k=1:L
%     my_data(:,k) = a.b.c.(my_last_field{k});
% end
% % write the matrix to excell sheet
% xlswrite('text.xls',my_data)

