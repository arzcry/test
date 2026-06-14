-- ACS Config Editor — standalone Matcha Drawing UI
-- v2: GC matcher, Search, Diff view, Per-tool memory, Reload, Scroll wheel, Horiz scroll, Browser fix

local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")

local T = {
    bg =      Color3.fromRGB(10, 10, 14),
    surface = Color3.fromRGB(16, 16, 22),
    panel =   Color3.fromRGB(22, 22, 30),
    panel2 =  Color3.fromRGB(28, 28, 40),
    border =  Color3.fromRGB(44, 44, 58),
    borderHi= Color3.fromRGB(80, 80, 110),
    accent =  Color3.fromRGB(99, 102, 241),
    accentHi= Color3.fromRGB(130, 133, 255),
    accentDim=Color3.fromRGB(50, 52, 140),
    text =    Color3.fromRGB(228, 228, 238),
    textDim = Color3.fromRGB(150, 150, 170),
    sub =     Color3.fromRGB(95, 95, 118),
    success = Color3.fromRGB(48, 209, 88),
    warn =    Color3.fromRGB(255, 196, 0),
    err =     Color3.fromRGB(255, 69, 58),
    numCol =  Color3.fromRGB(130, 190, 255),
    strCol =  Color3.fromRGB(130, 220, 130),
    cursor =  Color3.fromRGB(99, 102, 241),
    diffChg = Color3.fromRGB(255, 196, 50),
    diffAdd = Color3.fromRGB(48, 209, 88),
    srchHi =  Color3.fromRGB(70, 62, 10),
    srchCur = Color3.fromRGB(110, 96, 14),
    tag =     Color3.fromRGB(36, 36, 52),
    sep =     Color3.fromRGB(34, 34, 48),
}

local v2 = Vector2.new
local D = {}
local CHAR_W = 13 * 0.535

local function Ln(id, x1, y1, x2, y2, color, thick, zi)
    if not D[id] then D[id] = Drawing.new("Line") end
    local d = D[id]
    d.From = v2(x1,y1); d.To = v2(x2,y2)
    d.Thickness = thick or 1; d.ZIndex = zi or 2; d.Visible = true
end
local function Box(id, x, y, w, h, color, zi)
    if not D[id] then D[id] = Drawing.new("Square") end
    local d = D[id]
    d.Position = v2(x,y); d.Size = v2(w,h)
    d.Color = color; d.Filled = true; d.ZIndex = zi or 1; d.Visible = true
end
local function Outline(id, x, y, w, h, color, zi)
    if not D[id] then D[id] = Drawing.new("Square") end
    local d = D[id]
    d.Position = v2(x,y); d.Size = v2(w,h)
    d.Color = color; d.Filled = false; d.ZIndex = zi or 2; d.Visible = true
end
local function Txt(id, x, y, str, color, size, zi, center)
    if not D[id] then D[id] = Drawing.new("Text") end
    local d = D[id]
    d.Position = v2(x,y); d.Text = tostring(str); d.Color = color
    d.Size = size or 13; d.Font = Drawing.Fonts.UI; d.Outline = false
    d.Center = center or false; d.ZIndex = zi or 3; d.Visible = true
end
local function hide(id) if D[id] then D[id].Visible = false end end
local function hidePrefix(p)
    for k,d in pairs(D) do if k:sub(1,#p)==p then d.Visible=false end end
end
local function tw(s, sz) return #s*(sz or 13)*0.535 end

-- Rounded box approximation — no Circle support in Matcha, use thin side strips
-- Visually gives a slightly inset feel; true rounding not possible without Circle
local function RBox(id, x, y, w, h, color, zi, r)
    -- Just draw a normal box; we fake "rounding" via the corner clip overlay
    Box(id.."_c", x, y, w, h, color, zi or 1)
end
local function hideRBox(id)
    hide(id.."_c")
end

-- (Corner rounding via overlay removed — Matcha Line/Circle APIs too limited)

-- ===== Mouse scroll wheel (pcall — may or may not work in Matcha) =====
local wheelDelta = 0
pcall(function()
    local m = player:GetMouse()
    m.WheelForward:Connect(function() wheelDelta = wheelDelta - 3 end)
    m.WheelBackward:Connect(function() wheelDelta = wheelDelta + 3 end)
end)

-- ===== Input =====
local prevKeys = {}
local mouse = player:GetMouse()
local function getMouse() return v2(mouse.X, mouse.Y) end
local function inB(x,y,w,h)
    local m=getMouse(); return m.X>=x and m.X<=x+w and m.Y>=y and m.Y<=y+h
end

local KEY_IDS = {
    m1=0x01,m2=0x02,backspace=0x08,tab=0x09,enter=0x0D,escape=0x1B,
    shift=0x10,lshift=0xA0,rshift=0xA1,
    ctrl=0x11,lctrl=0xA2,rctrl=0xA3,
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
local function isCtrl()  return input.held["lctrl"]  or input.held["rctrl"]  or input.held["ctrl"]  end

-- ===== Constants =====
local PAD=10; local TITLE_H=34; local TAB_H=30
local HEADER_H=TITLE_H+TAB_H; local LINE_H=18; local SIDEBAR_W=220
local PATHBAR_H=22; local LIBAR_H=22; local BBH=36; local HSB_H=10
local DIFF_W=4; local LN_W=50; local SB_W=8
local prevTab=""

-- ===== State =====
local S = {
    x=60,y=30,w=780,h=640,
    dragging=false,dragOX=0,dragOY=0,
    visible=true,
    tab="browser",

    -- browser
    tools={},toolSel=1,
    scripts={},scriptSel=1,
    pathInput="",pathFocused=false,
    browserStatus="Click Scan to load your inventory",
    browserStatusColor=nil,
    toolMemory={},   -- [toolName] -> last scriptSel index

    -- editor
    lines={},
    originalLines={},  -- snapshot at load time for diff
    scroll=0,scrollX=0,
    cursorLine=1,cursorChar=1,
    focused=false,
    editorStatus="",editorStatusColor=nil,
    currentPath="",
    currentInst=nil,   -- for reload
    scrollDragging=false,
    scrollXDragging=false,

    -- search
    searchOpen=false,
    searchQuery="",
    searchFocused=false,
    searchMatches={},
    searchMatchIdx=1,

    -- key repeat
    keyRepeatTimer={},keyRepeatDelay=0.4,keyRepeatRate=0.05,

    -- auto-apply
    autoApply=false,
    autoApplyInterval=3.0,
    autoApplyIntervalInput="3",
    autoApplyTimer=0,
    autoApplyCount=0,
    autoApplyFocused=false,

    -- settings
    menuKey=0x70,menuKeyName="F1",
    listeningForKey=false,
}

-- ===== Helpers =====
local function deepCopy(t)
    local c={}; for i,v in ipairs(t) do c[i]=v end; return c
end

local function scanTools()
    local tools={}
    local bp=player:FindFirstChild("Backpack")
    if bp then
        for _,c in ipairs(bp:GetChildren()) do
            if c:IsA("Tool") then table.insert(tools,{label=c.Name,inst=c}) end
        end
    end
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

-- GC field matcher: verify keys exist in GC heap before applying
local function applyLinesGC(lines)
    local candidates={}
    local applied=0; local failed={}; local notInGC={}

    for _,l in ipairs(lines) do
        local key,val=l:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
        if key and val and val~="" then
            if val=="true" then candidates[key]={v=true,t="bool"}
            elseif val=="false" then candidates[key]={v=false,t="bool"}
            elseif tonumber(val) then candidates[key]={v=tonumber(val),t="num"}
            elseif val:match("^{%s*[%d%.%-]+%s*,%s*[%d%.%-]+%s*}$") then
                local a=val:match("([%d%.%-]+)")
                if a then candidates[key]={v=tonumber(a),t="vec"} end
            else table.insert(failed,key) end
        end
    end

    local keyList={}
    for k in pairs(candidates) do table.insert(keyList,k) end

    if #keyList>0 then
        local gcOk,gcRes=pcall(getgc,keyList)
        if gcOk and type(gcRes)=="table" then
            local found={}
            for _,entry in ipairs(gcRes) do
                if type(entry)=="table" and entry.key then found[tostring(entry.key)]=true end
            end
            local toSet={}
            for k,info in pairs(candidates) do
                if found[k] then
                    if info.t=="vec" then pcall(setgc,k,info.v)
                    else toSet[k]=info.v end
                    applied+=1
                else table.insert(notInGC,k) end
            end
            if next(toSet) then pcall(setgc,toSet) end
        else
            -- getgc unavailable, apply directly
            local toSet={}
            for k,info in pairs(candidates) do
                if info.t=="vec" then pcall(setgc,k,info.v)
                else toSet[k]=info.v end
                applied+=1
            end
            if next(toSet) then pcall(setgc,toSet) end
        end
    end
    return applied,failed,notInGC
end

local function buildSearchMatches(query)
    local matches={}
    if query=="" then return matches end
    local q=query:lower()
    for i,line in ipairs(S.lines) do
        if line:lower():find(q,1,true) then table.insert(matches,i) end
    end
    return matches
end

local KEYWORDS={
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

-- ===== Layout helpers =====
local function edLayout()
    local searchH = S.searchOpen and 22 or 0
    local edY = S.y+HEADER_H
    local pathBarY = edY
    local searchBarY = edY+PATHBAR_H
    local liBarY = edY+PATHBAR_H+searchH
    local codeY = edY+PATHBAR_H+searchH+LIBAR_H
    local codeH = S.h-HEADER_H-PATHBAR_H-searchH-LIBAR_H-BBH-HSB_H
    local codeW = S.w-LN_W-DIFF_W-SB_W-4
    local codeStartX = S.x+LN_W+DIFF_W+4
    return edY,pathBarY,searchBarY,liBarY,codeY,codeH,codeW,codeStartX
end

-- ===== Render =====
local function renderWindow()
    local x,y,w,h=S.x,S.y,S.w,S.h
    -- shadow
    Box("shad",x+4,y+4,w,h,Color3.fromRGB(0,0,0),0)
    -- main window (rounded)
    RBox("win",x,y,w,h,T.bg,1,6)
    -- subtle border
    RBox("win_o",x,y,w,h,T.border,2,6)
    -- title bar
    RBox("titlebar",x,y,w,TITLE_H+6,T.panel,2,6)
    Box("titlebar_sq",x,y+6,w,TITLE_H,T.panel,2) -- square out the bottom of titlebar rounding
    -- accent bar under title
    Box("title_accent",x,y+TITLE_H-1,w,1,T.accentDim,3)
    -- title text
    Txt("title_txt",x+PAD+2,y+10,"ACS Config Editor",T.text,13,3)
    -- version pill
    Box("title_ver",x+w-100,y+10,54,16,T.accentDim,3)
    Txt("title_ver_t",x+w-73,y+18,"v3",T.accent,10,4,true)
    -- close button
    Box("close_bg",x+w-26,y+8,18,18,T.panel2,3)
    Txt("close_x",x+w-17,y+17,"×",T.sub,14,4,true)

    -- tabs
    local tabs={{"browser","Browser"},{"editor","Editor"},{"settings","Settings"}}
    local tabW=110
    Box("tabs_bg",x,y+TITLE_H,w,TAB_H,T.surface,2)
    for i,td in ipairs(tabs) do
        local tx=x+(i-1)*tabW; local ty=y+TITLE_H; local active=S.tab==td[1]
        if active then
            Box("tab_bg_"..i,tx,ty,tabW,TAB_H,T.panel,3)
            -- accent underline
            Box("tab_ul_"..i,tx+4,ty+TAB_H-2,tabW-8,2,T.accent,4)
        else
            Box("tab_bg_"..i,tx,ty,tabW,TAB_H,T.surface,3)
            hide("tab_ul_"..i)
        end
        Txt("tab_txt_"..i,tx+tabW/2,ty+9,td[2],
            active and T.text or T.sub, active and 12 or 11, 4, true)
    end
    -- tab right separator line
    Ln("tabs_sep",x,y+TITLE_H+TAB_H-1,x+w,y+TITLE_H+TAB_H-1,nil,1,3)
end

local function renderBrowser()
    local x,y,w,h=S.x,S.y,S.w,S.h
    local cx=x+PAD
    local cy=y+HEADER_H+PAD
    -- leave 28px at bottom for status bar
    local lh=h-HEADER_H-PAD*2-28

    -- left panel: tools
    Box("br_lbg",x+PAD,cy,SIDEBAR_W,lh,T.surface,2)
    Outline("br_lbg_o",x+PAD,cy,SIDEBAR_W,lh,T.border,3)
    Txt("br_lhdr",x+PAD+8,cy+6,"TOOLS",T.sub,11,4)
    Ln("br_lhl",x+PAD,cy+22,x+PAD+SIDEBAR_W,cy+22,nil,1,3)

    local toolListY=cy+26; local scanBtnY=cy+lh-32
    local toolVis=math.floor((scanBtnY-toolListY-4)/22)
    for i=1,toolVis do
        local tool=S.tools[i]
        if not tool then hide("br_ti_"..i); hide("br_tt_"..i) break end
        local iy=toolListY+(i-1)*22; local sel=S.toolSel==i
        local hov=inB(x+PAD+1,iy,SIDEBAR_W-2,21)
        Box("br_ti_"..i,x+PAD+1,iy,SIDEBAR_W-2,21,sel and T.accent or (hov and T.panel or T.surface),3)
        local lbl=tool.label
        if tw(lbl,12)>SIDEBAR_W-16 then lbl=lbl:sub(1,26).."…" end
        Txt("br_tt_"..i,x+PAD+8,iy+4,lbl,sel and T.text or T.sub,12,4)
    end
    for i=#S.tools+1,toolVis+2 do hide("br_ti_"..i); hide("br_tt_"..i) end

    Box("br_scan",x+PAD,scanBtnY,SIDEBAR_W,28,inB(x+PAD,scanBtnY,SIDEBAR_W,28) and T.accentHi or T.accent,3)
    Txt("br_scan_t",x+PAD+SIDEBAR_W/2,scanBtnY+14,"Scan Inventory",T.text,13,4,true)

    -- right panel: scripts
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

    local slY=cy+58; local loadBtnY=cy+lh-32
    local sVis=math.floor((loadBtnY-slY-4)/22)
    for i=1,sVis do
        local sc=S.scripts[i]
        if not sc then hide("br_si_"..i); hide("br_st_"..i) break end
        local iy=slY+(i-1)*22; local sel=S.scriptSel==i
        local hov=inB(rx+1,iy,rw-2,21)
        Box("br_si_"..i,rx+1,iy,rw-2,21,sel and T.accent or (hov and T.panel or T.surface),3)
        local lbl=sc.label
        if tw(lbl,12)>rw-16 then lbl=lbl:sub(1,60).."…" end
        Txt("br_st_"..i,rx+8,iy+4,lbl,sel and T.text or T.sub,12,4)
    end
    for i=#S.scripts+1,sVis+2 do hide("br_si_"..i); hide("br_st_"..i) end

    local hasScript=#S.scripts>0
    Box("br_load",rx,loadBtnY,rw,28,
        (hasScript and inB(rx,loadBtnY,rw,28)) and T.accentHi or (hasScript and T.accent or T.border),3)
    Txt("br_load_t",rx+rw/2,loadBtnY+14,
        hasScript and "Decompile & Open in Editor" or "Select a tool then a script",T.text,12,4,true)

    -- status bar — own row below panels, always visible
    local stY=cy+lh+4
    Box("br_stbg",cx,stY,w-PAD*2,22,T.panel2,2)
    Outline("br_sto",cx,stY,w-PAD*2,22,T.border,3)
    -- colored dot indicator
    if S.browserStatusColor then
        Box("br_stdot",cx+8,stY+7,8,8,S.browserStatusColor,3)
        Txt("br_status",cx+22,stY+5,S.browserStatus,S.browserStatusColor,12,3)
    else
        hide("br_stdot")
        Txt("br_status",cx+8,stY+5,S.browserStatus,T.sub,12,3)
    end
end

local function renderEditor()
    local x,y,w,h=S.x,S.y,S.w,S.h
    local edY,pathBarY,searchBarY,liBarY,codeY,codeH,codeW,codeStartX=edLayout()
    local sbX=x+w-SB_W-2

    -- path bar
    Box("ed_pathbar",x,pathBarY,w,PATHBAR_H,T.panel,2)
    local pathDisp=S.currentPath=="" and "No file loaded — use Browser tab" or S.currentPath
    local maxPW=w-PAD*2-80
    if tw(pathDisp,11)>maxPW then
        pathDisp="…"..pathDisp:sub(-math.floor(maxPW/((11*0.535)))+1)
    end
    Txt("ed_path",x+PAD,pathBarY+4,pathDisp,T.sub,11,3)

    -- reload button
    if S.currentInst then
        local rbW=64; local rbX=x+w-rbW-PAD
        Box("ed_reload",rbX,pathBarY+3,rbW,16,inB(rbX,pathBarY+3,rbW,16) and T.accentHi or T.panel,3)
        Txt("ed_reload_t",rbX+rbW/2,pathBarY+11,"↺ Reload",T.sub,10,4,true)
    else hide("ed_reload"); hide("ed_reload_t") end

    -- search bar
    if S.searchOpen then
        Box("ed_srch_bg",x,searchBarY,w,22,Color3.fromRGB(18,18,28),3)
        Ln("ed_srch_bl",x,searchBarY+22,x+w,searchBarY+22,nil,1,4)
        Txt("ed_srch_lbl",x+PAD,searchBarY+5,"Find:",T.sub,11,4)
        local qx=x+PAD+40; local qw=220
        Box("ed_srch_box",qx,searchBarY+3,qw,16,T.panel,3)
        Outline("ed_srch_box_o",qx,searchBarY+3,qw,16,S.searchFocused and T.accent or T.border,4)
        local qd=S.searchQuery..(S.searchFocused and (math.floor(tick()*2)%2==0 and "|" or "") or "")
        Txt("ed_srch_q",qx+4,searchBarY+5,qd,T.text,11,4)
        local matchStr=#S.searchMatches>0 and (S.searchMatchIdx.."/"..#S.searchMatches.." matches") or "no matches"
        Txt("ed_srch_mc",qx+qw+8,searchBarY+5,matchStr,#S.searchMatches>0 and T.success or T.sub,11,4)
        Txt("ed_srch_esc",x+w-50,searchBarY+5,"ESC close",T.sub,10,4)
    else
        for _,id in ipairs({"ed_srch_bg","ed_srch_bl","ed_srch_lbl","ed_srch_box",
            "ed_srch_box_o","ed_srch_q","ed_srch_mc","ed_srch_esc"}) do hide(id) end
    end

    -- code background
    Box("ed_codebg",x,codeY,w,codeH,T.surface,1)
    Box("ed_lnbg",x,codeY,LN_W,codeH,T.bg,2)
    Box("ed_diffgutter",x+LN_W,codeY,DIFF_W,codeH,T.bg,2)
    Ln("ed_lnborder",x+LN_W+DIFF_W,codeY,x+LN_W+DIFF_W,codeY+codeH,nil,1,3)

    local visLines=math.floor(codeH/LINE_H)
    local totalLines=#S.lines
    local maxScroll=math.max(0,totalLines-visLines)
    S.scroll=math.max(0,math.min(S.scroll,maxScroll))

    local maxLineLen=0
    for _,l in ipairs(S.lines) do if #l>maxLineLen then maxLineLen=#l end end
    local visChars=math.floor(codeW/CHAR_W)
    local maxScrollX=math.max(0,maxLineLen-visChars)
    S.scrollX=math.max(0,math.min(S.scrollX,maxScrollX))

    -- build search match set
    local matchSet={}
    for _,li in ipairs(S.searchMatches) do matchSet[li]=true end

    local cursorVisible=false
    for i=1,visLines do
        local li=i+S.scroll; local lineY=codeY+(i-1)*LINE_H
        local isCur=li==S.cursorLine and S.focused

        -- search highlight
        if S.searchOpen and matchSet[li] then
            local isCurMatch=(S.searchMatches[S.searchMatchIdx]==li)
            Box("ed_shi_"..i,codeStartX,lineY,codeW,LINE_H,isCurMatch and T.srchCur or T.srchHi,2)
        else hide("ed_shi_"..i) end

        -- cursor line highlight
        if isCur then
            Box("ed_curhl_"..i,codeStartX,lineY,codeW,LINE_H,Color3.fromRGB(32,32,44),2)
        else hide("ed_curhl_"..i) end

        -- diff gutter
        if li<=#S.lines then
            local orig=S.originalLines[li]
            local curr=S.lines[li]
            if orig==nil then
                Box("ed_dif_"..i,x+LN_W,lineY,DIFF_W,LINE_H,T.diffAdd,3)
            elseif orig~=curr then
                Box("ed_dif_"..i,x+LN_W,lineY,DIFF_W,LINE_H,T.diffChg,3)
            else hide("ed_dif_"..i) end
        else hide("ed_dif_"..i) end

        if li<=totalLines then
            Txt("ed_ln_"..i,x+LN_W-4,lineY+2,tostring(li),
                li==S.cursorLine and T.accent or Color3.fromRGB(70,70,90),11,3,true)

            -- horizontal clip: slice string to visible char range
            local lineStr=S.lines[li]
            local charStart=S.scrollX+1
            local charEnd=math.min(#lineStr,S.scrollX+visChars+2)
            local visStr=lineStr:sub(charStart,charEnd)
            local spans=highlight(visStr)
            local ox=codeStartX
            hidePrefix("ed_sp_"..i.."_")
            for si,sp in ipairs(spans) do
                local spW=tw(sp[1],13)
                if ox+spW>codeStartX+codeW then
                    local avail=math.floor((codeStartX+codeW-ox)/CHAR_W)
                    if avail>0 then Txt("ed_sp_"..i.."_"..si,ox,lineY+2,sp[1]:sub(1,avail),sp[2],13,4) end
                    hidePrefix("ed_sp_"..i.."_"..(si+1))
                    break
                end
                Txt("ed_sp_"..i.."_"..si,ox,lineY+2,sp[1],sp[2],13,4)
                ox=ox+spW
            end
        else
            hide("ed_ln_"..i); hidePrefix("ed_sp_"..i.."_")
            hide("ed_dif_"..i); hide("ed_shi_"..i)
        end

        -- cursor
        if isCur and math.floor(tick()*2)%2==0 then
            local cur=S.lines[S.cursorLine] or ""
            local charsB=math.max(0,S.cursorChar-1-S.scrollX)
            local cx=codeStartX+charsB*CHAR_W
            if cx>=codeStartX and cx<codeStartX+codeW then
                Box("ed_cur",cx,lineY+2,2,LINE_H-4,T.cursor,5)
                cursorVisible=true
            end
        end
    end
    if not cursorVisible then hide("ed_cur") end

    -- clean up extra rows
    for i=visLines+1,visLines+6 do
        hide("ed_curhl_"..i); hide("ed_ln_"..i); hide("ed_dif_"..i); hide("ed_shi_"..i)
        hidePrefix("ed_sp_"..i.."_")
    end

    -- vertical scrollbar
    if totalLines>visLines then
        local tbH=codeH-4; local sH=math.max(20,tbH*(visLines/totalLines))
        local sY=codeY+2+(tbH-sH)*(S.scroll/math.max(1,maxScroll))
        Box("ed_sb_tr",sbX,codeY+2,SB_W,tbH,Color3.fromRGB(22,22,30),2)
        Box("ed_sb_th",sbX,sY,SB_W,sH,T.border,3)
    else hide("ed_sb_tr"); hide("ed_sb_th") end

    -- horizontal scrollbar
    local hsbY=codeY+codeH
    Box("ed_hsb_bg",x+LN_W+DIFF_W,hsbY,codeW,HSB_H,Color3.fromRGB(22,22,30),2)
    if maxScrollX>0 then
        local thW=math.max(30,codeW*(visChars/math.max(1,maxLineLen)))
        local thX=x+LN_W+DIFF_W+(codeW-thW)*(S.scrollX/math.max(1,maxScrollX))
        Box("ed_hsb_th",thX,hsbY+1,thW,HSB_H-2,T.border,3)
    else hide("ed_hsb_th") end

    -- bottom bar
    local bbY=y+h-BBH
    Box("ed_bb",x,bbY,w,BBH,T.panel,2)
    Ln("ed_bbl",x,bbY,x+w,bbY,nil,1,3)
    Txt("ed_li",x+PAD,bbY+10,"Ln "..S.cursorLine.." / "..totalLines.."   Col "..S.cursorChar,T.sub,11,3)
    Txt("ed_mode",x+210,bbY+10,S.focused and "  EDITING" or "  READ ONLY",S.focused and T.success or T.sub,11,3)
    -- auto-apply indicator
    if S.autoApply then
        Box("ed_aa_dot",x+330,bbY+13,6,6,T.success,3)
        Txt("ed_aa_lbl",x+340,bbY+9,"AUTO x"..S.autoApplyCount,T.success,10,3)
    else hide("ed_aa_dot"); hide("ed_aa_lbl") end
    if S.editorStatus~="" then
        Txt("ed_st",x+420,bbY+10,S.editorStatus,S.editorStatusColor or T.sub,11,3)
    else hide("ed_st") end
    local abW=150; local abX=x+w-abW-PAD; local abY=bbY+6
    Box("ed_ap",abX,abY,abW,24,inB(abX,abY,abW,24) and T.accentHi or T.accent,3)
    Txt("ed_ap_t",abX+abW/2,abY+12,"Apply via setgc",T.text,12,4,true)
end

local function renderLineBar()
    local x,y,w,h=S.x,S.y,S.w,S.h
    local _,_,_,liBarY=edLayout()
    Box("li_bg",x,liBarY,w,LIBAR_H,Color3.fromRGB(18,18,26),6)
    Ln("li_bot",x,liBarY+LIBAR_H,x+w,liBarY+LIBAR_H,nil,1,7)

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
    Txt("li_label",x+PAD,liBarY+5,label,T.sub,11,7)
    local word=displayLine:match("^([%w_]+)")
    if word and KEYWORDS[word] then
        Txt("li_kw",x+PAD+labelW,liBarY+5,word,T.accent,11,7)
        local rest=displayLine:sub(#word+1)
        local maxW=w-PAD*2-labelW-tw(word,11)-10
        if tw(rest,11)>maxW then rest=rest:sub(1,math.max(1,math.floor(maxW/(11*0.535)))).."…" end
        Txt("li_rest",x+PAD+labelW+tw(word,11),liBarY+5,rest,T.text,11,7); hide("li_plain")
    else
        local maxW=w-PAD*2-labelW-10
        if tw(displayLine,11)>maxW then displayLine=displayLine:sub(1,math.max(1,math.floor(maxW/(11*0.535)))).."…" end
        Txt("li_plain",x+PAD+labelW,liBarY+5,displayLine,T.text,11,7)
        hide("li_kw"); hide("li_rest")
    end
end

local function renderSettings()
    local x,y,w,h=S.x,S.y,S.w,S.h
    local cx=x+PAD; local cw=w-PAD*2
    local cy=y+HEADER_H+PAD
    local ch=h-HEADER_H-PAD*2

    -- panel background
    Box("st_bg",cx,cy,cw,ch,T.surface,2)
    Outline("st_bg_o",cx,cy,cw,ch,T.border,3)

    local lx=cx+14  -- left content x
    local ry=cy     -- rolling Y cursor

    -- ===== Section: Hotkey =====
    ry=ry+10
    Box("st_s1_tag",lx,ry,cw-28,18,T.tag,3)
    Txt("st_s1_lbl",lx+8,ry+3,"MENU HOTKEY",T.accent,10,4)
    ry=ry+26
    Txt("st_s1_sub",lx,ry,"Press button then tap any key to rebind",T.sub,11,4)
    ry=ry+18

    local btnW=140; local btnH=26; local btnY=ry
    local listening=S.listeningForKey
    Box("st_keybtn",lx,btnY,btnW,btnH,listening and T.accentDim or T.panel2,3)
    Outline("st_keybtn_o",lx,btnY,btnW,btnH,listening and T.accent or T.border,3)
    Txt("st_keytxt",lx+btnW/2,btnY+btnH/2,
        listening and "Press any key…" or S.menuKeyName,
        listening and T.accentHi or T.text,12,4,true)
    Txt("st_keynote",lx+btnW+12,btnY+7,"Current: "..S.menuKeyName,T.sub,11,4)
    ry=ry+btnH+16

    -- divider
    Box("st_div1",cx+8,ry,cw-16,1,T.sep,3)
    ry=ry+10

    -- ===== Section: Diff Gutter =====
    Box("st_s2_tag",lx,ry,cw-28,18,T.tag,3)
    Txt("st_s2_lbl",lx+8,ry+3,"DIFF GUTTER",T.accent,10,4)
    ry=ry+26
    Box("st_dif1",lx,ry+1,10,10,T.diffAdd,3)
    Txt("st_dif1t",lx+16,ry,"New line (added since load)",T.sub,11,4)
    ry=ry+16
    Box("st_dif2",lx,ry+1,10,10,T.diffChg,3)
    Txt("st_dif2t",lx+16,ry,"Modified line",T.sub,11,4)
    ry=ry+22

    -- divider
    Box("st_div2",cx+8,ry,cw-16,1,T.sep,3)
    ry=ry+10

    -- ===== Section: Auto-Apply =====
    Box("st_s3_tag",lx,ry,cw-28,18,T.tag,3)
    Txt("st_s3_lbl",lx+8,ry+3,"AUTO-APPLY",T.accent,10,4)
    ry=ry+26
    Txt("st_aa_sub",lx,ry,"Keeps ACS values alive after gun events (fire, reload, equip)",T.sub,11,4)
    ry=ry+18

    local aaOn=S.autoApply
    local aaBtnW=100; local aaBtnH=26
    Box("st_aatog",lx,ry,aaBtnW,aaBtnH,aaOn and T.success or T.panel2,3)
    Outline("st_aatog_o",lx,ry,aaBtnW,aaBtnH,aaOn and T.success or T.border,3)
    Txt("st_aatog_t",lx+aaBtnW/2,ry+aaBtnH/2,
        aaOn and "● ON" or "○ OFF",
        aaOn and T.bg or T.textDim,12,4,true)

    -- interval
    Txt("st_aaint_l",lx+aaBtnW+12,ry+7,"Every",T.sub,11,4)
    local aiX=lx+aaBtnW+58; local aiW=48
    Box("st_aaint",aiX,ry+2,aiW,22,T.panel2,3)
    Outline("st_aaint_o",aiX,ry+2,aiW,22,S.autoApplyFocused and T.accent or T.border,4)
    local aiDisp=S.autoApplyIntervalInput..(S.autoApplyFocused and (math.floor(tick()*2)%2==0 and "|" or "") or "")
    Txt("st_aaint_t",aiX+4,ry+6,aiDisp,T.text,11,4)
    Txt("st_aaint_s",aiX+aiW+6,ry+7,"sec",T.sub,11,4)

    ry=ry+aaBtnH+6
    if aaOn then
        Txt("st_aacnt",lx,ry,"Applied "..S.autoApplyCount.." time(s) this session — interval: "
            ..S.autoApplyInterval.."s",T.success,11,4)
    else
        Txt("st_aacnt",lx,ry,"Toggle ON to start. Only applies while Editor tab is active.",T.sub,11,4)
    end
    ry=ry+22

    -- divider
    Box("st_div3",cx+8,ry,cw-16,1,T.sep,3)
    ry=ry+10

    -- ===== Section: Shortcuts =====
    Box("st_s4_tag",lx,ry,cw-28,18,T.tag,3)
    Txt("st_s4_lbl",lx+8,ry+3,"SHORTCUTS",T.accent,10,4)
    ry=ry+26
    local shortcuts={
        {"Ctrl + F","Open search bar in editor"},
        {"Enter","Next search match"},
        {"Escape","Close search bar"},
        {"Ctrl + V","Paste into path / search inputs"},
        {S.menuKeyName,"Toggle this menu"},
    }
    for idx,sc in ipairs(shortcuts) do
        Box("st_sc_k_"..idx,lx,ry,62,15,T.panel2,3)
        Txt("st_sc_kt_"..idx,lx+31,ry+2,sc[1],T.accent,10,4,true)
        Txt("st_sc_vt_"..idx,lx+70,ry+2,sc[2],T.sub,11,4)
        ry=ry+18
    end
end

-- ===== Input handler =====
local function handleInput(dt)
    if not S.visible then return end
    local x,y,w,h=S.x,S.y,S.w,S.h
    local click=input.clicked["m1"]
    local held=input.held["m1"]
    local mx,my=getMouse().X,getMouse().Y

    -- close button
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
    if click and inB(x,y+TITLE_H,110,TAB_H) then
        S.tab="browser"; S.focused=false; S.pathFocused=false; S.searchFocused=false end
    if click and inB(x+110,y+TITLE_H,110,TAB_H) then
        S.tab="editor"; S.pathFocused=false end
    if click and inB(x+220,y+TITLE_H,110,TAB_H) then
        S.tab="settings"; S.focused=false; S.pathFocused=false; S.searchFocused=false end

    -- settings
    if S.tab=="settings" then
        local lx=x+PAD+14
        local ry=y+HEADER_H+PAD+10
        local btnY=ry+44
        if click and inB(lx,btnY,140,26) then S.listeningForKey=true end
        if S.listeningForKey then
            for name,id in pairs(KEY_IDS) do
                if name~="m1" and name~="m2" and name~="lshift" and name~="rshift"
                   and name~="shift" and name~="escape" then
                    if input.clicked[name] then
                        S.menuKey=id; S.menuKeyName=name:upper()
                        S.listeningForKey=false; break
                    end
                end
            end
        end
        -- auto-apply: positioned after hotkey (btnY+26+16) + divider(11) + section header(18) + subs(26+18) = btnY+115
        local aaY=btnY+26+16+11+18+26+18
        if click and inB(lx,aaY,100,26) then
            S.autoApply=not S.autoApply; S.autoApplyTimer=0
            if not S.autoApply then S.autoApplyCount=0 end
        end
        local aiX=lx+58+100; local aiY=aaY+2
        if click and inB(aiX,aiY,48,22) then
            S.autoApplyFocused=true
        elseif click then
            if S.autoApplyFocused then
                local v=tonumber(S.autoApplyIntervalInput)
                if v and v>0 then S.autoApplyInterval=math.max(0.5,v)
                else S.autoApplyIntervalInput=tostring(S.autoApplyInterval) end
            end
            S.autoApplyFocused=false
        end
        if S.autoApplyFocused then
            local numKeys={"0","1","2","3","4","5","6","7","8","9","period","backspace","enter"}
            for _,k in ipairs(numKeys) do
                if keyRepeating(k,dt) then
                    if k=="backspace" then S.autoApplyIntervalInput=S.autoApplyIntervalInput:sub(1,-2)
                    elseif k=="enter" then
                        S.autoApplyFocused=false
                        local v=tonumber(S.autoApplyIntervalInput)
                        if v and v>0 then S.autoApplyInterval=math.max(0.5,v)
                        else S.autoApplyIntervalInput=tostring(S.autoApplyInterval) end
                    else
                        local c=charMap[k] or k
                        if (c>="0" and c<="9") or c=="." then
                            S.autoApplyIntervalInput=S.autoApplyIntervalInput..c
                        end
                    end
                end
            end
        end
        return
    end

    -- browser
    if S.tab=="browser" then
        local cy=y+HEADER_H+PAD
        local lh=h-HEADER_H-PAD*2-28
        local scanBtnY=cy+lh-32
        local rx=x+PAD+SIDEBAR_W+PAD; local rw=w-SIDEBAR_W-PAD*3
        local piy=cy+28; local piw=rw-16-76; local lpx=rx+8+piw+6
        local slY=cy+58; local loadBtnY=cy+lh-32
        local toolListY=cy+26
        local toolVis=math.floor((scanBtnY-toolListY-4)/22)
        local sVis=math.floor((loadBtnY-slY-4)/22)

        if click and inB(x+PAD,scanBtnY,SIDEBAR_W,28) then
            S.tools=scanTools(); S.toolSel=1; S.scripts={}
            if #S.tools==0 then
                S.browserStatus="No tools found in backpack"; S.browserStatusColor=T.warn
            else
                S.scripts=getScripts(S.tools[1].inst)
                local mem=S.toolMemory[S.tools[1].inst.Name]
                S.scriptSel=math.min(mem or 1,math.max(1,#S.scripts))
                S.browserStatus="Found "..#S.tools.." tool(s) — "..#S.scripts.." script(s)"
                S.browserStatusColor=T.success
            end
        end

        for i=1,toolVis do
            if S.tools[i] and click and inB(x+PAD+1,toolListY+(i-1)*22,SIDEBAR_W-2,21) then
                S.toolSel=i
                S.scripts=getScripts(S.tools[i].inst)
                local mem=S.toolMemory[S.tools[i].inst.Name]
                S.scriptSel=math.min(mem or 1,math.max(1,#S.scripts))
                S.browserStatus=S.tools[i].label.." — "..#S.scripts.." script(s)"
                S.browserStatusColor=T.sub
            end
        end

        if click then
            if inB(rx+8,piy,piw,22) then S.pathFocused=true; S.focused=false
            elseif not inB(lpx,piy,70,22) then S.pathFocused=false end
        end

        if S.pathFocused then
            -- Ctrl+V paste
            if isCtrl() and input.clicked["v"] then
                local ok,clip=pcall(getclipboard)
                if ok and type(clip)=="string" then
                    S.pathInput=S.pathInput..clip:gsub("[^\32-\126]","")
                end
            end
            local typeKeys={"a","b","c","d","e","f","g","h","i","j","k","l","m",
                "n","o","p","q","r","s","t","u","v","w","x","y","z",
                "0","1","2","3","4","5","6","7","8","9",
                "space","period","minus","slash","backspace","enter"}
            for _,k in ipairs(typeKeys) do
                if keyRepeating(k,dt) then
                    if k=="backspace" then S.pathInput=S.pathInput:sub(1,-2)
                    elseif k=="enter" then S.pathFocused=false
                    else
                        local c=charMap[k] or k
                        if #c==1 then
                            if isShift() and shiftMap[c] then c=shiftMap[c]
                            elseif isShift() then c=c:upper() end
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
                    S.lines=lines; S.originalLines=deepCopy(lines)
                    S.currentPath=inst:GetFullName(); S.currentInst=inst
                    S.cursorLine=1; S.cursorChar=1; S.scroll=0; S.scrollX=0; S.tab="editor"
                    S.editorStatus="Loaded "..#lines.." lines"; S.editorStatusColor=T.success
                else S.browserStatus=err; S.browserStatusColor=T.err end
            else S.browserStatus="Path not found or not a script"; S.browserStatusColor=T.err end
        end

        for i=1,sVis do
            if S.scripts[i] and click and inB(rx+1,slY+(i-1)*22,rw-2,21) then
                S.scriptSel=i
                if S.tools[S.toolSel] then
                    S.toolMemory[S.tools[S.toolSel].inst.Name]=i
                end
            end
        end

        if click and #S.scripts>0 and inB(rx,loadBtnY,rw,28) then
            local sc=S.scripts[S.scriptSel]
            if sc then
                local lines,err=decompileToLines(sc.inst)
                if lines then
                    S.lines=lines; S.originalLines=deepCopy(lines)
                    S.currentPath=sc.inst:GetFullName(); S.currentInst=sc.inst
                    S.cursorLine=1; S.cursorChar=1; S.scroll=0; S.scrollX=0; S.tab="editor"
                    S.editorStatus="Loaded "..#lines.." lines"; S.editorStatusColor=T.success
                else S.browserStatus=err; S.browserStatusColor=T.err end
            end
        end
    end

    -- editor
    if S.tab=="editor" then
        local edY,pathBarY,searchBarY,liBarY,codeY,codeH,codeW,codeStartX=edLayout()
        local visLines=math.floor(codeH/LINE_H)
        local totalLines=#S.lines
        local maxScroll=math.max(0,totalLines-visLines)
        local sbX=x+w-SB_W-2

        local maxLineLen=0
        for _,l in ipairs(S.lines) do if #l>maxLineLen then maxLineLen=#l end end
        local visChars=math.floor(codeW/CHAR_W)
        local maxScrollX=math.max(0,maxLineLen-visChars)

        -- reload button
        local rbW=64; local rbX=x+w-rbW-PAD
        if S.currentInst and click and inB(rbX,pathBarY+3,rbW,16) then
            local lines,err=decompileToLines(S.currentInst)
            if lines then
                S.lines=lines; S.originalLines=deepCopy(lines)
                S.scroll=math.max(0,math.min(maxScroll,S.scroll))
                S.cursorLine=math.min(S.cursorLine,math.max(1,#lines))
                S.editorStatus="Reloaded "..#lines.." lines"; S.editorStatusColor=T.success
            else S.editorStatus="Reload failed"; S.editorStatusColor=T.err end
        end

        -- Ctrl+F search toggle
        if isCtrl() and input.clicked["f"] then
            S.searchOpen=not S.searchOpen
            if S.searchOpen then S.searchFocused=true
            else S.searchFocused=false; S.searchQuery=""; S.searchMatches={} end
        end
        -- Escape closes search
        if S.searchOpen and input.clicked["escape"] then
            S.searchOpen=false; S.searchFocused=false; S.searchQuery=""; S.searchMatches={}
        end

        -- search bar input
        if S.searchOpen then
            local qx=x+PAD+40; local qw=220
            if click and inB(qx,searchBarY+3,qw,16) then
                S.searchFocused=true; S.focused=false
            end
            if S.searchFocused then
                -- Ctrl+V paste into search
                if isCtrl() and input.clicked["v"] then
                    local ok,clip=pcall(getclipboard)
                    if ok and type(clip)=="string" then
                        S.searchQuery=S.searchQuery..clip:gsub("[^\32-\126]","")
                        S.searchMatches=buildSearchMatches(S.searchQuery); S.searchMatchIdx=1
                    end
                end
                local typeKeys={"a","b","c","d","e","f","g","h","i","j","k","l","m",
                    "n","o","p","q","r","s","t","u","v","w","x","y","z",
                    "0","1","2","3","4","5","6","7","8","9","space","minus","period",
                    "slash","backspace","enter"}
                for _,k in ipairs(typeKeys) do
                    if keyRepeating(k,dt) then
                        if k=="backspace" then
                            S.searchQuery=S.searchQuery:sub(1,-2)
                            S.searchMatches=buildSearchMatches(S.searchQuery); S.searchMatchIdx=1
                        elseif k=="enter" then
                            if #S.searchMatches>0 then
                                S.searchMatchIdx=S.searchMatchIdx%#S.searchMatches+1
                                local ml=S.searchMatches[S.searchMatchIdx]
                                S.cursorLine=ml
                                S.scroll=math.max(0,math.min(maxScroll,ml-math.floor(visLines/2)))
                            end
                        else
                            local c=charMap[k] or k
                            if #c==1 then
                                S.searchQuery=S.searchQuery..c
                                S.searchMatches=buildSearchMatches(S.searchQuery); S.searchMatchIdx=1
                                if #S.searchMatches>0 then
                                    local ml=S.searchMatches[1]
                                    S.cursorLine=ml
                                    S.scroll=math.max(0,math.min(maxScroll,ml-math.floor(visLines/2)))
                                end
                            end
                        end
                    end
                end
            end
        end

        -- mouse wheel scroll
        if wheelDelta~=0 then
            if inB(x,codeY,w,codeH) then
                S.scroll=math.max(0,math.min(maxScroll,S.scroll+wheelDelta))
            end
            wheelDelta=0
        end

        -- vertical scrollbar drag
        if click and inB(sbX,codeY,SB_W+2,codeH) then S.scrollDragging=true end
        if not held then S.scrollDragging=false end
        if S.scrollDragging and totalLines>visLines then
            local tbH=codeH-4; local sH=math.max(20,tbH*(visLines/totalLines))
            local ratio=(my-codeY-sH/2)/math.max(1,tbH-sH)
            S.scroll=math.max(0,math.min(maxScroll,math.floor(ratio*maxScroll+0.5)))
        end

        -- horizontal scrollbar drag
        local hsbY=codeY+codeH; local hsbStartX=x+LN_W+DIFF_W
        if click and inB(hsbStartX,hsbY,codeW,HSB_H) then S.scrollXDragging=true end
        if not held then S.scrollXDragging=false end
        if S.scrollXDragging and maxScrollX>0 then
            local thW=math.max(30,codeW*(visChars/math.max(1,maxLineLen)))
            local ratio=(mx-hsbStartX-thW/2)/math.max(1,codeW-thW)
            S.scrollX=math.max(0,math.min(maxScrollX,math.floor(ratio*maxScrollX+0.5)))
        end

        -- click to place cursor
        if click then
            if inB(codeStartX,codeY,codeW,codeH) then
                S.focused=true; S.pathFocused=false; S.searchFocused=false
                local cl=S.scroll+math.floor((my-codeY)/LINE_H)+1
                S.cursorLine=math.max(1,math.min(cl,math.max(1,totalLines)))
                local relX=mx-codeStartX
                local approxChar=S.scrollX+math.floor(relX/CHAR_W)+1
                S.cursorChar=math.max(1,math.min(approxChar,#(S.lines[S.cursorLine] or "")+1))
            elseif not (S.searchOpen and inB(x,searchBarY,w,22)) then
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
                        if S.cursorChar>1 then
                            S.cursorChar=S.cursorChar-1
                            if S.cursorChar-1<S.scrollX then S.scrollX=math.max(0,S.cursorChar-1) end
                        elseif S.cursorLine>1 then
                            S.cursorLine=S.cursorLine-1
                            S.cursorChar=#(S.lines[S.cursorLine] or "")+1
                        end
                    elseif k=="right" then
                        local ll=#(S.lines[S.cursorLine] or "")
                        if S.cursorChar<=ll then
                            S.cursorChar=S.cursorChar+1
                            if S.cursorChar>S.scrollX+visChars then S.scrollX=S.cursorChar-visChars end
                        elseif S.cursorLine<totalLines then
                            S.cursorLine=S.cursorLine+1; S.cursorChar=1; S.scrollX=0
                        end
                    elseif k=="pageup" then
                        S.scroll=math.max(0,S.scroll-visLines)
                        S.cursorLine=math.max(1,S.cursorLine-visLines)
                    elseif k=="pagedown" then
                        S.scroll=math.min(math.max(0,totalLines-visLines),S.scroll+visLines)
                        S.cursorLine=math.min(math.max(1,totalLines),S.cursorLine+visLines)
                    elseif k=="home" then S.cursorChar=1; S.scrollX=0
                    elseif k=="end" then
                        S.cursorChar=#(S.lines[S.cursorLine] or "")+1
                        if S.cursorChar>S.scrollX+visChars then
                            S.scrollX=math.max(0,S.cursorChar-visChars)
                        end
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
                            if S.cursorChar-1<S.scrollX then S.scrollX=math.max(0,S.cursorChar-1) end
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
                        S.cursorLine=S.cursorLine+1; S.cursorChar=#indent+1; S.scrollX=0
                        if S.cursorLine>S.scroll+visLines then S.scroll=S.scroll+1 end
                    elseif k=="tab" then
                        S.lines[S.cursorLine]=cur:sub(1,S.cursorChar-1).."    "..cur:sub(S.cursorChar)
                        S.cursorChar=S.cursorChar+4
                        if S.cursorChar>S.scrollX+visChars then S.scrollX=S.cursorChar-visChars end
                    else
                        if not isCtrl() then
                            local c=charMap[k] or k
                            if #c==1 then
                                if isShift() and shiftMap[c] then c=shiftMap[c]
                                elseif isShift() then c=c:upper() end
                                S.lines[S.cursorLine]=cur:sub(1,S.cursorChar-1)..c..cur:sub(S.cursorChar)
                                S.cursorChar=S.cursorChar+1
                                if S.cursorChar>S.scrollX+visChars then S.scrollX=S.cursorChar-visChars end
                            end
                        end
                    end
                    break
                end
            end
        end

        -- apply button (with GC matcher)
        local abW=150; local abX=x+w-abW-PAD; local abY=y+h-BBH+6
        if click and inB(abX,abY,abW,24) then
            local applied,failed,notInGC=applyLinesGC(S.lines)
            local parts={}
            if applied>0 then table.insert(parts,"Applied "..applied) end
            if #notInGC>0 then
                local ng=#notInGC>3
                    and table.concat(notInGC,",",1,3).."…"
                    or table.concat(notInGC,",")
                table.insert(parts,"Not in GC: "..ng)
                S.editorStatusColor=T.warn
            elseif #failed>0 then
                table.insert(parts,"Parse err: "..table.concat(failed,",",1,math.min(3,#failed)))
                S.editorStatusColor=T.warn
            else S.editorStatusColor=T.success end
            S.editorStatus=table.concat(parts," | ")
        end
    end
end

-- ===== Main loop =====
RunService.RenderStepped:Connect(function(dt)
    pollInput()

    local menuKeyDown=iskeypressed(S.menuKey)
    if menuKeyDown and not prevKeys["__menukey"] then
        S.visible=not S.visible
        if not S.visible then hidePrefix(""); setrobloxinput(true) end
    end
    prevKeys["__menukey"]=menuKeyDown

    if not S.visible then setrobloxinput(true); return end

    handleInput(dt)

    -- auto-apply timer
    if S.autoApply and S.tab=="editor" and #S.lines>0 then
        S.autoApplyTimer=S.autoApplyTimer+dt
        if S.autoApplyTimer>=S.autoApplyInterval then
            S.autoApplyTimer=0
            S.autoApplyCount=S.autoApplyCount+1
            applyLinesGC(S.lines)
        end
    end

    if S.pathFocused or S.searchFocused or (S.tab=="editor" and S.focused) then
        setrobloxinput(false)
    else
        setrobloxinput(true)
    end

    renderWindow()

    if S.tab~=prevTab then
        if S.tab=="browser" then
            hidePrefix("ed_"); hidePrefix("li_"); hidePrefix("st_")
        elseif S.tab=="editor" then
            hidePrefix("br_"); hidePrefix("st_")
        elseif S.tab=="settings" then
            hidePrefix("br_"); hidePrefix("ed_"); hidePrefix("li_")
        end
        prevTab=S.tab
    end

    if S.tab=="browser" then renderBrowser()
    elseif S.tab=="editor" then renderEditor(); renderLineBar()
    elseif S.tab=="settings" then renderSettings() end
end)
