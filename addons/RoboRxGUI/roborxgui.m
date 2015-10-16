function roborxgui()
% RoboRX GUI

f = openfig('robofig.fig');
hdl = guihandles(f);
set(hdl.b_on,'Callback',@on);
set(hdl.b_off,'Callback',@off);
set([hdl.s_xi;hdl.s_xq;hdl.s_yi;hdl.s_yq],'Callback',@gain_slide);
set([hdl.c_shx;hdl.c_shy],'Callback',@shutdown);
set(hdl.c_power,'Callback',@monpow)
set([hdl.r_auto;hdl.r_manual],'Callback',@gainmode)
end

function on(obj,~)
    hdl = guihandles(obj);
    dishdl = [hdl.c_xi; hdl.s_xi; hdl.c_shx; hdl.s_xq; hdl.c_xq; ...
              hdl.c_yi; hdl.s_yi; hdl.c_shy; hdl.s_yq; hdl.c_yq; hdl.b_off];
    set(dishdl,'Enable','on');    
    set(hdl.b_on,'Enable','off');
    
end

function off(obj,~)    
    hdl = guihandles(obj);
    dishdl = [hdl.c_xi; hdl.s_xi; hdl.c_shx; hdl.s_xq; hdl.c_xq; ...
              hdl.c_yi; hdl.s_yi; hdl.c_shy; hdl.s_yq; hdl.c_yq; hdl.b_off];
    set(dishdl,'Enable','off');
    
    
    set(hdl.b_on,'Enable','on');
end

function gain_slide(obj,~)
    hdl = guihandles(obj);
    switch obj
        case hdl.s_xi
            lock = get(hdl.c_xi,'Value');
        case hdl.s_xq
            lock = get(hdl.c_xq,'Value');
        case hdl.s_yi
            lock = get(hdl.c_yi,'Value');
        case hdl.s_yq
            lock = get(hdl.c_yq,'Value');
    end
    if lock
        if ~get(hdl.r_auto,'Value')
            locked = [get(hdl.c_xi,'Value') get(hdl.c_xq,'Value') ...
                      get(hdl.c_yi,'Value') get(hdl.c_yq,'Value')];
            hslides = [hdl.s_xi hdl.s_xq hdl.s_yi hdl.s_yq];
        elseif lock
            locked = [get(hdl.c_xi,'Value') get(hdl.c_yi,'Value')];
            hslides = [hdl.s_xi hdl.s_yi];
        end
        pos = get(obj,'Value');
        set(hslides(find(locked)),'Value',pos);
    end
    set([hdl.e_xi;],'String',[num2str(get(hdl.s_xi,'Value'),'%1.2f') ' V']);
    set([hdl.e_xq;],'String',[num2str(get(hdl.s_xq,'Value'),'%1.2f') ' V']);
    set([hdl.e_yi;],'String',[num2str(get(hdl.s_yi,'Value'),'%1.2f') ' V']);
    set([hdl.e_yq;],'String',[num2str(get(hdl.s_yq,'Value'),'%1.2f') ' V']); 
end

function shutdown(obj,~)
    hdl = guihandles(obj);
    switch obj
        case hdl.c_shx
            hdls = [hdl.c_xi;hdl.s_xi;hdl.x_xi;hdl.c_xq;hdl.s_xq;hdl.x_xq];
        case hdl.c_shy
            hdls = [hdl.c_yi;hdl.s_yi;hdl.x_yi;hdl.c_yq;hdl.s_yq;hdl.x_yq];
    end
    if get(obj,'Value') == 1
        set(hdls,'Enable','off')
    else
        set(hdls,'Enable','on')
    end
end

function monpow(obj,~)
    hdl = guihandles(obj);
    if get(obj,'Value')
        set(hdl.e_time,'Enable','on')
        pos = get(hdl.f_main,'Position');
        pos(3) = 680;
        set(hdl.f_main,'Position',pos);
    else
        set(hdl.e_time,'Enable','off')
        pos = get(hdl.f_main,'Position');
        pos(3) = 300;
        set(hdl.f_main,'Position',pos);
    end
end

function viewlog(obj,~)
    hdl = guihandles(obj);
    if get(obj,'Value')
        pos = get(hdl.f_main,'Position');
        pos(4) = 600;
        set(hdl.f_main,'Position',pos);
    else
        set(hdl.e_time,'Enable','off')
        pos = get(hdl.f_main,'Position');
        pos(4) = 420;
        set(hdl.f_main,'Position',pos);
    end
end

function gainmode(obj,~)
    set(obj,'Value',1);
    hdl = guihandles(obj);
    if get(hdl.r_auto,'Value')
        set([hdl.c_xq;hdl.x_xq;hdl.s_xq;hdl.e_xq;...
             hdl.c_yq;hdl.x_yq;hdl.s_yq;hdl.e_yq],'Visible','off');
        set(hdl.x_xi,'String','OAX');
        set(hdl.x_yi,'String','OAY');
        set([hdl.s_xi;hdl.s_yi],'Value',0.5,'Min',0.5,'Max',2);
        set([hdl.e_xi;],'String',[num2str(get(hdl.s_xi,'Value'),'%1.2f') ' V']);
        set([hdl.e_yi;],'String',[num2str(get(hdl.s_yi,'Value'),'%1.2f') ' V']);
    else
        set([hdl.c_xq;hdl.x_xq;hdl.s_xq;hdl.e_xq;...
             hdl.c_yq;hdl.x_yq;hdl.s_yq;hdl.e_yq],'Visible','on');
        set(hdl.x_xi,'String','X-I');
        set(hdl.x_yi,'String','Y-I');
        set([hdl.s_xi;hdl.s_yi],'Value',0,'Min',0,'Max',3.3);
        set([hdl.e_xi;],'String',[num2str(get(hdl.s_xi,'Value'),'%1.2f') ' V']);
        set([hdl.e_yi;],'String',[num2str(get(hdl.s_yi,'Value'),'%1.2f') ' V']);
    end
end
        
         

        