


function [xy]= parse_xml(xml_files)
    %read in xml doc for regions
    xDoc = xmlread(fullfile(xml_files(1).folder, xml_files(1).name));
    Regions =xDoc.getElementsByTagName('Region'); % get a list of all the region tags
    for regioni = 0:Regions.getLength-1
        Region=Regions.item(regioni);  % for each region tag
        %get a list of all the vertexes (which are in order)
        verticies= Region.getElementsByTagName('Vertex');
        xy{regioni+1}=zeros(verticies.getLength-1,2); %allocate space for them
        for vertexi = 0:verticies.getLength-1 %iterate through all verticies
            %get the x value of that vertex
            x=str2double(verticies.item(vertexi).getAttribute('X'));
            %get the y value of that vertex
            y=str2double(verticies.item(vertexi).getAttribute('Y'));
            xy{regioni+1}(vertexi+1,:)=[x,y]; % finally save them into the array
        end
    end        