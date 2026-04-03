function ImageEnhancementApp()

clc; close all;

%% ---- Main Figure
fig = uifigure('Name','Smart Image Enhancement ', ...
    'Position',[80 60 1150 720], ...
    'Color',[0.96 0.96 0.98], 'Resize','off');

%% ---- Top Bar
topBar = uipanel(fig,'Position',[0 682 1150 38],'BackgroundColor',[0.13 0.37 0.64],'BorderType','none');
uilabel(topBar,'Text','  Smart Image Enhancement & Analysis System  ', ...
    'Position',[0 6 800 24],'FontSize',13,'FontWeight','bold','FontColor',[1 1 1]);
uilabel(topBar,'Text','Mafaza Batool ','Position',[950 6 190 24], ...
    'FontSize',11,'FontColor',[0.8 0.9 1],'HorizontalAlignment','right');

%% ---- Left Panel
lp = uipanel(fig,'Position',[8 8 270 670],'BackgroundColor',[1 1 1], ...
    'BorderType','line','HighlightColor',[0.85 0.85 0.88]);

uilabel(lp,'Text','LOAD IMAGE','Position',[12 630 240 16], ...
    'FontSize',9,'FontWeight','bold','FontColor',[0.5 0.5 0.6]);

uibutton(lp,'push','Text','Browse / Load Image', ...
    'Position',[12 598 246 30],'FontSize',12,'FontWeight','bold', ...
    'BackgroundColor',[0.13 0.37 0.64],'FontColor',[1 1 1], ...
    'ButtonPushedFcn',@loadImage);

infoBox = uitextarea(lp,'Position',[12 520 246 72],'Editable','off', ...
    'FontSize',9,'FontName','Courier New','BackgroundColor',[0.97 0.97 0.99], ...
    'Value',{'No image loaded...','','JPG, PNG, BMP, TIF supported'});

uilabel(lp,'Text','SELECT PHASES','Position',[12 492 240 16], ...
    'FontSize',9,'FontWeight','bold','FontColor',[0.5 0.5 0.6]);

phLabels = {'Phase 1: Acquisition & Analysis', ...
            'Phase 2: Sampling & Quantization', ...
            'Phase 3: Geometric Transforms', ...
            'Phase 4: Intensity Transforms', ...
            'Phase 5: Histogram Processing', ...
            'Phase 6: Final Integration'};
phChecks = gobjects(6,1);
yy = [462 432 402 372 342 312];
for k = 1:6
    phChecks(k) = uicheckbox(lp,'Text',phLabels{k}, ...
        'Position',[12 yy(k) 246 22],'FontSize',10,'Value',1,'FontColor',[0.15 0.15 0.2]);
end

uibutton(lp,'push','Text','Select All','Position',[12 280 120 24], ...
    'FontSize',10,'ButtonPushedFcn',@(~,~)setAll(1));
uibutton(lp,'push','Text','Deselect All','Position',[138 280 120 24], ...
    'FontSize',10,'ButtonPushedFcn',@(~,~)setAll(0));

uilabel(lp,'Text','RUN','Position',[12 250 240 16], ...
    'FontSize',9,'FontWeight','bold','FontColor',[0.5 0.5 0.6]);

runBtn = uibutton(lp,'push','Text','Run Pipeline', ...
    'Position',[12 216 246 32],'FontSize',12,'FontWeight','bold', ...
    'BackgroundColor',[0.07 0.62 0.35],'FontColor',[1 1 1], ...
    'Enable','off','ButtonPushedFcn',@runPipeline);

saveBtn = uibutton(lp,'push','Text','Save All Results', ...
    'Position',[12 178 246 30],'FontSize',11,'FontWeight','bold', ...
    'BackgroundColor',[0.95 0.95 0.95],'FontColor',[0.2 0.2 0.2], ...
    'Enable','off','ButtonPushedFcn',@saveResults);

progLabel = uilabel(lp,'Text','Ready.','Position',[12 152 246 20], ...
    'FontSize',10,'FontColor',[0.4 0.4 0.5]);

uilabel(lp,'Text','LOG','Position',[12 128 200 16], ...
    'FontSize',9,'FontWeight','bold','FontColor',[0.5 0.5 0.6]);
logArea = uitextarea(lp,'Position',[12 8 246 116],'Editable','off', ...
    'FontSize',9,'FontName','Courier New', ...
    'BackgroundColor',[0.05 0.05 0.08],'FontColor',[0.4 1 0.6], ...
    'Value',{''});

%% ---- Image Axes (top right)
axOrig = uiaxes(fig,'Position',[290 390 270 280]); axis(axOrig,'off');
title(axOrig,'Original','FontSize',10,'FontWeight','bold');
axGray = uiaxes(fig,'Position',[570 390 270 280]); axis(axGray,'off');
title(axGray,'Grayscale','FontSize',10,'FontWeight','bold');
axEnh  = uiaxes(fig,'Position',[850 390 290 280]); axis(axEnh,'off');
title(axEnh,'Enhanced Output','FontSize',10,'FontWeight','bold');

%% ---- Bottom Tab Group
tg = uitabgroup(fig,'Position',[290 8 850 375]);
t1 = uitab(tg,'Title','Phase Results');
t2 = uitab(tg,'Title','Histogram');
t3 = uitab(tg,'Title','Intensity Curves');
t4 = uitab(tg,'Title','Metrics Table');

resultArea = uitextarea(t1,'Position',[5 5 835 330],'Editable','off', ...
    'FontSize',10,'FontName','Courier New','BackgroundColor',[0.97 0.98 1], ...
    'Value',{'Run the pipeline to see results...'});

axHistOrig = uiaxes(t2,'Position',[10 10 400 320]);
title(axHistOrig,'Histogram - Original','FontSize',10);
axHistEq   = uiaxes(t2,'Position',[430 10 400 320]);
title(axHistEq,'Histogram - Equalized','FontSize',10);

axCurves = uiaxes(t3,'Position',[10 10 830 320]);
title(axCurves,'Intensity Transformation Curves','FontSize',10);

metricTbl = uitable(t4,'Position',[5 5 835 330], ...
    'ColumnName',{'Property','Value'},'ColumnWidth',{240,570},'FontSize',11, ...
    'Data',repmat({'—','—'},8,1));

%% ---- State
S.rgb  = [];
S.gray = [];

%% ================================================================
    function loadImage(~,~)
        [f,p] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp;*.tif','Images'},'Select Image');
        if isequal(f,0), return; end
        raw = imread(fullfile(p,f));
        if size(raw,3)==3
            S.rgb  = raw;
            S.gray = rgb2gray(raw);
        else
            S.gray = raw;
            S.rgb  = cat(3,raw,raw,raw);
        end
        imshow(S.rgb,  'Parent',axOrig); title(axOrig,'Original','FontSize',10,'FontWeight','bold');
        imshow(S.gray, 'Parent',axGray); title(axGray,'Grayscale','FontSize',10,'FontWeight','bold');
        [r,c,ch] = size(S.rgb);
        infoBox.Value = {
            sprintf('File : %s',f)
            sprintf('Size : %d x %d  |  Ch: %d',c,r,ch)
            sprintf('Type : %s',class(S.rgb))
            sprintf('Mean : %.1f  Std : %.1f', ...
                mean(double(S.gray(:))),std(double(S.gray(:))))
        };
        runBtn.Enable = 'on';
        addLog(sprintf('Loaded: %s [%dx%d]',f,c,r));
        progLabel.Text = 'Image ready. Press Run.';
    end

%% ================================================================
    function runPipeline(~,~)
        if isempty(S.rgb), uialert(fig,'Load an image first.','No Image'); return; end
        runBtn.Enable  = 'off';
        saveBtn.Enable = 'off';
        logArea.Value  = {''};
        logs = {};
        g = double(S.gray);
        [rows,cols,~] = size(S.rgb);

        %% Phase 1
        if phChecks(1).Value
            setP('Phase 1: Acquisition...');
            logs{end+1} = '=== PHASE 1: Acquisition & Analysis ===';
            logs{end+1} = sprintf('  Resolution : %d x %d px', cols, rows);
            logs{end+1} = sprintf('  Data type  : %s', class(S.rgb));
            logs{end+1} = sprintf('  Min / Max  : %d / %d', min(S.gray(:)), max(S.gray(:)));
            logs{end+1} = sprintf('  Mean       : %.2f', mean(g(:)));
            logs{end+1} = sprintf('  Std Dev    : %.2f', std(g(:)));
            logs{end+1} = '  Partial matrix (top-left 4x4):';
            pm = double(S.gray(1:min(4,rows), 1:min(4,cols)));
            for rr=1:size(pm,1)
                logs{end+1} = sprintf('    %s', sprintf('%6.0f ',pm(rr,:)));
            end
            addLog('[1] Acquisition done');
        end

        %% Phase 2
        if phChecks(2).Value
            setP('Phase 2: Sampling & Quantization...');
            logs{end+1} = '';
            logs{end+1} = '=== PHASE 2: Sampling & Quantization ===';
            scales = [0.25 0.5 1.0 1.5 2.0];
            for k=1:numel(scales)
                rs = imresize(S.gray, scales(k));
                [r2,c2] = size(rs);
                logs{end+1} = sprintf('  Scale %.2fx  =>  %d x %d px', scales(k),c2,r2);
            end
            for b=[8 4 2]
                logs{end+1} = sprintf('  %d-bit => %d gray levels', b, 2^b);
            end
            addLog('[2] Sampling done');
        end

        %% Phase 3
        if phChecks(3).Value
            setP('Phase 3: Geometric Transforms...');
            logs{end+1} = '';
            logs{end+1} = '=== PHASE 3: Geometric Transformations ===';
            logs{end+1} = '  Rotations: 30,45,60,90,120,150,180 + inverse each';
            logs{end+1} = '  Translation: tx=30, ty=20 + inverse';
            logs{end+1} = '  Shearing: shx=0.3 + inverse';
            logs{end+1} = '  (Displayed in saved figures via Save button)';
            addLog('[3] Transforms logged');
        end

        %% Phase 4
        if phChecks(4).Value
            setP('Phase 4: Intensity Transforms...');
            cv  = 255/log(1+255);
            r_  = 0:255;
            cla(axCurves);
            plot(axCurves,r_,r_,              'k--','LineWidth',1.2,'DisplayName','Identity'); hold(axCurves,'on');
            plot(axCurves,r_,255-r_,           'r-', 'LineWidth',1.5,'DisplayName','Negative');
            plot(axCurves,r_,cv*log(1+r_),     'b-', 'LineWidth',1.5,'DisplayName','Log');
            plot(axCurves,r_,255*(r_/255).^0.5,'g-', 'LineWidth',1.5,'DisplayName','Gamma=0.5');
            plot(axCurves,r_,255*(r_/255).^1.5,'m-', 'LineWidth',1.5,'DisplayName','Gamma=1.5');
            hold(axCurves,'off');
            legend(axCurves,'show','Location','northwest');
            xlabel(axCurves,'Input Intensity'); ylabel(axCurves,'Output Intensity');
            title(axCurves,'Phase 4: Intensity Transformation Curves','FontSize',10,'FontWeight','bold');
            grid(axCurves,'on');

            neg = uint8(255-g); lg=uint8(cv*log(1+g));
            g05=uint8(255*(g/255).^0.5); g15=uint8(255*(g/255).^1.5);
            logs{end+1} = '';
            logs{end+1} = '=== PHASE 4: Intensity Transformations ===';
            logs{end+1} = sprintf('  Original mean  : %.1f', mean(g(:)));
            logs{end+1} = sprintf('  Negative mean  : %.1f', mean(double(neg(:))));
            logs{end+1} = sprintf('  Log mean       : %.1f', mean(double(lg(:))));
            logs{end+1} = sprintf('  Gamma 0.5 mean : %.1f', mean(double(g05(:))));
            logs{end+1} = sprintf('  Gamma 1.5 mean : %.1f', mean(double(g15(:))));
            logs{end+1} = '  Best brightening : Gamma = 0.5';
            logs{end+1} = '  Best detail      : Log Transform';
            addLog('[4] Intensity done');
        end

     %% Phase 5: Histogram Processing (Fixed for App)
if phChecks(5).Value
    setP('Phase 5: Histogram Processing...');
    eq = histeq(S.gray);
    
    % --- Clear existing plots in the UI axes ---
    cla(axHistOrig); 
    cla(axHistEq);

    % --- Plot Original Histogram inside the app ---
    % We use 'histogram' which is built for UIAxes
    histogram(axHistOrig, S.gray, 'BinEdges', 0:4:256, 'FaceColor', [0.2 0.4 0.6], 'EdgeColor', 'none');
    title(axHistOrig, 'Histogram - Original', 'FontSize', 10, 'FontWeight', 'bold');
    axHistOrig.XLim = [0 255];

    % --- Plot Equalized Histogram inside the app ---
    histogram(axHistEq, eq, 'BinEdges', 0:4:256, 'FaceColor', [0.1 0.6 0.3], 'EdgeColor', 'none');
    title(axHistEq, 'Histogram - Equalized', 'FontSize', 10, 'FontWeight', 'bold');
    axHistEq.XLim = [0 255];

    % Statistics for logs
    sb = std(double(S.gray(:))); 
    sa = std(double(eq(:)));
    logs{end+1} = '';
    logs{end+1} = '=== PHASE 5: Histogram Processing ===';
    logs{end+1} = sprintf('  Std before HE : %.2f', sb);
    logs{end+1} = sprintf('  Std after HE  : %.2f', sa);
    logs{end+1} = sprintf('  Contrast gain : +%.2f', sa-sb);
    addLog('[5] Histogram done');
end
        %% Phase 6
        if phChecks(6).Value
            setP('Phase 6: Final Pipeline...');
            enh = fastPipeline(S.rgb);
            imshow(enh,'Parent',axEnh);
            title(axEnh,'Enhanced Output','FontSize',10,'FontWeight','bold');

            eq2 = histeq(S.gray);
            [r2,c2,ch2] = size(S.rgb);
            metricTbl.Data = {
                'Resolution',          sprintf('%d x %d px', c2, r2);
                'Color channels',      sprintf('%d', ch2);
                'Data type',           class(S.rgb);
                'Mean intensity',      sprintf('%.2f', mean(g(:)));
                'Std deviation',       sprintf('%.2f', std(g(:)));
                'Min / Max',           sprintf('%d / %d', min(S.gray(:)), max(S.gray(:)));
                'Contrast before HE',  sprintf('%.2f', std(g(:)));
                'Contrast after HE',   sprintf('%.2f', std(double(eq2(:))));
                'Pipeline steps',      'Gamma(0.6) > HE > Log > Unsharp';
                'Output',              'Use Save button to export';
            };

            logs{end+1} = '';
            logs{end+1} = '=== PHASE 6: Final Integration ===';
            logs{end+1} = '  Pipeline: Gamma(0.6) > HE > Log > Unsharp';
            logs{end+1} = '  enhanced = process_image(input_image)';
            logs{end+1} = '  Use Save button to export results.';
            addLog('[6] Enhancement done');
        end

        resultArea.Value = logs;
        progLabel.Text   = 'Done! Use Save button to export.';
        saveBtn.Enable   = 'on';
        runBtn.Enable    = 'on';
        addLog('=== PIPELINE COMPLETE ===');
        tg.SelectedTab   = t1;
    end

%% ================================================================
    function enhanced = fastPipeline(rgb)
        gamma_ = 0.6;
        c_     = 255/log(1+255);
        enhanced = zeros(size(rgb),'uint8');
        for ch = 1:3
            d   = double(rgb(:,:,ch));
            gam = 255*(d/255).^gamma_;
            eq_ = double(histeq(uint8(gam)));
            lg_ = c_*log(1+d);
            bl  = uint8(0.65*eq_ + 0.35*lg_);
            enhanced(:,:,ch) = imsharpen(bl,'Radius',1.2,'Amount',0.7);
        end
    end

%% ================================================================
    function saveResults(~,~)
        if isempty(S.rgb), return; end
        if ~exist('results','dir'),       mkdir('results');        end
        if ~exist('images/output','dir'), mkdir('images/output'); end
        setP('Saving... please wait');

        enh = fastPipeline(S.rgb);
        imwrite(enh,'images/output/enhanced_output.jpg');

        f = figure('Visible','off');

        % Phase 1
        subplot(1,2,1); imshow(S.rgb);  title('Original RGB');
        subplot(1,2,2); imshow(S.gray); title('Grayscale');
        sgtitle('Phase 1: Acquisition'); saveas(f,'results/phase1.png');

        % Phase 2 sampling
        clf(f); scales=[0.25 0.5 1 1.5 2];
        for k=1:5
            rs=imresize(S.gray,scales(k)); re=imresize(rs,size(S.gray));
            subplot(2,5,k);   imshow(rs); title(sprintf('%.2fx',scales(k)));
            subplot(2,5,k+5); imshow(re); title('Restored');
        end
        sgtitle('Phase 2: Sampling'); saveas(f,'results/phase2_sampling.png');

        % Phase 2 quantization
        clf(f);
        subplot(1,4,1); imshow(S.gray); title('8-bit original');
        for k=1:3, b=[8 4 2]; lev=2^b(k);
            q=uint8(round(double(S.gray)/255*(lev-1))/(lev-1)*255);
            subplot(1,4,k+1); imshow(q); title(sprintf('%d-bit',b(k)));
        end
        sgtitle('Phase 2: Quantization'); saveas(f,'results/phase2_quantization.png');

        % Phase 3
        clf(f); angles=[30 45 60 90 120 150 180];
        [rows,cols,~]=size(S.rgb);
        for k=1:7
            rot=imrotate(S.gray,angles(k),'bilinear','crop');
            inv=imrotate(rot,-angles(k),'bilinear','crop');
            subplot(2,7,k);   imshow(rot); title(sprintf('%d',angles(k)));
            subplot(2,7,k+7); imshow(inv); title(sprintf('Inv'));
        end
        sgtitle('Phase 3: Rotation'); saveas(f,'results/phase3_rotation.png');

        clf(f);
        tx=30;ty=20;shx=0.3;
        T=affine2d([1 0 0;0 1 0;tx ty 1]);
        Ti=affine2d([1 0 0;0 1 0;-tx -ty 1]);
        S_=affine2d([1 0 0;shx 1 0;0 0 1]);
        Si=affine2d([1 0 0;-shx 1 0;0 0 1]);
        tr=imwarp(S.gray,T,'OutputView',imref2d([rows cols]));
        ti=imwarp(tr,Ti,'OutputView',imref2d([rows cols]));
        sh=imwarp(S.gray,S_,'OutputView',imref2d([rows cols]));
        si2=imwarp(sh,Si,'OutputView',imref2d([rows cols]));
        subplot(2,3,1);imshow(S.gray);title('Original');
        subplot(2,3,2);imshow(tr);title('Translated');
        subplot(2,3,3);imshow(ti);title('Inv Trans');
        subplot(2,3,4);imshow(S.gray);title('Original');
        subplot(2,3,5);imshow(sh);title('Sheared');
        subplot(2,3,6);imshow(si2);title('Inv Shear');
        sgtitle('Phase 3: Translation & Shearing');
        saveas(f,'results/phase3_trans_shear.png');

        % Phase 4
        clf(f); g=double(S.gray); cv=255/log(1+255);
        neg=uint8(255-g); lg=uint8(cv*log(1+g));
        g05=uint8(255*(g/255).^0.5); g15=uint8(255*(g/255).^1.5);
        subplot(2,3,1);imshow(S.gray);title('Original');
        subplot(2,3,2);imshow(neg);title('Negative');
        subplot(2,3,3);imshow(lg);title('Log');
        subplot(2,3,4);imshow(g05);title('Gamma=0.5');
        subplot(2,3,5);imshow(g15);title('Gamma=1.5');
        subplot(2,3,6);
        bar([mean(g(:)),mean(double(neg(:))),mean(double(lg(:))),mean(double(g05(:))),mean(double(g15(:)))]);
        set(gca,'XTickLabel',{'Orig','Neg','Log','g0.5','g1.5'});
        ylabel('Mean Intensity'); title('Comparison');
        sgtitle('Phase 4: Intensity Transforms');
        saveas(f,'results/phase4_intensity.png');

        % Phase 5
        clf(f); eq=histeq(S.gray);
        subplot(2,2,1);imshow(S.gray);title('Original');
        subplot(2,2,2);imshow(eq);title('Equalized');
        subplot(2,2,3);imhist(S.gray,64);title('Hist Original');
        subplot(2,2,4);imhist(eq,64);title('Hist Equalized');
        sgtitle('Phase 5: Histogram Processing');
        saveas(f,'results/phase5_histogram.png');

        % Phase 6
        clf(f);
        subplot(1,2,1);imshow(S.rgb);title('Input');
        subplot(1,2,2);imshow(enh);title('Enhanced');
        sgtitle('Phase 6: Final Output');
        saveas(f,'results/phase6_final.png');

        close(f);
        progLabel.Text = 'All results saved!';
        addLog('Saved: results/ and images/output/');
        uialert(fig, ...
            sprintf('Saved:\n- results/phase1-6 .png\n- images/output/enhanced_output.jpg'), ...
            'Save Complete','Icon','success');
    end

%% ================================================================
    function setP(msg)
        progLabel.Text = msg; drawnow limitrate;
    end
    function addLog(msg)
        v = logArea.Value;
        if numel(v)==1 && isempty(v{1}), logArea.Value={msg};
        else, logArea.Value=[v;{msg}]; end
        drawnow limitrate;
    end
    function setAll(val)
        for i=1:6, phChecks(i).Value=val; end
    end

end
