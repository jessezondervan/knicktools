function stream_profiler(poly, DEM, stream_objects, identifier, output_location, ...
    knickpoints, proj_data, export_options)
    
    % Export options
    % export_options(1) = knickpoint text
    % export_options(2) = Ksn data
    % export_options(3) = Ksn shapefile
    % export_options(4) = Plots
    
    % SETTINGS

    stream_pixel_threshold = 300; % pixels

    n_slope_area_bins = 100;

    aggregrate_ksn_length = 1000; % metres (must be greater than S.cellsize*3)
        
    % Output matrices

    c_ID = identifier;

    [r,c] = coord2sub(DEM,poly.X,poly.Y);

    %Remove NaNs
    n = find(isnan(r));
    r(n) = [];
    c(n) = [];
    
    % Export knickpoints to text file
    if export_options(1)
        fname = [output_location ,filesep, 'test','_knickpoints.txt'];
        x = knickpoints(:,1);
        y = knickpoints(:,2);
        z = knickpoints(:,6);
        writetable(table(x,y,z),[output_location, '/', 'test.csv']);
    end

    FD = FLOWobj(DEM, 'preprocess','carve');
    cDEM = imposemin(FD,DEM,0.0001);

    % Flow Accumulation
    A = flowacc(FD);

    X = 42.0;                  %# A3 paper size
    Y = 29.7;                  %# A3 paper size
    xMargin = 0;               %# left/right margins from page borders
    yMargin = 2;               %# bottom/top margins from page borders
    xSize = X - 2*xMargin;     %# figure size on paper (widht & hieght)
    ySize = Y - 2*yMargin;     %# figure size on paper (widht & hieght)

    % Gradients
    G   = gradient8(cDEM);
    
    for p=1:length(stream_objects)
        % Upstream area
        S = stream_objects(p);
        a = A.Z(S.IXgrid).*(A.cellsize).^2;

        % Binned slope area calc
        STATS = slopearea_ksn(S,cDEM,A, 'areabins', aggregrate_ksn_length, 'plot', false);

        % Localised KSN
        KSN = G./(A.*(A.cellsize^2)).^-.45;
        [x,y,ksn] = STREAMobj2XY(S,KSN);

        f = figure('Menubar','none');
        set(f,'visible','off');
        set(f, 'PaperSize',[X X]);
        set(f, 'PaperPosition',[0 xMargin xSize xSize])
        set(f, 'PaperUnits','centimeters');

        MS = STREAMobj2mapstruct(S,'seglength',aggregrate_ksn_length,'attributes',...
        {'ksn' KSN @mean 'uparea' (A.*(A.cellsize^2)) @mean 'gradient' G @mean});
        symbolspec = makesymbolspec('line',...
            {'ksn' [min([MS.ksn]) max([MS.ksn])] 'color' jet(6)});
        colorbar;
        imageschs(cDEM,cDEM,'colormap',gray,'colorbar',false);
        mapshow(MS,'SymbolSpec',symbolspec);
        caxis([min([MS.ksn]) max([MS.ksn])]);
        contourcbar;
        print(f,[output_location ,'/', 'test_',num2str(p),'_ksn_plot'], '-dpdf')

        shapewrite(MS, [output_location ,'/', 'test_',num2str(p),'_ksn.shp']);

        if export_options(3)
            % Write projection file
            fid = fopen([output_location ,'/', 'test_',num2str(p),'_ksn.prj'],'w');
            fprintf(fid,proj_data);
            fclose(fid);
        end

        if export_options(4)
            f = figure('Menubar','none');
            set(f,'visible','off');
            set(f, 'PaperSize',[X Y]);
            set(f, 'PaperPosition',[0 yMargin xSize ySize])
            set(f, 'PaperUnits','centimeters');

            sb1 = subplot(2,2,1);
            max_val = max(cDEM.Z(:));
            vdata = cDEM;
            vdata.Z(isnan(vdata.Z)) = max_val + max_val/10;
            imagesc(vdata);
            colormap bone;
            colorbar
            hold on;
            plot(S);
            title(['Catchment ', 'test']);

            subplot(2,2,2);
            SA = slopearea(S,cDEM,A);
            sa_values = {['\bf \theta', '\rm ',  num2str(SA.theta)], ...
                ['\bf ks ', '\rm ',  num2str(SA.ks)]
            };
            DataX = interp1( [0 1], xlim(), 0.01 );
            DataY = interp1( [0 1], ylim(), 0.01 );

            text(DataX,DataY,sa_values,'EdgeColor', 'black', 'FontSize', 14);

            title('Slope v Area');

            subplot(2,2,3);
            axis equal tight
            plot(S, 'k-', 'LineWidth', 2);
            title('River plan');

            subplot(2,2,4)
            axis normal
            plotdz(S,cDEM);
            title('Stream profile elevation');


            print(f,[output_location, '/', 'test_',num2str(p), '_plots'], '-dpdf')
        end
        
        ksn = ksn(1:end-1);
        local_slope = gradient(S, cDEM);
        distance = S.distance;
        x = S.x;
        y = S.y;
        upstream_area = a;
        elevation = cDEM.Z(S.IXgrid);

        if export_options(2)
            results = table(distance, x, y, elevation, local_slope, upstream_area, ksn);
            writetable(results,[output_location, '/', 'test_', num2str(p), '.csv']);
        end
    end
%     fid = fopen([output_location, '/catchment_averages_data.csv'],'w');
%     fprintf(fid,'%s\r\n','catchment,ksn,theta');
%     fclose(fid);

%     average_data = [c_IDs, c_KSN, thetas];
%     average_data = average_data(~any(isnan(average_data),2),:);
% 
%     dlmwrite([output_location, '/catchment_averages_data.csv'], average_data, '-append' ...
%         , 'delimiter', ',');    
end
  