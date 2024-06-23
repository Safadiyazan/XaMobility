function [TFC,ObjAircraft,SimInfo] = TCP_RouteGuidance(SimInfo,ObjAircraft,Settings,TFC,k)
dtC = SimInfo.dtC;
dtS = SimInfo.dtS;
t = SimInfo.t;
warning('Load MFD Ri')
warning('Add Route Sets and MFD-MPC Optimization')
if (k~=0)&&(mod(t,dtC)==0)&&(~isempty(TFC))
k = SimInfo.t/dtC;
%% Calculate the shortest path for each vehicle
[TFC,ObjAircraft,SimInfo] = ApplyRoutingControl(TFC,t,dtC,SimInfo,ObjAircraft,Settings);
end % End Routing Active Timing
end % End Function

function [TFC,ObjAircraft,SimInfo] = ApplyRoutingControl(TFC,t,dtC,SimInfo,ObjAircraft,Settings)
% TFC.CS(t/dtC).dtdepc = zeros(size(TFC.CS(t/dtC).udidt));
dtS = SimInfo.dtS;
LMque = size(SimInfo.Mque,2);
for aai=1:LMque
    if (t<=(ObjAircraft(SimInfo.Mque(aai)).tda)) && ((ObjAircraft(SimInfo.Mque(aai)).tda)<(t+dtC))
        [TFC,ObjAircraft,SimInfo] = CheckOptimalPath(TFC,t,dtC,SimInfo,ObjAircraft,Settings,SimInfo.Mque(aai));
    end
    aai = aai + 1;
end
InActiveAircraftID = SimInfo.Mina(all([( (t+dtS) < (cat(1,ObjAircraft(SimInfo.Mina).tda)) ) , ( (cat(1,ObjAircraft(SimInfo.Mina).tda)) < (t+dtC+dtS) )],2));
LMina = size(InActiveAircraftID,2);
aai = 1;
while aai<=LMina
    if (t<=(ObjAircraft(InActiveAircraftID(aai)).tda)) && ((ObjAircraft(InActiveAircraftID(aai)).tda)<(t+dtC))
        [TFC,ObjAircraft,SimInfo] = CheckOptimalPath(TFC,t,dtC,SimInfo,ObjAircraft,Settings,InActiveAircraftID(aai));
    end
    aai = aai + 1;
end
end

function [TFC,ObjAircraft,SimInfo] = CheckOptimalPath(TFC,t,dtC,SimInfo,ObjAircraft,Settings,aai)
    startNode = mod(ObjAircraft(aai).rio,Settings.Airspace.Regions.dzri);%ObjAircraft(aai).rio;
    endNode = mod(ObjAircraft(aai).rid,Settings.Airspace.Regions.dzri);%ObjAircraft(aai).rid;
    o_xyz = ObjAircraft(aai).o;
    d_xyz = ObjAircraft(aai).d;
    edgeWeights = CalculateedgeWeights(t/dtC,TFC,Settings,startNode,endNode,o_xyz,d_xyz);
    [dist,path] = dijkstraalgo(edgeWeights,startNode,endNode);
    if(size(path,2)>2)
%         ObjAircraft(aai).wpCR
%         ObjAircraft(aai).wp(ObjAircraft(aai).wpCR+1,:)
        if (ObjAircraft(aai).wpTR>2)
            startNodewpCR = 2;
        else
            startNodewpCR = 1;
        end
        for wpi=2:size(path,2)-1
            extranode = path(wpi);
            extranodeid = extranode + Settings.Airspace.Regions.dzri;
            NewWaypoint = Settings.Airspace.Regions.B(cat(1,Settings.Airspace.Regions.B.ri)==extranodeid).center;
            ObjAircraft(aai).wp = [ObjAircraft(aai).wp(1:startNodewpCR,:);NewWaypoint;ObjAircraft(aai).wp(startNodewpCR+1:end,:)];
            ObjAircraft(aai).wpTR = ObjAircraft(aai).wpTR + 1;
            startNodewpCR = startNodewpCR + 1;
            ObjAircraft(aai).wpChange = 1;
            ObjAircraft(aai).wpRouting = 1;
        end
    end
end

function [edgeWeights] = CalculateedgeWeights(k,TFC,Settings,startNode,endNode,o_xyz,d_xyz)
% Define the grid network
numNodes = Settings.Airspace.Regions.nxy;
Li = 1;
% Add edges to the network
adjMatrix = zeros(numNodes);
RiVdt = zeros(1,numNodes);
for i=1:numNodes
    for j=1:numNodes
        if ((Settings.Airspace.Regions.B(i).layer==Li)&&(Settings.Airspace.Regions.B(j).layer==Li))
            if i==startNode
%                 i_xyz = [o_xyz(1:2), Settings.Airspace.Regions.B(i).center(3)];
                i_xyz = o_xyz;
            else
                i_xyz = Settings.Airspace.Regions.B(i).center;
            end
            if j==endNode
%                 j_xyz = [d_xyz(1:2), Settings.Airspace.Regions.B(j).center(3)];
                j_xyz = d_xyz;
            else
                j_xyz = Settings.Airspace.Regions.B(j).center;
            end
            adjMatrix(i,j) = norm(i_xyz-j_xyz);
        end
    end
end
% Define the average speed in each node
RiV = cat(1,TFC.Ri.V);
RiVdt = RiV(cat(1,Settings.Airspace.Regions.B(:).layer)==Li,k);
RiVdt(isnan(RiVdt)) = Settings.Aircraft.vm_range(1);
nodeSpeeds = RiVdt;
% nodeSpeeds = ones(size(RiVdt));
% Calculate the travel time for each edge
edgeWeights = zeros(numNodes);
for i = 1:numNodes
    for j = 1:numNodes
            edgeWeights(i,j) = adjMatrix(i,j)/mean([nodeSpeeds(i),nodeSpeeds(j)]);
    end
end

end


function [dist, path] = dijkstraalgo(adjMatrix,startNode,endNode)
% Initialize the distance vector
numNodes = size(adjMatrix,1);
dist = inf(1,numNodes);
dist(startNode) = 0;
% Initialize the previous node vector
prev = zeros(1,numNodes);
% Initialize the unvisited set
unvisited = 1:numNodes;
while ~isempty(unvisited)
    % Find the unvisited node with the smallest distance
    [minDist, idx] = min(dist(unvisited));
    currNode = unvisited(idx);
    % Remove the current node from the unvisited set
    unvisited(idx) = [];
    % If we've reached the end node, terminate the algorithm
    if currNode == endNode
        break;
    end
    % Update the distances to the neighbors of the current node
    neighbors = find(adjMatrix(currNode,:));
    for i = 1:length(neighbors)
        neighbor = neighbors(i);
        altDist = dist(currNode) + adjMatrix(currNode,neighbor);
        if altDist < dist(neighbor)
            dist(neighbor) = altDist;
            prev(neighbor) = currNode;
        end
    end
end
% Build the shortest path from startNode to endNode
path = [];
currNode = endNode;
while currNode ~= startNode
    path = [currNode path];
    currNode = prev(currNode);
    if(size(path,2)>numNodes*2)%(nchoosek(numNodes,2)))
        path = endNode;
        break;
    end
end
path = [startNode path];
end