
%for CZI files to parse from Zeiss
function [pos] = parse_czAnnotation(xml_files)
    xDoc = xmlread(fullfile(xml_files(1).folder, xml_files(1).name));
    theStruct = parseChildNodes(xDoc);
    num = ((length(theStruct.Children)-1)/2);
    for idx = 1:num
        rnum=idx*2;
    %for each rectangle
    X = round(str2double(theStruct.Children(4).Children(rnum).Children(6).Children(2).Children.Data));
    Y = round(str2double(theStruct.Children(4).Children(rnum).Children(6).Children(4).Children.Data));
    width = round(str2double(theStruct.Children(4).Children(rnum).Children(6).Children(6).Children.Data));
    height = round(str2double(theStruct.Children(4).Children(rnum).Children(6).Children(8).Children.Data));
    pos{idx} = [X, Y, width, height];
    end
end

