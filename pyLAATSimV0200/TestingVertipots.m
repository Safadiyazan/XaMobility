function [] = TestingVertipots()
Vertiports = [
    -73.98440300426283, 40.77275113399261, 20.89627363010538;
    -73.96773955133848, 40.75007173649506, 4.318934694714676;
    -73.98427004394215, 40.72990870353391, -15.521595383896994;
    -73.99687660760746, 40.724604427122294, 28.434851429241917;
];

[E, N, U, refPoint] = calculateEnuWithCenterRef(Vertiports);

% Display the results
disp('E:');
disp(E);
disp('N:');
disp(N);
disp('U:');
disp(U);
disp('Reference Point (Center):');
disp(refPoint);

figure;
plot3(E,N,U,'.')
end

function [E, N, U, refPoint] = calculateEnuWithCenterRef(vertiports)
    % Earth radius and flattening
    a = 6378137.0; % Semi-major axis
    f = 1 / 298.257223563; % Flattening
    b = a * (1 - f); % Semi-minor axis

    % Step 1: Initial calculation using the first vertiport as reference point
    initialRefPoint = vertiports(1, :);
    [E, N, U] = llhToEnu(vertiports, initialRefPoint, a, b);

    % Step 2: Find max and min in E and N directions
    maxE = max(E);
    minE = min(E);
    maxN = max(N);
    minN = min(N);

    % Step 3: Calculate the center point in ENU space
    centerE = (maxE + minE) / 2;
    centerN = (maxN + minN) / 2;
    
    % Convert the center point back to latitude and longitude
    refLat = vertiports(1, 2);
    refLon = vertiports(1, 1);
    refH = vertiports(1, 3);
    
    % Reference point in ECEF coordinates
    [x0, y0, z0] = llhToEcef(refLat, refLon, refH, a, b);
    
    % Convert the ENU center point to ECEF
    [centerX, centerY, centerZ] = enuToEcef(centerE, centerN, 0, x0, y0, z0, refLat, refLon);
    
    % Convert the ECEF center point to LLH
    [centerLat, centerLon, centerH] = ecefToLlh(centerX, centerY, centerZ, a, b);
    refPoint = [centerLon, centerLat, centerH];

    % Step 4: Recalculate ENU coordinates with the new center reference point
    [E, N, U] = llhToEnu(vertiports, refPoint, a, b);
end

function [x, y, z] = llhToEcef(lat, lon, h, a, b)
    % Convert latitude and longitude to radians
    lat = deg2rad(lat);
    lon = deg2rad(lon);

    % Calculate the radius of curvature in the prime vertical
    N = a / sqrt(1 - (a^2 - b^2) / a^2 * sin(lat)^2);

    % Calculate ECEF coordinates
    x = (N + h) * cos(lat) * cos(lon);
    y = (N + h) * cos(lat) * sin(lon);
    z = (b^2 / a^2 * N + h) * sin(lat);
end

function [E, N, U] = llhToEnu(vertiports, refPoint, a, b)
    % Reference point
    lat0 = refPoint(2);
    lon0 = refPoint(1);
    h0 = refPoint(3);

    % Convert reference point to ECEF coordinates
    [x0, y0, z0] = llhToEcef(lat0, lon0, h0, a, b);

    % Preallocate arrays
    E = zeros(size(vertiports, 1), 1);
    N = zeros(size(vertiports, 1), 1);
    U = zeros(size(vertiports, 1), 1);
    
    % Calculate ENU coordinates
    for i = 1:size(vertiports, 1)
        lat = vertiports(i, 2);
        lon = vertiports(i, 1);
        h = vertiports(i, 3);

        % Convert current point to ECEF coordinates
        [x, y, z] = llhToEcef(lat, lon, h, a, b);

        % Transform to ENU coordinates
        [e, n, u] = ecefToEnu(x, y, z, x0, y0, z0, lat0, lon0);
        
        E(i) = e;
        N(i) = n;
        U(i) = u;
    end
end

function [E, N, U] = ecefToEnu(x, y, z, x0, y0, z0, lat0, lon0)
    % Convert reference latitude and longitude to radians
    lat0 = deg2rad(lat0);
    lon0 = deg2rad(lon0);

    % Calculate differences in coordinates
    dx = x - x0;
    dy = y - y0;
    dz = z - z0;

    % Calculate the ENU coordinates
    E = -sin(lon0) * dx + cos(lon0) * dy;
    N = -sin(lat0) * cos(lon0) * dx - sin(lat0) * sin(lon0) * dy + cos(lat0) * dz;
    U = cos(lat0) * cos(lon0) * dx + cos(lat0) * sin(lon0) * dy + sin(lat0) * dz;
end

function [x, y, z] = enuToEcef(e, n, u, x0, y0, z0, lat0, lon0)
    % Convert reference latitude and longitude to radians
    lat0 = deg2rad(lat0);
    lon0 = deg2rad(lon0);

    % Calculate the ECEF coordinates from ENU
    x = -sin(lon0) * e - sin(lat0) * cos(lon0) * n + cos(lat0) * cos(lon0) * u + x0;
    y = cos(lon0) * e - sin(lat0) * sin(lon0) * n + cos(lat0) * sin(lon0) * u + y0;
    z = cos(lat0) * n + sin(lat0) * u + z0;
end

function [lat, lon, h] = ecefToLlh(x, y, z, a, b)
    % Calculate latitude, longitude, and height from ECEF coordinates
    ep = sqrt((a^2 - b^2) / b^2);
    p = sqrt(x^2 + y^2);
    th = atan2(a * z, b * p);
    lon = atan2(y, x);
    lat = atan2((z + ep^2 * b * sin(th)^3), (p - (a^2 - b^2) / a^2 * cos(th)^3));
    N = a / sqrt(1 - (a^2 - b^2) / a^2 * sin(lat)^2);
    h = p / cos(lat) - N;

    % Convert latitude and longitude from radians to degrees
    lat = rad2deg(lat);
    lon = rad2deg(lon);
end
