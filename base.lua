-- ACS Config Editor — standalone Matcha Drawing UI

local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")

local T = {
    bg =      Color3.fromRGB(13, 13, 15),
    surface = Color3.fromRGB(20, 20, 24),
    panel =   Color3.fromRGB(27, 27, 33),
    border =  Color3.fromRGB(48, 48, 60),
    accent =  Color3.fromRGB(99, 102, 241),
    accentHi= Color3.fromRGB(120, 123, 255),
    text =    Color3.fromRGB(235, 235, 240),
    sub =     Color3.fromRGB(130, 130, 148),
    success = Color3.fromRGB(52, 199, 89),
    warn =    Color3.fromRGB(255, 204, 0),
    err =     Color3.fromRGB(255, 69, 58),
    numCol =  Color3.fromRGB(150, 200, 255),
    boolCol = Color3.fromRGB(255, 160, 100),
    strCol =  Color3.fromRGB(150, 230, 150),
    cursor =  Color3.fromRGB(99, 102, 241),
}

local v2 = Vector2.new
local D = {}

local function Ln(id, x1, y1, x2, y2, color, thick, zi)
    if not D[id] then D[id] = Drawing.new("Line") end
    local d = D[id]
    d.From = v2(x1, y1); d.To = v2(x2, y2)
    d.Thickness = thick or 1; d.ZIndex = zi or 2; d.Visible = true
end
local function Box(id, x, y, w, h, color, zi)
    if not D[id] then D[id] = Drawing.new("Square") end
    local d = D[id]
    d.Position = v2(x, y); d.Size = v2(w, h)
    d.Color = color; d.Filled = true; d.ZIndex = zi or 1; d.Visible = true
end
local function Outline(id, x, y, w, h, color, zi)
    if not D[id] then D[id] = Drawing.new("Square") end
    local d = D[id]
    d.Position = v2(x, y); d.Size = v2(w, h)
    d.Color = color; d.Filled = false; d.ZIndex = zi or 2; d.Visible = true
end
local function Txt(id, x, y, str, color, size, zi, center)
    if not D[id] then D[id] = Drawing.new("Text") end
    local d = D[id]
    d.Position = v2(x, y); d.Text = tostring(str); d.Color = color
    d.Size = size or 13; d.Font = Drawing.Fonts.UI; d.Outline = false
    d.Center = center or false; d.ZIndex = zi or 3; d.Visible = true
end
local function hide(id) if D[id] then D[id].Visible = false end end
local function hidePrefix(p)
    for k, d in pairs(D) do if k:sub(1,#p)==p then d.Visible=false end end
end
local function tw(s, sz) return #s*(sz or 13)*0.535 end

local prevKeys = {}
local mouse = player:GetMouse()
local function getMouse() return v2(mouse.X, mouse.Y) end
local function inB(x,y,w,h) local m=getMouse(); return m.X>=x and m.X<=x+w and m.Y>=y and m.Y<=y+h end

local KEY_IDS = {
    m1=0x01,m2=0x02,backspace=0x08,tab=0x09,enter=0x0D,
    shift=0x10,lshift=0xA0,rshift=0xA1,
    left=0x25,up=0x26,right=0x27,down=0x28,
    pageup=0x21,pagedown=0x22,home=0x24,["end"]=0x23,space=0x20,
    ["0"]=0x30,["1"]=0x31,["2"]=0x32,["3"]=0x33,["4"]=0x34,
    ["5"]=0x35,["6"]=0x36,["7"]=0x37,["8"]=0x38,["9"]=0x39,
    a=0x41,b=0x42,c=0x43,d=0x44,e=0x45,f=0x46,g=0x47,h=0x48,
    i=0x49,j=0x4A,k=0x4B,l=0x4C,m=0x4D,n=0x4E,o=0x4F,p=0x50,
    q=0x51,r=0x52,s=0x53,t=0x54,u=0x55,v=0x56,w=0x57,x=0x58,
    y=0x59,z=0x5A,
    f1=0x70,f2=0x71,f3=0x72,f4=0x73,f5=0x74,f6=0x75,
    f7=0x76,f8=0x77,f9=0x78,f10=0x79,f11=0x7A,f12=0x7B,
    minus=0xBD,plus=0xBB,lbracket=0xDB,rbracket=0xDD,
    semicolon=0xBA,quote=0xDE,comma=0xBC,period=0xBE,
    slash=0xBF,backslash=0xDC,tilde=0xC0,
}
local charMap = {
    space=" ",minus="-",plus="=",lbracket="[",rbracket="]",
    semicolon=";",quote="'",comma=",",period=".",slash="/",
    backslash="\\",tilde="`",
}
local shiftMap = {
    ["1"]="!",["2"]="@",["3"]="#",["4"]="$",["5"]="%",["6"]="^",
    ["7"]="&",["8"]="*",["9"]="(",["0"]=")",["="]="+",["["]="{",
    ["]"]="}",[";"]=":",["\'"]='"',[","]=("<"),["."]=">",["/"]=("?"),
    ["\\"]="|",["-"]="_",["`"]="~",
}

local input = {clicked={},held={}}
local function pollInput()
    input.clicked={}; input.held={}
    for name,id in pairs(KEY_IDS) do
        local pressed=iskeypressed(id)
        input.held[name]=pressed
        if pressed and not prevKeys[name] then input.clicked[name]=true end
        prevKeys[name]=pressed
    end
end
local function isShift() return input.held["lshift"] or input.held["rshift"] or input.held["shift"] end

local PAD=10; local TITLE_H=34; local TAB_H=30
local HEADER_H=TITLE_H+TAB_H; local LINE_H=18; local SIDEBAR_W=210
local prevTab=""

local S = {
    x=80,y=50,w=700,h=540,
    dragging=false,dragOX=0,dragOY=0,
    visible=true,
    tab="browser",
    tools={},toolSel=1,
    scripts={},scriptSel=1,
    pathInput="",pathFocused=false,
    browserStatus="Click Scan to load your inventory",
    browserStatusColor=nil,
    lines={},scroll=0,cursorLine=1,cursorChar=1,
    focused=false,
    editorStatus="",editorStatusColor=nil,
    currentPath="",
    scrollDragging=false,
    keyRepeatTimer={},keyRepeatDelay=0.4,keyRepeatRate=0.05,
    -- settings
    menuKey=0x70, menuKeyName="F1",
    listeningForKey=false,
}

local function scanTools()
    local tools={}
    local bp=player:FindFirstChild("Backpack")
    if bp then for _,c in ipairs(bp:GetChildren()) do
        if c:IsA("Tool") then table.insert(tools,{label=c.Name,inst=c}) end
    end end
    local char=player.Character
    if char then
        local eq=char:FindFirstChildOfClass("Tool")
        if eq then table.insert(tools,{label="[Equipped] "..eq.Name,inst=eq}) end
    end
    return tools
end

local function getScripts(tool)
    local found={}
    for _,c in ipairs(tool:GetDescendants()) do
        if c:IsA("ModuleScript") or c:IsA("LocalScript") or c:IsA("Script") then
            table.insert(found,{label=c.Name.." ["..c.ClassName.."]",inst=c})
        end
    end
    table.sort(found,function(a,b) return a.label<b.label end)
    return found
end

local function decompileToLines(inst)
    local ok,src=pcall(decompile,inst)
    if not ok or not src or src=="" then return nil,"decompile() failed" end
    local lines={}
    for l in (src.."\n"):gmatch("([^\n]*)\n") do table.insert(lines,l) end
    if lines[#lines]=="" then table.remove(lines) end
    return lines,nil
end

local function resolvePathString(path)
    local parts={}
    for p in path:gmatch("[^%.]+") do table.insert(parts,p) end
    local cur
    if parts[1]=="game" then cur=game; table.remove(parts,1)
    elseif parts[1]=="workspace" then cur=workspace; table.remove(parts,1)
    else cur=game end
    for _,p in ipairs(parts) do if cur then cur=cur:FindFirstChild(p) end end
    return cur
end

local function applyLines(lines)
    local toSet,applied,failed={},0,{}
    for _,l in ipairs(lines) do
        local key,val=l:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
        if key and val and val~="" then
            if val=="true" then toSet[key]=true; applied+=1
            elseif val=="false" then toSet[key]=false; applied+=1
            elseif tonumber(val) then toSet[key]=tonumber(val); applied+=1
            elseif val:match("^{%s*[%d%.%-]+%s*,%s*[%d%.%-]+%s*}$") then
                local a=val:match("([%d%.%-]+)")
                if a then setgc(key,tonumber(a)); applied+=1 end
            else table.insert(failed,key) end
        end
    end
    if next(toSet) then setgc(toSet) end
    return applied,failed
end

local KEYWORDS = {
    ["local"]=true,["function"]=true,["return"]=true,["end"]=true,
    ["if"]=true,["then"]=true,["else"]=true,["elseif"]=true,
    ["for"]=true,["do"]=true,["while"]=true,["repeat"]=true,
    ["until"]=true,["and"]=true,["or"]=true,["not"]=true,
    ["in"]=true,["true"]=true,["false"]=true,["nil"]=true,["break"]=true,
}

local function highlight(line)
    local spans={}; local i,n=1,#line
    while i<=n do
        local c=line:sub(i,i)
        if line:sub(i,i+1)=="--" then
            table.insert(spans,{line:sub(i),T.sub}); break
        elseif c=='"' or c=="'" then
            local q,j=c,i+1
            while j<=n and line:sub(j,j)~=q do j=j+1 end
            table.insert(spans,{line:sub(i,j),T.strCol}); i=j+1
        elseif c:match("%d") or (c=="-" and line:sub(i+1,i+1):match("%d")) then
            local j=i; if c=="-" then j=j+1 end
            while j<=n and line:sub(j,j):match("[%d%.]") do j=j+1 end
            table.insert(spans,{line:sub(i,j-1),T.numCol}); i=j
        elseif c:match("[%a_]") then
            local j=i
            while j<=n and line:sub(j,j):match("[%w_]") do j=j+1 end
            local word=line:sub(i,j-1)
            table.insert(spans,{word,KEYWORDS[word] and T.accent or T.text}); i=j
        else
            table.insert(spans,{c,T.sub}); i=i+1
        end
    end
    return spans
end

local function keyRepeating(key,dt)
    if not input.held[key] then S.keyRepeatTimer[key]=nil; return false end
    if input.clicked[key] then S.keyRepeatTimer[key]=S.keyRepeatDelay; return true end
    if S.keyRepeatTimer[key] then
        S.keyRepeatTimer[key]=S.keyRepeatTimer[key]-dt
        if S.keyRepeatTimer[key]<=0 then S.keyRepeatTimer[key]=S.keyRepeatRate; return true end
    end
    return false
end

-- ===== Render =====
local function renderWindow()
    local x,y,w,h=S.x,S.y,S.w,S.h
    Box("shad",x+3,y+3,w,h,Color3.fromRGB(0,0,0),0)
    Box("bg",x,y,w,h,T.bg,1)
    Outline("bg_o",x,y,w,h,T.border,2)
    Box("titlebar",x,y,w,TITLE_H,T.surface,2)
    Ln("title_accent",x+2,y+TITLE_H-1,x+w-2,y+TITLE_H-1,nil,1,3)
    Txt("title_txt",x+PAD,y+10,"ACS Config Editor",T.text,14,3)
    Box("close_bg",x+w-28,y+7,22,20,T.panel,3)
    Txt("close_x",x+w-17,y+17,"x",T.sub,16,4,true)
    local tabs={{"browser","Browser"},{"editor","Editor"},{"settings","Settings"}}
    for i,td in ipairs(tabs) do
        local tx=x+(i-1)*100; local ty=y+TITLE_H
        local active=S.tab==td[1]
        Box("tab_bg_"..i,tx,ty,100,TAB_H,active and T.panel or T.surface,2)
        Txt("tab_txt_"..i,tx+50,ty+8,td[2],active and T.text or T.sub,13,3,true)
        if active then Ln("tab_ul_"..i,tx+2,ty+TAB_H-1,tx+98,ty+TAB_H-1,nil,2,4)
        else hide("tab_ul_"..i) end
    end
end

local function renderBrowser()
    local x,y,w,h=S.x,S.y,S.w,S.h
    local cy=y+HEADER_H+PAD; local lh=h-HEADER_H-PAD*2

    Box("br_lbg",x+PAD,cy,SIDEBAR_W,lh,T.surface,2)
    Outline("br_lbg_o",x+PAD,cy,SIDEBAR_W,lh,T.border,3)
    Txt("br_lhdr",x+PAD+8,cy+6,"TOOLS",T.sub,11,4)
    Ln("br_lhl",x+PAD,cy+22,x+PAD+SIDEBAR_W,cy+22,nil,1,3)

    local toolListY=cy+26; local scanBtnY=cy+lh-28
    local toolVis=math.floor((scanBtnY-toolListY-4)/22)
    for i=1,toolVis do
        local tool=S.tools[i]
        if not tool then hide("br_ti_"..i); hide("br_tt_"..i) break end
        local iy=toolListY+(i-1)*22; local sel=S.toolSel==i
        local hov=inB(x+PAD+1,iy,SIDEBAR_W-2,21)
        Box("br_ti_"..i,x+PAD+1,iy,SIDEBAR_W-2,21,sel and T.accent or (hov and T.panel or T.surface),3)
        local lbl=tool.label
        if tw(lbl,12)>SIDEBAR_W-16 then lbl=lbl:sub(1,23).."…" end
        Txt("br_tt_"..i,x+PAD+8,iy+4,lbl,sel and T.text or T.sub,12,4)
    end
    for i=#S.tools+1,toolVis+2 do hide("br_ti_"..i); hide("br_tt_"..i) end

    Box("br_scan",x+PAD,scanBtnY,SIDEBAR_W,24,inB(x+PAD,scanBtnY,SIDEBAR_W,24) and T.accentHi or T.accent,3)
    Txt("br_scan_t",x+PAD+SIDEBAR_W/2,scanBtnY+12,"Scan Inventory",T.text,12,4,true)

    local rx=x+PAD+SIDEBAR_W+PAD; local rw=w-SIDEBAR_W-PAD*3
    Box("br_rbg",rx,cy,rw,lh,T.surface,2)
    Outline("br_rbg_o",rx,cy,rw,lh,T.border,3)
    Txt("br_rhdr",rx+8,cy+6,"SCRIPTS IN SELECTED TOOL",T.sub,11,4)
    Ln("br_rhl",rx,cy+22,rx+rw,cy+22,nil,1,3)

    local piy=cy+28; local piw=rw-16-76
    Box("br_pi_bg",rx+8,piy,piw,22,T.panel,3)
    Outline("br_pi_o",rx+8,piy,piw,22,S.pathFocused and T.accent or T.border,3)
    local pd=S.pathInput
    if pd=="" and not S.pathFocused then
        Txt("br_pi_t",rx+14,piy+4,"or paste path: game.X.Y.Script",T.sub,11,4)
    else
        if S.pathFocused then pd=pd..(math.floor(tick()*2)%2==0 and "|" or " ") end
        Txt("br_pi_t",rx+14,piy+4,pd,T.text,11,4)
    end
    local lpx=rx+8+piw+6
    Box("br_lp_bg",lpx,piy,70,22,inB(lpx,piy,70,22) and T.accentHi or T.accent,3)
    Txt("br_lp_t",lpx+35,piy+11,"Load Path",T.text,11,4,true)

    local slY=cy+58; local loadBtnY=cy+lh-28
    local sVis=math.floor((loadBtnY-slY-4)/22)
    for i=1,sVis do
        local sc=S.scripts[i]
        if not sc then hide("br_si_"..i); hide("br_st_"..i) break end
        local iy=slY+(i-1)*22; local sel=S.scriptSel==i
        local hov=inB(rx+1,iy,rw-2,21)
        Box("br_si_"..i,rx+1,iy,rw-2,21,sel and T.accent or (hov and T.panel or T.surface),3)
        local lbl=sc.label
        if tw(lbl,12)>rw-16 then lbl=lbl:sub(1,50).."…" end
        Txt("br_st_"..i,rx+8,iy+4,lbl,sel and T.text or T.sub,12,4)
    end
    for i=#S.scripts+1,sVis+2 do hide("br_si_"..i); hide("br_st_"..i) end

    local hasScript=#S.scripts>0
    Box("br_load",rx,loadBtnY,rw,24,
        (hasScript and inB(rx,loadBtnY,rw,24)) and T.accentHi or (hasScript and T.accent or T.border),3)
    Txt("br_load_t",rx+rw/2,loadBtnY+12,
        hasScript and "Decompile & Open in Editor" or "Select a tool then a script",T.text,12,4,true)
    Txt("br_status",x+PAD,y+h-16,S.browserStatus,S.browserStatusColor or T.sub,11,3)
end

local function renderEditor()
    local x,y,w,h=S.x,S.y,S.w,S.h
    local edY=y+HEADER_H; local bbH=36; local pathbarH=22; local libarH=22
    local lineNumW=46; local codeY=edY+pathbarH+libarH
    local codeH=h-HEADER_H-pathbarH-libarH-bbH

    Box("ed_pathbar",x,edY,w,pathbarH,T.panel,2)
    Txt("ed_path",x+PAD,edY+4,S.currentPath=="" and "No file loaded — use Browser tab" or S.currentPath,T.sub,11,3)

    Box("ed_codebg",x,codeY,w,codeH,T.surface,1)
    Box("ed_lnbg",x,codeY,lineNumW,codeH,T.bg,2)
    Ln("ed_lnborder",x+lineNumW,codeY,x+lineNumW,codeY+codeH,nil,1,3)

    local visLines=math.floor(codeH/LINE_H)
    local totalLines=#S.lines
    local maxScroll=math.max(0,totalLines-visLines)
    S.scroll=math.max(0,math.min(S.scroll,maxScroll))

    local cursorVisible=false
    for i=1,visLines do
        local li=i+S.scroll; local lineY=codeY+(i-1)*LINE_H
        local isCur=li==S.cursorLine and S.focused

        if isCur then Box("ed_curhl_"..i,x+lineNumW+1,lineY,w-lineNumW-1,LINE_H,Color3.fromRGB(32,32,44),2)
        else hide("ed_curhl_"..i) end

        if li<=totalLines then
            Txt("ed_ln_"..i,x+lineNumW-4,lineY+2,tostring(li),
                li==S.cursorLine and T.accent or Color3.fromRGB(70,70,90),11,3,true)
            local spans=highlight(S.lines[li]); local ox=x+lineNumW+6
            hidePrefix("ed_sp_"..i.."_")
            for si,sp in ipairs(spans) do
                Txt("ed_sp_"..i.."_"..si,ox,lineY+2,sp[1],sp[2],13,4)
                ox=ox+tw(sp[1],13)
            end
        else
            hide("ed_ln_"..i); hidePrefix("ed_sp_"..i.."_")
        end

        if isCur and math.floor(tick()*2)%2==0 then
            local cur=S.lines[S.cursorLine] or ""
            Box("ed_cur",x+lineNumW+6+tw(cur:sub(1,S.cursorChar-1),13),lineY+2,2,LINE_H-4,T.cursor,5)
            cursorVisible=true
        end
    end
    if not cursorVisible then hide("ed_cur") end

    for i=visLines+1,visLines+5 do
        hide("ed_curhl_"..i); hide("ed_ln_"..i); hidePrefix("ed_sp_"..i.."_")
    end

    -- scrollbar
    local sbW=8; local sbX=x+w-sbW-2
    if totalLines>visLines then
        local tbH=codeH-4
        local sbH=math.max(20,tbH*(visLines/totalLines))
        local sbY=codeY+2+(tbH-sbH)*(S.scroll/math.max(1,maxScroll))
        Box("ed_sb_tr",sbX,codeY+2,sbW,tbH,Color3.fromRGB(22,22,30),2)
        Box("ed_sb_th",sbX,sbY,sbW,sbH,T.border,3)
    else hide("ed_sb_tr"); hide("ed_sb_th") end

    local bbY=y+h-bbH
    Box("ed_bb",x,bbY,w,bbH,T.panel,2)
    Ln("ed_bbl",x,bbY,x+w,bbY,nil,1,3)
    Txt("ed_li",x+PAD,bbY+10,"Ln "..S.cursorLine.." / "..totalLines.."   Col "..S.cursorChar,T.sub,11,3)
    Txt("ed_mode",x+180,bbY+10,S.focused and "  EDITING" or "  READ ONLY",S.focused and T.success or T.sub,11,3)
    if S.editorStatus~="" then Txt("ed_st",x+310,bbY+10,S.editorStatus,S.editorStatusColor or T.sub,11,3)
    else hide("ed_st") end
    local abW=150; local abX=x+w-abW-PAD; local abY=bbY+6
    Box("ed_ap",abX,abY,abW,24,inB(abX,abY,abW,24) and T.accentHi or T.accent,3)
    Txt("ed_ap_t",abX+abW/2,abY+12,"Apply via setgc",T.text,12,4,true)
end

local function renderLineBar()
    local x,y,w,h=S.x,S.y,S.w,S.h
    local libarY=y+HEADER_H+22; local libarH=22
    Box("li_bg",x,libarY,w,libarH,Color3.fromRGB(18,18,26),6)
    Ln("li_bot",x,libarY+libarH,x+w,libarY+libarH,nil,1,7)

    local rawLine=S.lines[S.cursorLine] or ""
    local indent=rawLine:match("^(%s*)") or ""
    local trimmed=rawLine:match("^%s*(.-)%s*$") or ""
    local cursorInTrimmed=math.max(0,S.cursorChar-1-#indent)
    local blink=math.floor(tick()*2)%2==0
    local displayLine
    if S.focused and blink then
        displayLine=trimmed:sub(1,cursorInTrimmed).."|"..trimmed:sub(cursorInTrimmed+1)
    else
        displayLine=trimmed=="" and " " or trimmed
    end

    local label=" Ln "..S.cursorLine.."  ›  "; local labelW=tw(label,11)
    Txt("li_label",x+PAD,libarY+5,label,T.sub,11,7)
    local word=displayLine:match("^([%w_]+)")
    if word and KEYWORDS[word] then
        Txt("li_kw",x+PAD+labelW,libarY+5,word,T.accent,11,7)
        local rest=displayLine:sub(#word+1)
        local maxW=w-PAD*2-labelW-tw(word,11)-10
        if tw(rest,11)>maxW then rest=rest:sub(1,math.max(1,math.floor(maxW/(11*0.535)))).."…" end
        Txt("li_rest",x+PAD+labelW+tw(word,11),libarY+5,rest,T.text,11,7); hide("li_plain")
    else
        local maxW=w-PAD*2-labelW-10
        if tw(displayLine,11)>maxW then displayLine=displayLine:sub(1,math.max(1,math.floor(maxW/(11*0.535)))).."…" end
        Txt("li_plain",x+PAD+labelW,libarY+5,displayLine,T.text,11,7)
        hide("li_kw"); hide("li_rest")
    end
end

local function renderSettings()
    local x,y,w,h=S.x,S.y,S.w,S.h
    local cy=y+HEADER_H+PAD

    Box("st_bg",x+PAD,cy,w-PAD*2,h-HEADER_H-PAD*2,T.surface,2)
    Outline("st_bg_o",x+PAD,cy,w-PAD*2,h-HEADER_H-PAD*2,T.border,3)
    Txt("st_hdr",x+PAD+12,cy+10,"SETTINGS",T.sub,11,4)
    Ln("st_hdrl",x+PAD,cy+26,x+w-PAD,cy+26,nil,1,3)

    Txt("st_keylbl",x+PAD+12,cy+40,"Menu Toggle Hotkey",T.text,13,4)
    Txt("st_keysub",x+PAD+12,cy+58,"Click the button then press any key to rebind",T.sub,11,4)

    local btnW=160; local btnX=x+PAD+12; local btnY=cy+80
    local listening=S.listeningForKey
    Box("st_keybtn",btnX,btnY,btnW,30,listening and T.accentHi or T.panel,3)
    Outline("st_keybtn_o",btnX,btnY,btnW,30,listening and T.accent or T.border,3)
    Txt("st_keytxt",btnX+btnW/2,btnY+15,
        listening and "Press any key..." or S.menuKeyName,
        listening and T.accent or T.text,13,4,true)

    Txt("st_note",x+PAD+12,btnY+42,"Current hotkey: "..S.menuKeyName,T.sub,11,4)
end

-- ===== Input handler =====
local function handleInput(dt)
    if not S.visible then return end
    local x,y,w,h=S.x,S.y,S.w,S.h
    local click=input.clicked["m1"]
    local held=input.held["m1"]
    local mx,my=getMouse().X,getMouse().Y

    -- close
    if click and inB(x+w-28,y+7,22,20) then
        S.visible=false; hidePrefix(""); setrobloxinput(true); return
    end

    -- drag
    if click and inB(x,y,w,TITLE_H) and not inB(x+w-28,y+7,22,20) then
        S.dragging=true; S.dragOX=mx-x; S.dragOY=my-y
    end
    if S.dragging then
        if held then S.x=mx-S.dragOX; S.y=my-S.dragOY else S.dragging=false end
    end

    -- tabs
    if click and inB(x,y+TITLE_H,100,TAB_H) then S.tab="browser"; S.focused=false; S.pathFocused=false end
    if click and inB(x+100,y+TITLE_H,100,TAB_H) then S.tab="editor"; S.pathFocused=false end
    if click and inB(x+200,y+TITLE_H,100,TAB_H) then S.tab="settings"; S.focused=false; S.pathFocused=false end

    -- settings
    if S.tab=="settings" then
        local cy=y+HEADER_H+PAD
        local btnX=x+PAD+12; local btnY=cy+80; local btnW=160

        if click and inB(btnX,btnY,btnW,30) then
            S.listeningForKey=true
        end

        if S.listeningForKey then
            for name,id in pairs(KEY_IDS) do
                if name~="m1" and name~="m2" and name~="lshift" and name~="rshift" and name~="shift" then
                    if input.clicked[name] then
                        S.menuKey=id
                        S.menuKeyName=name:upper()
                        S.listeningForKey=false
                        break
                    end
                end
            end
        end
        return
    end

    if S.tab=="browser" then
        local cy=y+HEADER_H+PAD; local lh=h-HEADER_H-PAD*2
        local scanBtnY=cy+lh-28
        local rx=x+PAD+SIDEBAR_W+PAD; local rw=w-SIDEBAR_W-PAD*3
        local piy=cy+28; local piw=rw-16-76; local lpx=rx+8+piw+6
        local slY=cy+58; local loadBtnY=cy+lh-28
        local toolListY=cy+26
        local toolVis=math.floor((scanBtnY-toolListY-4)/22)
        local sVis=math.floor((loadBtnY-slY-4)/22)

        if click and inB(x+PAD,scanBtnY,SIDEBAR_W,24) then
            S.tools=scanTools(); S.toolSel=1; S.scripts={}
            if #S.tools==0 then S.browserStatus="No tools found"; S.browserStatusColor=T.warn
            else
                S.browserStatus="Found "..#S.tools.." tool(s)"; S.browserStatusColor=T.success
                S.scripts=getScripts(S.tools[1].inst)
            end
        end

        for i=1,toolVis do
            if S.tools[i] and click and inB(x+PAD+1,toolListY+(i-1)*22,SIDEBAR_W-2,21) then
                S.toolSel=i; S.scripts=getScripts(S.tools[i].inst); S.scriptSel=1
                S.browserStatus=S.tools[i].label.." — "..#S.scripts.." script(s)"
                S.browserStatusColor=T.sub
            end
        end

        if click then
            if inB(rx+8,piy,piw,22) then S.pathFocused=true; S.focused=false
            elseif not inB(lpx,piy,70,22) then S.pathFocused=false end
        end

        if S.pathFocused then
            local typeKeys={"a","b","c","d","e","f","g","h","i","j","k","l","m",
                "n","o","p","q","r","s","t","u","v","w","x","y","z",
                "0","1","2","3","4","5","6","7","8","9",
                "period","minus","slash","backspace","enter"}
            for _,k in ipairs(typeKeys) do
                if keyRepeating(k,dt) then
                    if k=="backspace" then S.pathInput=S.pathInput:sub(1,-2)
                    elseif k=="enter" then S.pathFocused=false
                    else
                        local c=charMap[k] or k
                        if #c==1 then
                            if isShift() then c=c:upper() end
                            S.pathInput=S.pathInput..c
                        end
                    end
                end
            end
        end

        if click and inB(lpx,piy,70,22) and S.pathInput~="" then
            S.pathFocused=false
            local inst=resolvePathString(S.pathInput)
            if inst and (inst:IsA("ModuleScript") or inst:IsA("LocalScript") or inst:IsA("Script")) then
                local lines,err=decompileToLines(inst)
                if lines then
                    S.lines=lines; S.currentPath=inst:GetFullName()
                    S.cursorLine=1; S.cursorChar=1; S.scroll=0; S.tab="editor"
                    S.editorStatus="Loaded "..#lines.." lines"; S.editorStatusColor=T.success
                else S.browserStatus=err; S.browserStatusColor=T.err end
            else S.browserStatus="Path not found or not a script"; S.browserStatusColor=T.err end
        end

        for i=1,sVis do
            if S.scripts[i] and click and inB(rx+1,slY+(i-1)*22,rw-2,21) then S.scriptSel=i end
        end

        if click and #S.scripts>0 and inB(rx,loadBtnY,rw,24) then
            local sc=S.scripts[S.scriptSel]
            if sc then
                local lines,err=decompileToLines(sc.inst)
                if lines then
                    S.lines=lines; S.currentPath=sc.inst:GetFullName()
                    S.cursorLine=1; S.cursorChar=1; S.scroll=0; S.tab="editor"
                    S.editorStatus="Loaded "..#lines.." lines"; S.editorStatusColor=T.success
                else S.browserStatus=err; S.browserStatusColor=T.err end
            end
        end
    end

    if S.tab=="editor" then
        local pathbarH=22; local libarH=22; local bbH=36
        local edY=y+HEADER_H
        local codeY=edY+pathbarH+libarH
        local codeH=h-HEADER_H-pathbarH-libarH-bbH
        local lineNumW=46
        local visLines=math.floor(codeH/LINE_H)
        local totalLines=#S.lines
        local maxScroll=math.max(0,totalLines-visLines)
        local sbW=8; local sbX=x+w-sbW-2

        -- scrollbar drag
        if click and inB(sbX,codeY,sbW+2,codeH) then S.scrollDragging=true end
        if not held then S.scrollDragging=false end
        if S.scrollDragging and totalLines>visLines then
            local tbH=codeH-4
            local sbH=math.max(20,tbH*(visLines/totalLines))
            local ratio=(my-codeY-sbH/2)/math.max(1,tbH-sbH)
            S.scroll=math.max(0,math.min(maxScroll,math.floor(ratio*maxScroll+0.5)))
        end

        if click then
            if inB(x+lineNumW,codeY,w-lineNumW-sbW-4,codeH) then
                S.focused=true; S.pathFocused=false
                local cl=S.scroll+math.floor((my-codeY)/LINE_H)+1
                S.cursorLine=math.max(1,math.min(cl,math.max(1,totalLines)))
                local clickedLine=S.lines[S.cursorLine] or ""
                local relX=mx-(x+lineNumW+6)+tw("a",13)*0.5
                S.cursorChar=math.max(1,math.min(math.floor(relX/tw("a",13))+1,#clickedLine+1))
            else
                S.focused=false
            end
        end

        if S.focused then
            local navKeys={"up","down","left","right","pageup","pagedown","home","end"}
            for _,k in ipairs(navKeys) do
                if keyRepeating(k,dt) then
                    if k=="up" then
                        S.cursorLine=math.max(1,S.cursorLine-1)
                        if S.cursorLine<S.scroll+1 then S.scroll=S.cursorLine-1 end
                        S.cursorChar=math.min(S.cursorChar,#(S.lines[S.cursorLine] or "")+1)
                    elseif k=="down" then
                        S.cursorLine=math.min(math.max(1,totalLines),S.cursorLine+1)
                        if S.cursorLine>S.scroll+visLines then S.scroll=S.cursorLine-visLines end
                        S.cursorChar=math.min(S.cursorChar,#(S.lines[S.cursorLine] or "")+1)
                    elseif k=="left" then
                        if S.cursorChar>1 then S.cursorChar=S.cursorChar-1
                        elseif S.cursorLine>1 then
                            S.cursorLine=S.cursorLine-1
                            S.cursorChar=#(S.lines[S.cursorLine] or "")+1
                        end
                    elseif k=="right" then
                        local ll=#(S.lines[S.cursorLine] or "")
                        if S.cursorChar<=ll then S.cursorChar=S.cursorChar+1
                        elseif S.cursorLine<totalLines then S.cursorLine=S.cursorLine+1; S.cursorChar=1 end
                    elseif k=="pageup" then
                        S.scroll=math.max(0,S.scroll-visLines)
                        S.cursorLine=math.max(1,S.cursorLine-visLines)
                    elseif k=="pagedown" then
                        S.scroll=math.min(math.max(0,totalLines-visLines),S.scroll+visLines)
                        S.cursorLine=math.min(math.max(1,totalLines),S.cursorLine+visLines)
                    elseif k=="home" then S.cursorChar=1
                    elseif k=="end" then S.cursorChar=#(S.lines[S.cursorLine] or "")+1
                    end
                end
            end

            local typeKeys={"a","b","c","d","e","f","g","h","i","j","k","l","m",
                "n","o","p","q","r","s","t","u","v","w","x","y","z",
                "0","1","2","3","4","5","6","7","8","9",
                "space","minus","plus","lbracket","rbracket","semicolon",
                "quote","comma","period","slash","backslash","tilde",
                "backspace","enter","tab"}
            for _,k in ipairs(typeKeys) do
                if keyRepeating(k,dt) then
                    local cur=S.lines[S.cursorLine] or ""
                    if k=="backspace" then
                        if S.cursorChar>1 then
                            S.lines[S.cursorLine]=cur:sub(1,S.cursorChar-2)..cur:sub(S.cursorChar)
                            S.cursorChar=S.cursorChar-1
                        elseif S.cursorLine>1 then
                            local prev=S.lines[S.cursorLine-1]; local nc=#prev+1
                            S.lines[S.cursorLine-1]=prev..cur
                            table.remove(S.lines,S.cursorLine)
                            S.cursorLine=S.cursorLine-1; S.cursorChar=nc
                            if S.cursorLine<S.scroll then S.scroll=math.max(0,S.cursorLine-1) end
                        end
                    elseif k=="enter" then
                        local before=cur:sub(1,S.cursorChar-1); local after=cur:sub(S.cursorChar)
                        local indent=before:match("^(%s*)") or ""
                        S.lines[S.cursorLine]=before
                        table.insert(S.lines,S.cursorLine+1,indent..after)
                        S.cursorLine=S.cursorLine+1; S.cursorChar=#indent+1
                        if S.cursorLine>S.scroll+visLines then S.scroll=S.scroll+1 end
                    elseif k=="tab" then
                        S.lines[S.cursorLine]=cur:sub(1,S.cursorChar-1).."    "..cur:sub(S.cursorChar)
                        S.cursorChar=S.cursorChar+4
                    else
                        local c=charMap[k] or k
                        if #c==1 then
                            if isShift() and shiftMap[c] then c=shiftMap[c]
                            elseif isShift() then c=c:upper() end
                            S.lines[S.cursorLine]=cur:sub(1,S.cursorChar-1)..c..cur:sub(S.cursorChar)
                            S.cursorChar=S.cursorChar+1
                        end
                    end
                    break
                end
            end
        end

        local abW=150; local abX=x+w-abW-PAD; local abY=y+h-bbH+6
        if click and inB(abX,abY,abW,24) then
            local applied,failed=applyLines(S.lines)
            if #failed==0 then
                S.editorStatus="Applied "..applied.." value(s)"; S.editorStatusColor=T.success
            else
                S.editorStatus="Applied "..applied..", skipped: "..table.concat(failed,", ")
                S.editorStatusColor=T.warn
            end
        end
    end
end

-- ===== Main loop =====
RunService.RenderStepped:Connect(function(dt)
    pollInput()

    -- hotkey toggle (always active)
    if input.clicked["m1"]==nil and iskeypressed(S.menuKey) and not prevKeys["__menukey"] then
        S.visible=not S.visible
        if not S.visible then hidePrefix(""); setrobloxinput(true) end
    end
    prevKeys["__menukey"]=iskeypressed(S.menuKey)

    if not S.visible then
        setrobloxinput(true)
        return
    end

    handleInput(dt)

    if S.pathFocused or (S.tab=="editor" and S.focused) then
        setrobloxinput(false)
    else
        setrobloxinput(true)
    end

    renderWindow()

    if S.tab~=prevTab then
        if S.tab=="browser" then hidePrefix("ed_"); hidePrefix("li_"); hidePrefix("st_")
        elseif S.tab=="editor" then hidePrefix("br_"); hidePrefix("st_")
        elseif S.tab=="settings" then hidePrefix("br_"); hidePrefix("ed_"); hidePrefix("li_") end
        prevTab=S.tab
    end

    if S.tab=="browser" then renderBrowser()
    elseif S.tab=="editor" then renderEditor(); renderLineBar()
    elseif S.tab=="settings" then renderSettings() end
end)
