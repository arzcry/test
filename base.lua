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
    hintNum = Color3.fromRGB(100, 160, 255),
    hintBool= Color3.fromRGB(255, 150, 80),
    hintOk  = Color3.fromRGB(48, 209, 88),
    hintBad = Color3.fromRGB(255, 69, 58),
    hintVec = Color3.fromRGB(200, 130, 255),
}

local v2 = Vector2.new
local D = {}
local CHAR_W = 13 * 0.535
local CR = 5

local THEMES = {
    {name="Dark",     bg=Color3.fromRGB(10,10,14),  surface=Color3.fromRGB(16,16,22),  panel=Color3.fromRGB(22,22,30),  panel2=Color3.fromRGB(28,28,40),  border=Color3.fromRGB(44,44,58),   accent=Color3.fromRGB(99,102,241),  accentHi=Color3.fromRGB(130,133,255), accentDim=Color3.fromRGB(50,52,140)},
    {name="OLED",     bg=Color3.fromRGB(0,0,0),     surface=Color3.fromRGB(10,10,10),  panel=Color3.fromRGB(16,16,16),  panel2=Color3.fromRGB(22,22,22),  border=Color3.fromRGB(40,40,40),   accent=Color3.fromRGB(99,102,241),  accentHi=Color3.fromRGB(130,133,255), accentDim=Color3.fromRGB(40,42,120)},
    {name="Midnight", bg=Color3.fromRGB(8,10,20),   surface=Color3.fromRGB(12,16,32),  panel=Color3.fromRGB(18,22,44),  panel2=Color3.fromRGB(22,28,56),  border=Color3.fromRGB(40,50,90),   accent=Color3.fromRGB(80,140,255),  accentHi=Color3.fromRGB(120,170,255), accentDim=Color3.fromRGB(30,60,140)},
    {name="Forest",   bg=Color3.fromRGB(8,14,10),   surface=Color3.fromRGB(12,20,14),  panel=Color3.fromRGB(16,28,18),  panel2=Color3.fromRGB(20,34,22),  border=Color3.fromRGB(36,60,40),   accent=Color3.fromRGB(48,200,90),   accentHi=Color3.fromRGB(80,220,120),  accentDim=Color3.fromRGB(20,80,36)},
    {name="Rose",     bg=Color3.fromRGB(18,10,12),  surface=Color3.fromRGB(26,14,18),  panel=Color3.fromRGB(34,18,24),  panel2=Color3.fromRGB(42,22,30),  border=Color3.fromRGB(80,40,52),   accent=Color3.fromRGB(240,80,120),  accentHi=Color3.fromRGB(255,120,150), accentDim=Color3.fromRGB(120,30,56)},
    {name="Slate",    bg=Color3.fromRGB(15,17,21),  surface=Color3.fromRGB(22,25,31),  panel=Color3.fromRGB(29,33,41),  panel2=Color3.fromRGB(36,41,51),  border=Color3.fromRGB(55,62,78),   accent=Color3.fromRGB(56,189,248),  accentHi=Color3.fromRGB(100,210,255), accentDim=Color3.fromRGB(20,80,120)},
    {name="Ember",    bg=Color3.fromRGB(16,10,8),   surface=Color3.fromRGB(24,14,10),  panel=Color3.fromRGB(32,18,12),  panel2=Color3.fromRGB(40,22,14),  border=Color3.fromRGB(80,44,28),   accent=Color3.fromRGB(251,146,60),  accentHi=Color3.fromRGB(255,180,100), accentDim=Color3.fromRGB(120,50,10)},
    {name="Arctic",   bg=Color3.fromRGB(10,14,18),  surface=Color3.fromRGB(14,20,28),  panel=Color3.fromRGB(18,26,38),  panel2=Color3.fromRGB(22,32,48),  border=Color3.fromRGB(40,58,80),   accent=Color3.fromRGB(120,220,200), accentHi=Color3.fromRGB(160,240,220), accentDim=Color3.fromRGB(30,90,80)},
}

local THEME_FILE = "acs_theme.json"
local function saveTheme(idx)
    pcall(function()
        writefile(THEME_FILE, game:GetService("HttpService"):JSONEncode({themeIdx=idx}))
    end)
end
local function loadSavedTheme()
    if not isfile(THEME_FILE) then return 1 end
    local ok,data=pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile(THEME_FILE))
    end)
    if ok and data and data.themeIdx then
        local idx=math.max(1,math.min(#THEMES,data.themeIdx))
        return idx
    end
    return 1
end

local function applyTheme(idx)
    local th=THEMES[idx]
    if not th then return end
    T.bg=th.bg; T.surface=th.surface; T.panel=th.panel; T.panel2=th.panel2
    T.border=th.border; T.accent=th.accent; T.accentHi=th.accentHi; T.accentDim=th.accentDim
end

local function Ln(id, x1, y1, x2, y2, color, thick, zi)
    if not D[id] then D[id] = Drawing.new("Line") end
    local d = D[id]
    d.From = v2(x1,y1); d.To = v2(x2,y2)
    d.Thickness = thick or 1; d.ZIndex = zi or 2; d.Visible = true
end
local function Box(id, x, y, w, h, color, zi, corner)
    if not D[id] then D[id] = Drawing.new("Square") end
    local d = D[id]
    d.Position = v2(x,y); d.Size = v2(w,h)
    d.Color = color; d.Filled = true; d.ZIndex = zi or 1
    d.Corner = corner or 0; d.Visible = true
end
local function Outline(id, x, y, w, h, color, zi, corner)
    if not D[id] then D[id] = Drawing.new("Square") end
    local d = D[id]
    d.Position = v2(x,y); d.Size = v2(w,h)
    d.Color = color; d.Filled = false; d.ZIndex = zi or 2
    d.Corner = corner or 0; d.Visible = true
end
local function Txt(id, x, y, str, color, size, zi, center)
    if not D[id] then D[id] = Drawing.new("Text") end
    local d = D[id]
    d.Position = v2(x,y); d.Text = tostring(str); d.Color = color
    d.Size = size or 13; d.Font = Drawing.Fonts.SystemBold; d.Outline = false
    d.Center = center or false; d.ZIndex = zi or 3; d.Visible = true
end
local function TxtCode(id, x, y, str, color, size, zi)
    if not D[id] then D[id] = Drawing.new("Text") end
    local d = D[id]
    d.Position = v2(x,y); d.Text = tostring(str); d.Color = color
    d.Size = size or 13; d.Font = Drawing.Fonts.Monospace; d.Outline = false
    d.Center = false; d.ZIndex = zi or 3; d.Visible = true
end
local function hide(id) if D[id] then D[id].Visible = false end end
local function hidePrefix(p)
    for k,d in pairs(D) do if k:sub(1,#p)==p then d.Visible=false end end
end
local function tw(s, sz) return #s*(sz or 13)*0.535 end

local function RBox(id, x, y, w, h, color, zi, r)
    Box(id.."_c", x, y, w, h, color, zi or 1)
end
local function hideRBox(id)
    hide(id.."_c")
end

local wheelDelta = 0
pcall(function()
    local m = player:GetMouse()
    m.WheelForward:Connect(function() wheelDelta = wheelDelta - 3 end)
    m.WheelBackward:Connect(function() wheelDelta = wheelDelta + 3 end)
end)

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

local PAD=10; local TITLE_H=34; local TAB_H=30
local HEADER_H=TITLE_H+TAB_H; local LINE_H=18; local SIDEBAR_W=220
local PATHBAR_H=22; local LIBAR_H=22; local BBH=36; local HSB_H=10
local DIFF_W=4; local LN_W=50; local SB_W=8
local TAB_BAR_H=26; local MAX_TABS=6
local prevTab=""

local S = {
    x=60,y=30,w=780,h=640,
    dragging=false,dragOX=0,dragOY=0,
    visible=true,
    tab="browser",
    tools={},toolSel=1,toolScroll=0,toolSearch="",toolSearchFocused=false,
    scripts={},scriptSel=1,
    pathInput="",pathFocused=false,
    browserStatus="Click Scan to load your inventory",
    browserStatusColor=nil,
    toolMemory={},
    lines={},
    originalLines={},
    scroll=0,scrollX=0,
    cursorLine=1,cursorChar=1,
    focused=false,
    editorStatus="",editorStatusColor=nil,
    currentPath="",
    currentInst=nil,
    editValueInst=nil, editValueType="",
    scrollDragging=false,
    scrollXDragging=false,
    searchOpen=false,
    searchQuery="",
    searchFocused=false,
    searchMatches={},
    searchMatchIdx=1,
    tabs={},
    activeTab=1,
    scriptSearch="",
    scriptSearchFocused=false,
    scriptSearchMode=false,
    scriptSearchResults={},
    scriptSearchScroll=0,
    scriptSearchFilter="scripts",
    keyRepeatTimer={},keyRepeatDelay=0.4,keyRepeatRate=0.05,
    autoApply=false,
    autoApplyInterval=3.0,
    autoApplyIntervalInput="3",
    autoApplyTimer=0,
    autoApplyCount=0,
    autoApplyFocused=false,
    menuKey=0x70,menuKeyName="F1",
    listeningForKey=false,
    undoStack={},
    redoStack={},
    browserFilter="scripts",
    browserSubTab="tool",
    themeIdx=loadSavedTheme(),
    gcBrowseMode=false,
    gcBrowseResults={},
    gcBrowseScroll=0,
    gcBrowseFilter="config",
    gcBrowseStatus="",
    presets={},
    presetSel=1,
    presetNameInput="",
    presetNameFocused=false,
    settingsScroll=0,
    settingsScrollDrag=false,
    settingsMaxScroll=400,
    lineJumpOpen=false,
    lineJumpInput="",
    lineJumpFocused=false,
    gcBulkSel={},
    gcBulkValue="",
    gcBulkFocused=false,
    pinnedScripts={},
    navStack={},
    navItems={},
    navScroll=0,
    navSel=1,
    explorerFilter="all",
    crossSearchOpen=false,
    crossSearchQuery="",
    crossSearchFocused=false,
    crossSearchResults={},
    diffPanelOpen=false,
    diffResults={},
}

local function deepCopy(t)
    local c={}; for i,v in ipairs(t) do c[i]=v end; return c
end

local function makeTabSnapshot()
    return {
        lines=S.lines, originalLines=S.originalLines,
        scroll=S.scroll, scrollX=S.scrollX,
        cursorLine=S.cursorLine, cursorChar=S.cursorChar,
        currentPath=S.currentPath, currentInst=S.currentInst,
        editorStatus=S.editorStatus, editorStatusColor=S.editorStatusColor,
        searchOpen=S.searchOpen, searchQuery=S.searchQuery,
        searchMatches=S.searchMatches, searchMatchIdx=S.searchMatchIdx,
        undoStack=S.undoStack, redoStack=S.redoStack,
        editValueInst=S.editValueInst, editValueType=S.editValueType,
    }
end
local function restoreTabSnapshot(t)
    S.lines=t.lines; S.originalLines=t.originalLines
    S.scroll=t.scroll; S.scrollX=t.scrollX
    S.cursorLine=t.cursorLine; S.cursorChar=t.cursorChar
    S.currentPath=t.currentPath; S.currentInst=t.currentInst
    S.editorStatus=t.editorStatus; S.editorStatusColor=t.editorStatusColor
    S.searchOpen=t.searchOpen or false; S.searchQuery=t.searchQuery or ""
    S.searchMatches=t.searchMatches or {}; S.searchMatchIdx=t.searchMatchIdx or 1
    S.undoStack=t.undoStack or {}; S.redoStack=t.redoStack or {}
    S.editValueInst=t.editValueInst or nil; S.editValueType=t.editValueType or ""
    S.focused=false
end
local function getTabLabel(t)
    if not t or t.currentPath=="" then return "Untitled" end
    return t.currentPath:match("[^%.]+$") or "?"
end
local function saveActiveTab()
    if #S.tabs>0 then S.tabs[S.activeTab]=makeTabSnapshot() end
end
local function switchTab(idx)
    saveActiveTab(); restoreTabSnapshot(S.tabs[idx]); S.activeTab=idx
end
local function newTab()
    if #S.tabs>=MAX_TABS then return end
    saveActiveTab()
    table.insert(S.tabs,{
        lines={},originalLines={},scroll=0,scrollX=0,
        cursorLine=1,cursorChar=1,currentPath="",currentInst=nil,
        editorStatus="New tab — type key=value pairs, or load a script via Browser",
        editorStatusColor=nil,
        searchOpen=false,searchQuery="",searchMatches={},searchMatchIdx=1,
    })
    restoreTabSnapshot(S.tabs[#S.tabs]); S.activeTab=#S.tabs
end
local function closeTab(idx)
    if #S.tabs<=1 then
        S.tabs[1]={lines={},originalLines={},scroll=0,scrollX=0,
            cursorLine=1,cursorChar=1,currentPath="",currentInst=nil,
            editorStatus="",editorStatusColor=nil,
            searchOpen=false,searchQuery="",searchMatches={},searchMatchIdx=1}
        restoreTabSnapshot(S.tabs[1]); S.activeTab=1; return
    end
    table.remove(S.tabs,idx)
    local newIdx=math.max(1,math.min(idx,#S.tabs))
    restoreTabSnapshot(S.tabs[newIdx]); S.activeTab=newIdx
end
local function openInTab(lines,path,inst,statusMsg)
    for i,t in ipairs(S.tabs) do
        if t.currentPath==path then switchTab(i); return end
    end
    local snap={
        lines=lines,originalLines=deepCopy(lines),
        scroll=0,scrollX=0,cursorLine=1,cursorChar=1,
        currentPath=path,currentInst=inst,
        editorStatus=statusMsg or "Loaded "..#lines.." lines",
        editorStatusColor=T.success,
        searchOpen=false,searchQuery="",searchMatches={},searchMatchIdx=1,
    }
    if #S.lines==0 and S.currentPath=="" then
        S.tabs[S.activeTab]=snap; restoreTabSnapshot(snap); return
    end
    if #S.tabs<MAX_TABS then
        saveActiveTab()
        table.insert(S.tabs,snap)
        restoreTabSnapshot(snap); S.activeTab=#S.tabs
    else
        S.tabs[S.activeTab]=snap; restoreTabSnapshot(snap)
    end
end

local VALUE_TYPES={"NumberValue","BoolValue","StringValue","IntValue",
    "DoubleConstrainedValue","IntConstrainedValue","Vector3Value","Color3Value",
    "CFrameValue","ObjectValue","RayValue","NumberSequenceValue","ColorSequenceValue",
    "BrickColorValue"}
local function isScriptType(c)
    return c:IsA("ModuleScript") or c:IsA("LocalScript") or c:IsA("Script")
end
local function isValueType(c)
    for _,t in ipairs(VALUE_TYPES) do if c:IsA(t) then return true end end
    return false
end

local function isPartType(c)
    local cn=c.ClassName
    return cn=="Part" or cn=="MeshPart" or cn=="WedgePart" or cn=="UnionOperation"
        or cn=="TrussPart" or cn=="CornerWedgePart" or cn=="SpawnLocation"
        or cn=="Seat" or cn=="VehicleSeat"
end
local function isContainerType(c)
    local cn=c.ClassName
    return cn=="Folder" or cn=="Configuration"
end
local function isHumanoidType(c)
    return c.ClassName=="Humanoid"
end

local function buildNavItems(inst)
    local items={}
    local ok,children=pcall(function() return inst:GetChildren() end)
    if not ok then return items end
    for _,c in ipairs(children) do
        local isSc=isScriptType(c); local isVal=isValueType(c)
        local isPart=isPartType(c); local isCont=isContainerType(c)
        local hasChildren=false
        local ok2,ch=pcall(function() return c:GetChildren() end)
        if ok2 then hasChildren=#ch>0 end
        local currentVal=""
        if isVal then
            local ok3,v=pcall(function() return c.Value end)
            if ok3 and v~=nil then currentVal=" = "..tostring(v) end
        end
        local icon = isSc and "📜" or isVal and "🔢" or isPart and "⬜" or isCont and "📁" or "•"
        table.insert(items,{
            inst=c, name=c.Name, class=c.ClassName,
            isScript=isSc, isValue=isVal, isPart=isPart, isContainer=isCont,
            hasChildren=hasChildren, currentVal=currentVal, icon=icon,
        })
    end
    table.sort(items,function(a,b)
        local function rank(x) return x.isContainer and 0 or x.isScript and 1 or x.isValue and 2 or x.isPart and 4 or 3 end
        local ra,rb=rank(a),rank(b)
        if ra~=rb then return ra<rb end
        return a.name<b.name
    end)
    return items
end

local function searchAllScripts(query, filterMode)
    local results={}
    if query=="" then return results end
    local q=query:lower()
    local lp2=game:GetService("Players").LocalPlayer
    local desc={}
    local seen={}
    local scanWorkspace = filterMode=="parts" or filterMode=="folders"
        or filterMode=="humanoid" or filterMode=="all"
    local ok1,lpDesc=pcall(function() return lp2 and lp2:GetDescendants() or {} end)
    if ok1 then
        for _,v in ipairs(lpDesc) do
            seen[v]=true
            table.insert(desc,v)
        end
    end
    if scanWorkspace then
        local ok2,wsDesc=pcall(function() return workspace:GetDescendants() end)
        if ok2 then
            for _,v in ipairs(wsDesc) do
                if not seen[v] then table.insert(desc,v) end
            end
        end
    end
    for _,inst in ipairs(desc) do
        local isSc=isScriptType(inst)
        local isVal=isValueType(inst)
        local isPt=isPartType(inst)
        local isCnt=isContainerType(inst)
        local include
        if filterMode=="scripts" then include=isSc
        elseif filterMode=="values" then include=isVal
        elseif filterMode=="parts" then include=isPt
        elseif filterMode=="folders" then include=isCnt
        elseif filterMode=="humanoid" then
            include=isHumanoidType(inst)
        else include=true end
        if include and inst.Name:lower():find(q,1,true) then
            local cv=""
            if isVal then
                local ok2,v=pcall(function() return inst.Value end)
                if ok2 then cv=" = "..tostring(v) end
            end
            local fullPath=""
            pcall(function() fullPath=inst:GetFullName() end)
            table.insert(results,{
                label=inst.Name.." ["..inst.ClassName.."]"..cv,
                inst=inst, isScript=isSc, isValue=isVal,
                fullPath=fullPath,
            })
            if #results>=80 then break end
        end
    end
    return results
end

applyTheme(S.themeIdx)

S.tabs[1] = {
    lines=S.lines, originalLines=S.originalLines,
    scroll=S.scroll, scrollX=S.scrollX,
    cursorLine=S.cursorLine, cursorChar=S.cursorChar,
    currentPath=S.currentPath, currentInst=S.currentInst,
    editorStatus=S.editorStatus, editorStatusColor=S.editorStatusColor,
    searchOpen=false, searchQuery="", searchMatches={}, searchMatchIdx=1,
}

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

local function getScripts(tool, filterMode)
    if not tool then return {} end
    filterMode = filterMode or "scripts"
    local found={}
    for _,c in ipairs(tool:GetDescendants()) do
        local isSc=isScriptType(c); local isVal=isValueType(c)
        local include = (filterMode=="all" and (isSc or isVal))
            or (filterMode=="values" and isVal)
            or (filterMode=="scripts" and isSc)
        if include then
            table.insert(found,{
                label=c.Name.." ["..c.ClassName.."]",
                inst=c, isScript=isSc, isValue=isVal,
            })
        end
    end
    table.sort(found,function(a,b) return a.label<b.label end)
    return found
end

local function decompileToLines(inst)
    local ok,src=pcall(decompile,inst)
    if not ok or not src or src=="" then
        return nil,"decompile() failed for "..inst.ClassName
    end
    local out={}
    for l in (src.."\n"):gmatch("([^\n]*)\n") do table.insert(out,l) end
    if #out>0 and out[#out]=="" then table.remove(out) end
    return out,nil
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

local MAX_UNDO = 60
local function pushUndo()
    if #S.undoStack >= MAX_UNDO then table.remove(S.undoStack, 1) end
    table.insert(S.undoStack, {
        lines=deepCopy(S.lines),
        cursorLine=S.cursorLine, cursorChar=S.cursorChar,
    })
    S.redoStack = {}
end
local function doUndo()
    if #S.undoStack == 0 then return end
    table.insert(S.redoStack, {
        lines=deepCopy(S.lines),
        cursorLine=S.cursorLine, cursorChar=S.cursorChar,
    })
    local st=table.remove(S.undoStack)
    S.lines=st.lines; S.cursorLine=st.cursorLine; S.cursorChar=st.cursorChar
end
local function doRedo()
    if #S.redoStack == 0 then return end
    table.insert(S.undoStack, {
        lines=deepCopy(S.lines),
        cursorLine=S.cursorLine, cursorChar=S.cursorChar,
    })
    local st=table.remove(S.redoStack)
    S.lines=st.lines; S.cursorLine=st.cursorLine; S.cursorChar=st.cursorChar
end

local function getLineHint(line)
    local key,val=line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
    if not key or val=="" then return nil end
    if val=="true" or val=="false" then return "bool" end
    if tonumber(val) then return "num" end
    if val:match("^{%s*[%d%.%-]+%s*,%s*[%d%.%-]+%s*}$") then return "vec" end
    return "bad"
end

local function browseGCAll(filterMode)
    local ok,entries=pcall(getgc)
    if not ok or type(entries)~="table" or #entries==0 then
        ok,entries=pcall(getgc,{})
    end
    if not ok then return nil,"getgc() failed: "..tostring(entries) end
    if type(entries)~="table" then return nil,"getgc() returned unexpected type" end
    local results={}
    local seen={}
    for _,entry in ipairs(entries) do
        if type(entry)=="table" and entry.key then
            local k=tostring(entry.key)
            local vt=entry.type or type(entry.value)
            local include
            if filterMode=="all" then
                include=(vt=="number" or vt=="boolean" or vt=="string")
            else
                include=(vt=="number" or vt=="boolean")
            end
            if include and k:match("^[%a_][%w_]*$") and not seen[k] then
                seen[k]=true
                table.insert(results,{
                    key=k,
                    val=tostring(entry.value),
                    vtype=vt,
                    label=k.." = "..tostring(entry.value),
                })
            end
        end
    end
    table.sort(results,function(a,b) return a.key<b.key end)
    return results,nil
end

local function runCrossSearch(query)
    if query=="" then return {} end
    local q=query:lower()
    local results={}
    saveActiveTab()
    for ti,t in ipairs(S.tabs) do
        local lbl=getTabLabel(t)
        for li,line in ipairs(t.lines or {}) do
            if line:lower():find(q,1,true) then
                table.insert(results,{tabIdx=ti,tabLabel=lbl,lineIdx=li,line=line})
                if #results>=100 then return results end
            end
        end
    end
    return results
end

local function runValueDiff(appliedPairs)
    local results={}
    local keys={}; for _,p in ipairs(appliedPairs) do table.insert(keys,p.key) end
    local ok,gcEntries=pcall(getgc,keys)
    local gcMap={}
    if ok and type(gcEntries)=="table" then
        for _,e in ipairs(gcEntries) do if e.key then gcMap[e.key]=tostring(e.value) end end
    end
    for _,p in ipairs(appliedPairs) do
        local actual=gcMap[p.key]
        table.insert(results,{
            key=p.key, requested=p.value,
            actual=actual or "(not in GC)",
            match=(actual==p.value),
        })
    end
    return results
end

local function savePreset(name, lines)
    for i,p in ipairs(S.presets) do
        if p.name==name then S.presets[i].lines=deepCopy(lines); return end
    end
    table.insert(S.presets,{name=name,lines=deepCopy(lines)})
end
local function applyPreset(idx)
    local p=S.presets[idx]
    if not p then return end
    local snap={
        lines=deepCopy(p.lines),originalLines=deepCopy(p.lines),
        scroll=0,scrollX=0,cursorLine=1,cursorChar=1,
        currentPath="[Preset] "..p.name,currentInst=nil,
        editorStatus="Preset loaded: "..p.name,editorStatusColor=T.success,
        searchOpen=false,searchQuery="",searchMatches={},searchMatchIdx=1,
        undoStack={},redoStack={},
    }
    saveActiveTab()
    if #S.lines==0 and S.currentPath=="" then
        S.tabs[S.activeTab]=snap; restoreTabSnapshot(snap)
    elseif #S.tabs<MAX_TABS then
        table.insert(S.tabs,snap)
        restoreTabSnapshot(snap); S.activeTab=#S.tabs
    else
        S.tabs[S.activeTab]=snap; restoreTabSnapshot(snap)
    end
    S.tab="editor"
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

local function edLayout()
    local searchH = S.searchOpen and 22 or 0
    local edY = S.y+HEADER_H
    local tabBarY = edY
    local pathBarY = edY+TAB_BAR_H
    local searchBarY = edY+TAB_BAR_H+PATHBAR_H
    local liBarY = edY+TAB_BAR_H+PATHBAR_H+searchH
    local codeY = edY+TAB_BAR_H+PATHBAR_H+searchH+LIBAR_H
    local codeH = S.h-HEADER_H-TAB_BAR_H-PATHBAR_H-searchH-LIBAR_H-BBH-HSB_H
    local codeW = S.w-LN_W-DIFF_W-SB_W-4
    local codeStartX = S.x+LN_W+DIFF_W+4
    return edY,pathBarY,searchBarY,liBarY,codeY,codeH,codeW,codeStartX,tabBarY
end

local function renderWindow()
    local x,y,w,h=S.x,S.y,S.w,S.h
    Box("shad",x+4,y+4,w,h,Color3.fromRGB(0,0,0),0)
    RBox("win",x,y,w,h,T.bg,1,6)
    RBox("win_o",x,y,w,h,T.border,2,6)
    RBox("titlebar",x,y,w,TITLE_H+6,T.panel,2,6,CR)
    Box("titlebar_sq",x,y+6,w,TITLE_H,T.panel,2,CR)
    Box("title_accent",x,y+TITLE_H-1,w,1,T.accentDim,3)
    Txt("title_txt",x+PAD+2,y+10,"ACS Config Editor",T.text,13,3)
    Box("title_ver",x+w-100,y+10,54,16,T.accentDim,3)
    Txt("title_ver_t",x+w-73,y+18,"v3",T.accent,10,4,true)
    Box("close_bg",x+w-26,y+8,18,18,T.panel2,3)
    Txt("close_x",x+w-17,y+17,"×",T.sub,14,4,true)
    local tabs={{"browser","Browser"},{"editor","Editor"},{"settings","Settings"}}
    local tabW=110
    Box("tabs_bg",x,y+TITLE_H,w,TAB_H,T.surface,2,CR)
    for i,td in ipairs(tabs) do
        local tx=x+(i-1)*tabW; local ty=y+TITLE_H; local active=S.tab==td[1]
        if active then
            Box("tab_bg_"..i,tx,ty,tabW,TAB_H,T.panel,3)
            Box("tab_ul_"..i,tx+4,ty+TAB_H-2,tabW-8,2,T.accent,4)
        else
            Box("tab_bg_"..i,tx,ty,tabW,TAB_H,T.surface,3)
            hide("tab_ul_"..i)
        end
        Txt("tab_txt_"..i,tx+tabW/2,ty+9,td[2],
            active and T.text or T.sub, active and 12 or 11, 4, true)
    end
    Ln("tabs_sep",x,y+TITLE_H+TAB_H-1,x+w,y+TITLE_H+TAB_H-1,nil,1,3)
end

local function renderBrowser()
    local x,y,w,h=S.x,S.y,S.w,S.h
    local cx=x+PAD
    local cy=y+HEADER_H+PAD
    local lh=h-HEADER_H-PAD*2-28
    local subTab=S.browserSubTab

    local subBarH=24
    Box("br_subbar",cx,cy,w-PAD*2,subBarH,T.panel2,2)
    local stW=(w-PAD*2)/2
    local toolActive=subTab=="tool"
    Box("br_st_tool",cx,cy,stW,subBarH,toolActive and T.panel or T.surface,3)
    Txt("br_st_tool_t",cx+stW/2,cy+subBarH/2,"Tool Browser",toolActive and T.text or T.sub,11,4,true)
    local gameActive=subTab=="game"
    Box("br_st_game",cx+stW,cy,stW,subBarH,gameActive and T.panel or T.surface,3)
    Txt("br_st_game_t",cx+stW+stW/2,cy+subBarH/2,"Game Browser",gameActive and T.text or T.sub,11,4,true)
    if toolActive then
        Box("br_st_ul",cx,cy+subBarH-2,stW,2,T.accent,4)
        hide("br_st_ul2")
    else
        Box("br_st_ul2",cx+stW,cy+subBarH-2,stW,2,T.accent,4)
        hide("br_st_ul")
    end
    Ln("br_st_sep",cx,cy+subBarH,cx+w-PAD*2,cy+subBarH,nil,1,3)

    local panelY=cy+subBarH+2
    local panelH=lh-subBarH-2

    if subTab=="tool" then
        for _,id in ipairs({
            "br_game_input","br_game_input_o","br_game_input_t",
            "br_game_go","br_game_go_t","br_game_gc","br_game_gc_t",
            "br_game_cnt","br_game_list_sb_bg","br_game_list_sb",
        }) do hide(id) end
        for i=1,6 do hide("br_gsf_"..i); hide("br_gsf_t"..i) end
        for i=1,30 do hide("br_gi_"..i); hide("br_gt_"..i); hide("br_gpath_"..i) end
        hide("br_game_load"); hide("br_game_load_t")

        local lw=SIDEBAR_W; local rx=cx+lw+PAD; local rw=w-PAD*2-lw-PAD
        Box("br_lbg",cx,panelY,lw,panelH,T.surface,2,CR)
        Outline("br_lbg_o",cx,panelY,lw,panelH,T.border,3,CR)
        Txt("br_lhdr",cx+8,panelY+6,"TOOLS",T.sub,11,4)
        Ln("br_lhl",cx,panelY+22,cx+lw,panelY+22,nil,1,3)
        local tsY=panelY+26; local tsH=20; local tsW=lw-16
        Box("br_ts_bg",cx+4,tsY,tsW,tsH,T.panel2,3,CR)
        Outline("br_ts_o",cx+4,tsY,tsW,tsH,S.toolSearchFocused and T.accent or T.border,4,CR)
        local tsCursor=S.toolSearchFocused and (math.floor(tick()*2)%2==0 and "|" or "") or ""
        local tsDisp=S.toolSearch..tsCursor
        if tsDisp=="" and not S.toolSearchFocused then
            Txt("br_ts_t",cx+8,tsY+4,"Filter tools…",T.sub,10,4)
        else
            Txt("br_ts_t",cx+8,tsY+4,tsDisp,T.text,10,4)
        end
        local toolListY=panelY+50; local scanBtnY=panelY+panelH-32
        local toolVis=math.floor((scanBtnY-toolListY-4)/22)
        local filteredToolsR={}
        local tsqR=S.toolSearch:lower()
        for _,t in ipairs(S.tools) do
            if tsqR=="" or t.label:lower():find(tsqR,1,true) then
                table.insert(filteredToolsR,t)
            end
        end
        local maxToolScroll=math.max(0,#filteredToolsR-toolVis)
        S.toolScroll=math.max(0,math.min(maxToolScroll,S.toolScroll))
        local sbW=8; local sbX=cx+lw-sbW-2
        for i=1,toolVis do
            local tool=filteredToolsR[i+S.toolScroll]
            if not tool then hide("br_ti_"..i); hide("br_tt_"..i) break end
            local iy=toolListY+(i-1)*22; local absIdx=i+S.toolScroll
            local sel=S.toolSel==absIdx
            Box("br_ti_"..i,cx+1,iy,lw-sbW-4,21,sel and T.accent or (inB(cx+1,iy,lw-sbW-4,21) and T.panel or T.surface),3)
            local lbl=tool.label; if tw(lbl,12)>lw-sbW-20 then lbl=lbl:sub(1,28).."…" end
            Txt("br_tt_"..i,cx+8,iy+4,lbl,sel and T.text or T.sub,12,4)
        end
        for i=math.max(1,#filteredToolsR-S.toolScroll+1),toolVis+2 do hide("br_ti_"..i); hide("br_tt_"..i) end
        if #filteredToolsR>toolVis then
            local trackH=scanBtnY-toolListY-2
            local thumbH=math.max(20,math.floor(toolVis/#S.tools*trackH))
            local thumbY=toolListY+math.floor(S.toolScroll/math.max(1,maxToolScroll)*(trackH-thumbH))
            thumbY=math.max(toolListY,math.min(toolListY+trackH-thumbH,thumbY))
            Box("br_tool_sb_bg",sbX,toolListY,sbW,trackH,T.panel2,3,4)
            Box("br_tool_sb",sbX,thumbY,sbW,thumbH,T.border,4,4)
        else hide("br_tool_sb_bg"); hide("br_tool_sb") end

        Box("br_scan",cx,scanBtnY,lw,28,inB(cx,scanBtnY,lw,28) and T.accentHi or T.accent,3,CR)
        Txt("br_scan_t",cx+lw/2,scanBtnY+14,"Scan Inventory",T.text,13,4,true)

        if #S.pinnedScripts>0 then
            local pinY=scanBtnY+32
            Txt("br_pin_hdr",cx+4,pinY,"📌 PINNED",T.warn,10,4)
            for i=1,math.min(#S.pinnedScripts,4) do
                local p=S.pinnedScripts[i]; local piy2=pinY+14+(i-1)*18
                local phov=inB(cx,piy2,lw,17)
                Box("br_pin_"..i,cx,piy2,lw,17,phov and T.panel or T.surface,3)
                local plbl=p.name; if tw(plbl,10)>lw-8 then plbl=plbl:sub(1,22).."…" end
                Txt("br_pin_t"..i,cx+4,piy2+3,plbl,T.sub,10,4)
            end
            for i=#S.pinnedScripts+1,5 do hide("br_pin_"..i); hide("br_pin_t"..i) end
        else
            for i=1,5 do hide("br_pin_"..i); hide("br_pin_t"..i) end
            hide("br_pin_hdr")
        end

        Box("br_rbg",rx,panelY,rw,panelH,T.surface,2,CR)
        Outline("br_rbg_o",rx,panelY,rw,panelH,T.border,3,CR)

        local canBack=#S.navStack>1
        Box("br_back",rx+2,panelY+3,18,18,canBack and T.panel2 or T.surface,3,CR)
        Txt("br_back_t",rx+11,panelY+12,"<",canBack and T.text or Color3.fromRGB(40,40,55),13,4,true)
        local crumb=""
        for i,v in ipairs(S.navStack) do if i>1 then crumb=crumb.." › " end; crumb=crumb..v.name end
        if crumb=="" then crumb="Select a tool to explore" end
        if tw(crumb,11)>rw-36 then crumb="…"..crumb:sub(-38) end
        Txt("br_rhdr",rx+24,panelY+6,crumb,#S.navStack>0 and T.text or T.sub,11,4)
        Ln("br_rhl",rx,panelY+24,rx+rw,panelY+24,nil,1,3)

        local slY=panelY+28; local loadBtnY=panelY+panelH-32
        local sVis=math.floor((loadBtnY-slY-4)/22)
        local navItems=S.navItems or {}
        local maxNavScroll=math.max(0,#navItems-sVis)
        S.navScroll=math.max(0,math.min(S.navScroll,maxNavScroll))

        for i=1,sVis do
            local sc=navItems[i+S.navScroll]
            if not sc then hide("br_si_"..i); hide("br_st_"..i); hide("br_si_pin_"..i) break end
            local iy=slY+(i-1)*22
            local absIdx=i+S.navScroll
            local sel=S.navSel==absIdx
            local hov=inB(rx+1,iy,rw-10,21)
            Box("br_si_"..i,rx+1,iy,rw-10,21,sel and T.accent or (hov and T.panel or T.surface),3)
            local isPinned=sc.inst and (function()
                for _,p in ipairs(S.pinnedScripts) do if p.path==sc.inst:GetFullName() then return true end end
                return false
            end)()
            if isPinned then Txt("br_si_pin_"..i,rx+rw-14,iy+4,"📌",T.warn,9,4)
            else hide("br_si_pin_"..i) end
            local lbl=(sc.icon or "")..sc.name.." ["..sc.class.."]"..(sc.currentVal or "")
            if sc.hasChildren then lbl=lbl.." ›" end
            if tw(lbl,12)>rw-24 then lbl=lbl:sub(1,56).."…" end
            local txtCol=sel and T.text or (sc.isScript and T.sub or sc.isValue and T.hintNum or sc.isContainer and T.sub or T.textDim)
            Txt("br_st_"..i,rx+8,iy+4,lbl,txtCol,12,4)
        end
        for i=math.min(#navItems-S.navScroll,sVis)+1,sVis+2 do
            hide("br_si_"..i); hide("br_st_"..i); hide("br_si_pin_"..i)
        end

        if #navItems>sVis then
            local sbH=math.floor(sVis/#navItems*(loadBtnY-slY))
            local sbY=slY+math.floor(S.navScroll/math.max(1,#navItems-sVis)*(loadBtnY-slY-sbH))
            Box("br_nav_sb_bg",rx+rw-12,slY,12,loadBtnY-slY,T.surface,3)
            Box("br_nav_sb",rx+rw-12,sbY,12,math.max(20,sbH),T.borderHi,4,4)
        else hide("br_nav_sb_bg"); hide("br_nav_sb") end

        local selEntry=navItems[S.navSel]
        local loadLbl
        if selEntry then
            if selEntry.isValue then loadLbl="Edit Value"
            elseif selEntry.isScript then loadLbl="Decompile & Open in Editor"
            elseif selEntry.isContainer and selEntry.hasChildren then loadLbl="Open Folder →"
            else loadLbl="Browse" end
        else loadLbl=#navItems>0 and "Select an item" or "Scan a tool first" end
        local pinBtnW=selEntry and 38 or 0
        local loadW=rw-pinBtnW-(pinBtnW>0 and 2 or 0)
        Box("br_load",rx,loadBtnY,loadW,28,
            (selEntry and inB(rx,loadBtnY,loadW,28)) and T.accentHi or (selEntry and T.accent or T.border),3,CR)
        Txt("br_load_t",rx+loadW/2,loadBtnY+14,loadLbl,T.text,12,4,true)
        if pinBtnW>0 and selEntry and selEntry.inst then
            local isPinned2=false
            for _,p in ipairs(S.pinnedScripts) do if p.path==selEntry.inst:GetFullName() then isPinned2=true end end
            Box("br_pin_btn",rx+loadW+2,loadBtnY,pinBtnW,28,isPinned2 and T.warn or T.panel2,3,CR)
            Txt("br_pin_t_btn",rx+loadW+2+pinBtnW/2,loadBtnY+14,isPinned2 and "📌" or "Pin",isPinned2 and T.bg or T.sub,11,4,true)
        else hide("br_pin_btn"); hide("br_pin_t_btn") end

        hide("br_game_load"); hide("br_game_load_t")

    else
        -- GAME BROWSER
        for i=1,30 do hide("br_ti_"..i); hide("br_tt_"..i); hide("br_si_"..i); hide("br_st_"..i); hide("br_si_pin_"..i) end
        hide("br_tool_sb_bg"); hide("br_tool_sb")
        hide("br_ts_bg"); hide("br_ts_o"); hide("br_ts_t")
        S.toolSearchFocused=false
        for i=1,5 do hide("br_pin_"..i); hide("br_pin_t"..i) end
        hide("br_lbg"); hide("br_lbg_o"); hide("br_lhdr"); hide("br_lhl")
        hide("br_scan"); hide("br_scan_t"); hide("br_pin_hdr")
        hide("br_rbg"); hide("br_rbg_o"); hide("br_rhdr"); hide("br_rhl")
        hide("br_back"); hide("br_back_t")
        hide("br_load"); hide("br_load_t"); hide("br_pin_btn"); hide("br_pin_t_btn")
        hide("br_nav_sb_bg"); hide("br_nav_sb")
        hide("br_f_sc"); hide("br_f_sct"); hide("br_f_va"); hide("br_f_vat"); hide("br_f_al"); hide("br_f_alt")
        hide("br_gc_btn"); hide("br_gc_btn_t")
        hide("br_srch_btn"); hide("br_srch_btn_t")

        local rw=w-PAD*2
        local inputY=panelY+4; local inputH=26
        local gcBtnW=36; local goBtnW=32
        local inputW=rw-gcBtnW-goBtnW-16
        Box("br_game_input",cx,inputY,inputW,inputH,T.panel,3,CR)
        Outline("br_game_input_o",cx,inputY,inputW,inputH,S.scriptSearchFocused and T.accent or T.border,4,CR)
        local sd=S.scriptSearch..(S.scriptSearchFocused and (math.floor(tick()*2)%2==0 and "|" or "") or "")
        if sd=="" and not S.scriptSearchFocused then
            Txt("br_game_input_t",cx+8,inputY+7,"Search all game instances by name…",T.sub,11,4)
        else Txt("br_game_input_t",cx+8,inputY+7,sd,T.text,11,4) end
        local goX=cx+inputW+4
        Box("br_game_go",goX,inputY,goBtnW,inputH,inB(goX,inputY,goBtnW,inputH) and T.accentHi or T.accent,3,CR)
        Txt("br_game_go_t",goX+goBtnW/2,inputY+13,"Go",T.text,11,4,true)
        local gcX=goX+goBtnW+4
        Box("br_game_gc",gcX,inputY,gcBtnW,inputH,S.gcBrowseMode and T.accentDim or T.panel2,3,CR)
        Txt("br_game_gc_t",gcX+gcBtnW/2,inputY+13,"GC",S.gcBrowseMode and T.accentHi or T.sub,11,4,true)

        local filterY=inputY+inputH+4
        local filters={"All","Scripts","Values","Parts","Folders","Humanoid"}
        local filterKeys={"all","scripts","values","parts","folders","humanoid"}
        local fW=math.floor(rw/#filters)-1
        for fi,fn in ipairs(filters) do
            local fk=filterKeys[fi]; local fx=cx+(fi-1)*(fW+1)
            local active=S.explorerFilter==fk and not S.gcBrowseMode
            Box("br_gsf_"..fi,fx,filterY,fW,18,active and T.accent or T.panel2,3,2)
            Txt("br_gsf_t"..fi,fx+fW/2,filterY+9,fn,active and T.text or T.sub,9,4,true)
        end

        local slY=filterY+22
        local loadBtnY2=panelY+panelH-32
        local sVis=math.floor((loadBtnY2-slY-4)/22)
        local displayItems = S.gcBrowseMode and S.gcBrowseResults or S.scriptSearchResults
        local listScroll=S.gcBrowseMode and S.gcBrowseScroll or S.scriptSearchScroll
        local maxScroll=math.max(0,#displayItems-sVis)
        if S.gcBrowseMode then S.gcBrowseScroll=math.max(0,math.min(S.gcBrowseScroll,maxScroll))
        else S.scriptSearchScroll=math.max(0,math.min(S.scriptSearchScroll,maxScroll)) end
        listScroll=S.gcBrowseMode and S.gcBrowseScroll or S.scriptSearchScroll

        local rc=#displayItems
        if S.gcBrowseMode then
            local selCount=0; for _ in pairs(S.gcBulkSel) do selCount=selCount+1 end
            local gcStatusTxt=selCount>0 and (selCount.." selected") or (S.gcBrowseStatus~="" and S.gcBrowseStatus or (rc>0 and rc.." GC entries" or "Click GC → Scan GC"))
            Txt("br_game_cnt",cx,slY-16,gcStatusTxt,selCount>0 and T.warn or T.sub,10,4)
            local fX2=cx; local fW2=52
            Box("br_gc_fc",fX2,filterY,fW2,18,S.gcBrowseFilter=="config" and T.accent or T.panel2,3,2)
            Txt("br_gc_fct",fX2+fW2/2,filterY+9,"Config",S.gcBrowseFilter=="config" and T.text or T.sub,9,4,true)
            Box("br_gc_fa",fX2+fW2+2,filterY,fW2,18,S.gcBrowseFilter=="all" and T.accent or T.panel2,3,2)
            Txt("br_gc_fat",fX2+fW2*1.5+2,filterY+9,"All",S.gcBrowseFilter=="all" and T.text or T.sub,9,4,true)
            local scanX=fX2+fW2*2+8
            Box("br_gc_scan",scanX,filterY,60,18,inB(scanX,filterY,60,18) and T.accentHi or T.accent,3,CR)
            Txt("br_gc_scant",scanX+30,filterY+9,"Scan GC",T.text,9,4,true)
            for fi=1,6 do hide("br_gsf_"..fi); hide("br_gsf_t"..fi) end
        else
            Txt("br_game_cnt",cx,slY-16,rc>0 and rc.." results" or (S.scriptSearch~="" and "No results" or ""),T.sub,10,4)
            hide("br_gc_fc"); hide("br_gc_fct"); hide("br_gc_fa"); hide("br_gc_fat")
            hide("br_gc_scan"); hide("br_gc_scant")
            for _,id in ipairs({"br_gc_bv","br_gc_bvo","br_gc_bvt","br_gc_bvb","br_gc_bvbt"}) do hide(id) end
        end

        for i=1,sVis do
            local sc=displayItems[i+listScroll]
            if not sc then hide("br_gi_"..i); hide("br_gt_"..i); hide("br_gpath_"..i) break end
            local iy=slY+(i-1)*22
            local absIdx=i+listScroll
            local sel=S.scriptSel==absIdx
            local bulkSel=S.gcBrowseMode and S.gcBulkSel[absIdx]
            local hov=inB(cx,iy,rw-10,21)
            local bgCol=bulkSel and T.warn or sel and T.accent or (hov and T.panel or T.surface)
            Box("br_gi_"..i,cx,iy,rw-10,21,bgCol,3)
            local lbl
            if S.gcBrowseMode then
                lbl=sc.key.." = "..sc.val
                if tw(lbl,12)>rw-18 then lbl=lbl:sub(1,60).."…" end
                hide("br_gpath_"..i)
            else
                lbl=sc.label or ((sc.icon or "")..sc.name.." ["..sc.class.."]"..(sc.currentVal or ""))
                if sc.fullPath and sc.fullPath~="" then
                    local pathStr=sc.fullPath
                    local pathW=tw(pathStr,9)
                    local maxPathW=rw-10-tw(lbl,12)-24
                    if pathW>maxPathW and maxPathW>40 then
                        while tw("…"..pathStr,9)>maxPathW and #pathStr>4 do
                            pathStr=pathStr:sub(2)
                        end
                        pathStr="…"..pathStr
                    end
                    local pathX=cx+rw-12-tw(pathStr,9)
                    Txt("br_gpath_"..i,pathX,iy+7,pathStr,sel and T.dim or T.border,9,4)
                    local lblMax=pathX-cx-14
                    if tw(lbl,12)>lblMax then lbl=lbl:sub(1,math.floor(lblMax/6.5)).."…" end
                else
                    hide("br_gpath_"..i)
                    if tw(lbl,12)>rw-18 then lbl=lbl:sub(1,60).."…" end
                end
            end
            local txtCol
            if S.gcBrowseMode and sc.vtype then
                txtCol=(bulkSel or sel) and T.bg or (sc.vtype=="number" and T.hintNum or sc.vtype=="boolean" and T.hintBool or T.sub)
            else txtCol=sel and T.text or T.sub end
            Txt("br_gt_"..i,cx+6,iy+4,lbl,txtCol,12,4)
        end
        for i=math.min(#displayItems-listScroll,sVis)+1,sVis+2 do
            hide("br_gi_"..i); hide("br_gt_"..i); hide("br_gpath_"..i)
        end

        if #displayItems>sVis then
            local sbH=math.floor(sVis/#displayItems*(loadBtnY2-slY))
            local sbY=slY+math.floor(listScroll/math.max(1,#displayItems-sVis)*(loadBtnY2-slY-sbH))
            Box("br_game_list_sb_bg",cx+rw-12,slY,12,loadBtnY2-slY,T.surface,3)
            Box("br_game_list_sb",cx+rw-12,sbY,12,math.max(20,sbH),T.borderHi,4,4)
        else hide("br_game_list_sb_bg"); hide("br_game_list_sb") end

        local sel2=displayItems[S.scriptSel]
        local loadLbl2
        if S.gcBrowseMode then loadLbl2=#displayItems>0 and "Insert into Editor" or "Scan GC first"
        elseif sel2 then
            if sel2.isValue then loadLbl2="Edit Value"
            elseif sel2.isScript then loadLbl2="Decompile & Open"
            else loadLbl2="Browse" end
        else loadLbl2=#displayItems>0 and "Select a result" or "Search to find items" end
        Box("br_game_load",cx,loadBtnY2,rw,28,(sel2 and inB(cx,loadBtnY2,rw,28)) and T.accentHi or (sel2 and T.accent or T.border),3,CR)
        Txt("br_game_load_t",cx+rw/2,loadBtnY2+14,loadLbl2,T.text,12,4,true)

        if S.gcBrowseMode then
            local selCount=0; for _ in pairs(S.gcBulkSel) do selCount=selCount+1 end
            if selCount>0 then
                local bvX=cx; local bvW=rw-66
                Box("br_gc_bv",bvX,loadBtnY2-26,bvW,20,T.panel2,3,CR)
                Outline("br_gc_bvo",bvX,loadBtnY2-26,bvW,20,S.gcBulkFocused and T.accent or T.border,4,CR)
                local bvd=S.gcBulkValue..(S.gcBulkFocused and (math.floor(tick()*2)%2==0 and "|" or "") or "")
                if bvd=="" and not S.gcBulkFocused then Txt("br_gc_bvt",bvX+5,loadBtnY2-22,"Set all selected…",T.sub,10,4)
                else Txt("br_gc_bvt",bvX+5,loadBtnY2-22,bvd,T.text,10,4) end
                Box("br_gc_bvb",bvX+bvW+4,loadBtnY2-26,60,20,inB(bvX+bvW+4,loadBtnY2-26,60,20) and T.accentHi or T.accent,3,CR)
                Txt("br_gc_bvbt",bvX+bvW+34,loadBtnY2-16,"Set All",T.text,10,4,true)
            else
                for _,id in ipairs({"br_gc_bv","br_gc_bvo","br_gc_bvt","br_gc_bvb","br_gc_bvbt"}) do hide(id) end
            end
        end
    end  -- end game browser else

    local stY=y+h-PAD-16
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
    local edY,pathBarY,searchBarY,liBarY,codeY,codeH,codeW,codeStartX,tabBarY=edLayout()
    local sbX=x+w-SB_W-2

    Box("ed_tabbg",x,tabBarY,w,TAB_BAR_H,T.panel2,2,CR)
    Ln("ed_tabbl",x,tabBarY+TAB_BAR_H,x+w,tabBarY+TAB_BAR_H,nil,1,3)
    local numTabs=math.max(1,#S.tabs)
    local tabW=math.min(150,math.floor((w-28)/numTabs))
    for i=1,numTabs do
        local t=S.tabs[i]; local tx=x+(i-1)*tabW
        local active=i==S.activeTab
        Box("ed_tab_"..i,tx,tabBarY+2,tabW-1,TAB_BAR_H-4,active and T.panel or T.surface,3)
        if active then Box("ed_tab_ul_"..i,tx,tabBarY+TAB_BAR_H-2,tabW-1,2,T.accent,4)
        else hide("ed_tab_ul_"..i) end
        local lbl=getTabLabel(t)
        local maxLblW=tabW-22
        if tw(lbl,11)>maxLblW then lbl=lbl:sub(1,math.max(1,math.floor(maxLblW/(11*0.535)))).."…" end
        Txt("ed_tab_t_"..i,tx+6,tabBarY+7,lbl,active and T.text or T.sub,11,4)
        Txt("ed_tab_x_"..i,tx+tabW-12,tabBarY+7,"×",active and T.textDim or Color3.fromRGB(45,45,60),11,4)
    end
    for i=numTabs+1,MAX_TABS+1 do
        hide("ed_tab_"..i); hide("ed_tab_ul_"..i); hide("ed_tab_t_"..i); hide("ed_tab_x_"..i)
    end
    local plusX=x+numTabs*tabW
    if numTabs<MAX_TABS then
        Box("ed_tab_new",plusX,tabBarY+4,20,TAB_BAR_H-8,T.panel,3,CR)
        Txt("ed_tab_new_t",plusX+10,tabBarY+7,"+",T.sub,12,4,true)
    else hide("ed_tab_new"); hide("ed_tab_new_t") end
    Box("ed_pathbar",x,pathBarY,w,PATHBAR_H,T.panel,2,CR)
    local pathDisp=S.currentPath=="" and "No file loaded — use Browser tab" or S.currentPath
    local maxPW=w-PAD*2-80
    if tw(pathDisp,11)>maxPW then
        pathDisp="…"..pathDisp:sub(-math.floor(maxPW/((11*0.535)))+1)
    end
    Txt("ed_path",x+PAD,pathBarY+4,pathDisp,T.sub,11,3)

    if S.currentInst then
        local rbW=64; local rbX=x+w-rbW-PAD
        Box("ed_reload",rbX,pathBarY+3,rbW,16,inB(rbX,pathBarY+3,rbW,16,CR) and T.accentHi or T.panel,3)
        Txt("ed_reload_t",rbX+rbW/2,pathBarY+11,"↺ Reload",T.sub,10,4,true)
    else hide("ed_reload"); hide("ed_reload_t") end

    if S.searchOpen then
        Box("ed_srch_bg",x,searchBarY,w,22,Color3.fromRGB(18,18,28),3)
        Ln("ed_srch_bl",x,searchBarY+22,x+w,searchBarY+22,nil,1,4)
        Txt("ed_srch_lbl",x+PAD,searchBarY+5,"Find:",T.sub,11,4)
        local qx=x+PAD+40; local qw=220
        Box("ed_srch_box",qx,searchBarY+3,qw,16,T.panel,3)
        Outline("ed_srch_box_o",qx,searchBarY+3,qw,16,S.searchFocused and T.accent or T.border,4,CR)
        local qd=S.searchQuery..(S.searchFocused and (math.floor(tick()*2)%2==0 and "|" or "") or "")
        Txt("ed_srch_q",qx+4,searchBarY+5,qd,T.text,11,4)
        local matchStr=#S.searchMatches>0 and (S.searchMatchIdx.."/"..#S.searchMatches.." matches") or "no matches"
        Txt("ed_srch_mc",qx+qw+8,searchBarY+5,matchStr,#S.searchMatches>0 and T.success or T.sub,11,4)
        Txt("ed_srch_esc",x+w-50,searchBarY+5,"ESC close",T.sub,10,4)
    else
        for _,id in ipairs({"ed_srch_bg","ed_srch_bl","ed_srch_lbl","ed_srch_box",
            "ed_srch_box_o","ed_srch_q","ed_srch_mc","ed_srch_esc"}) do hide(id) end
    end

    if S.lineJumpOpen then
        local ljW=200; local ljX=x+w/2-ljW/2; local ljY=codeY+4
        Box("ed_lj_bg",ljX,ljY,ljW,28,T.panel2,10,CR)
        Outline("ed_lj_o",ljX,ljY,ljW,28,T.accent,11,CR)
        Txt("ed_lj_lbl",ljX+8,ljY+8,"Go to line:",T.sub,11,11)
        local ljInputX=ljX+74; local ljInputW=ljW-78
        Box("ed_lj_inp",ljInputX,ljY+4,ljInputW,20,T.bg,11,2)
        local ljd=S.lineJumpInput..(math.floor(tick()*2)%2==0 and "|" or "")
        Txt("ed_lj_t",ljInputX+4,ljY+8,ljd,T.text,12,12)
    else
        for _,id in ipairs({"ed_lj_bg","ed_lj_o","ed_lj_lbl","ed_lj_inp","ed_lj_t"}) do hide(id) end
    end

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

    local matchSet={}
    for _,li in ipairs(S.searchMatches) do matchSet[li]=true end

    local cursorVisible=false
    for i=1,visLines do
        local li=i+S.scroll; local lineY=codeY+(i-1)*LINE_H
        local isCur=li==S.cursorLine and S.focused

        if S.searchOpen and matchSet[li] then
            local isCurMatch=(S.searchMatches[S.searchMatchIdx]==li)
            Box("ed_shi_"..i,codeStartX,lineY,codeW,LINE_H,isCurMatch and T.srchCur or T.srchHi,2)
        else hide("ed_shi_"..i) end

        if isCur then
            Box("ed_curhl_"..i,codeStartX,lineY,codeW,LINE_H,Color3.fromRGB(32,32,44),2)
        else hide("ed_curhl_"..i) end

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
            TxtCode("ed_ln_"..i,x+LN_W-4,lineY+2,tostring(li),
                li==S.cursorLine and T.accent or Color3.fromRGB(70,70,90),11,3)
            local hint=getLineHint(S.lines[li])
            if hint then
                local hc = hint=="num" and T.hintNum or hint=="bool" and T.hintBool
                    or hint=="vec" and T.hintVec or T.hintBad
                Box("ed_hint_"..i,x+2,lineY+6,4,4,hc,4)
            else hide("ed_hint_"..i) end

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
                    if avail>0 then TxtCode("ed_sp_"..i.."_"..si,ox,lineY+2,sp[1]:sub(1,avail),sp[2],13,4) end
                    hidePrefix("ed_sp_"..i.."_"..(si+1))
                    break
                end
                TxtCode("ed_sp_"..i.."_"..si,ox,lineY+2,sp[1],sp[2],13,4)
                ox=ox+spW
            end
        else
            hide("ed_ln_"..i); hidePrefix("ed_sp_"..i.."_")
            hide("ed_dif_"..i); hide("ed_shi_"..i)
        end

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

    for i=visLines+1,visLines+6 do
        hide("ed_curhl_"..i); hide("ed_ln_"..i); hide("ed_dif_"..i); hide("ed_shi_"..i)
        hide("ed_hint_"..i); hidePrefix("ed_sp_"..i.."_")
    end

    if totalLines>visLines then
        local tbH=codeH-4; local sH=math.max(20,tbH*(visLines/totalLines))
        local sY=codeY+2+(tbH-sH)*(S.scroll/math.max(1,maxScroll))
        Box("ed_sb_tr",sbX,codeY+2,SB_W,tbH,Color3.fromRGB(22,22,30),2)
        Box("ed_sb_th",sbX,sY,SB_W,sH,T.border,3)
    else hide("ed_sb_tr"); hide("ed_sb_th") end

    local hsbY=codeY+codeH
    Box("ed_hsb_bg",x+LN_W+DIFF_W,hsbY,codeW,HSB_H,Color3.fromRGB(22,22,30),2)
    if maxScrollX>0 then
        local thW=math.max(30,codeW*(visChars/math.max(1,maxLineLen)))
        local thX=x+LN_W+DIFF_W+(codeW-thW)*(S.scrollX/math.max(1,maxScrollX))
        Box("ed_hsb_th",thX,hsbY+1,thW,HSB_H-2,T.border,3)
    else hide("ed_hsb_th") end

    local bbY=y+h-BBH
    Box("ed_bb",x,bbY,w,BBH,T.panel,2,CR)
    Ln("ed_bbl",x,bbY,x+w,bbY,nil,1,3)
    Txt("ed_li",x+PAD,bbY+10,"Ln "..S.cursorLine.." / "..totalLines.."   Col "..S.cursorChar,T.sub,11,3)
    Txt("ed_mode",x+210,bbY+10,S.focused and "  EDITING" or "  READ ONLY",S.focused and T.success or T.sub,11,3)
    if S.autoApply then
        Box("ed_aa_dot",x+330,bbY+13,6,6,T.success,3)
        Txt("ed_aa_lbl",x+340,bbY+9,"AUTO x"..S.autoApplyCount,T.success,10,3)
    else hide("ed_aa_dot"); hide("ed_aa_lbl") end
    if S.editorStatus~="" then
        Txt("ed_st",x+420,bbY+10,S.editorStatus,S.editorStatusColor or T.sub,11,3)
    else hide("ed_st") end
    local hasChanges = S.originalLines and #S.originalLines>0
    local rvW=60; local rvX=x+w-150-PAD-rvW-4
    if hasChanges and not S.editValueInst then
        Box("ed_rv",rvX,bbY+6,rvW,24,inB(rvX,bbY+6,rvW,24) and Color3.fromRGB(120,40,40) or Color3.fromRGB(80,25,25),3,CR)
        Txt("ed_rv_t",rvX+rvW/2,bbY+18,"Revert",T.text,11,4,true)
    else hide("ed_rv"); hide("ed_rv_t") end
    local abW=150; local abX=x+w-abW-PAD; local abY=bbY+6
    if S.editValueInst then
        Box("ed_ap",abX,abY,abW,24,inB(abX,abY,abW,24,CR) and T.accentHi or T.accent,3,CR)
        Txt("ed_ap_t",abX+abW/2,abY+12,"Set Value",T.text,12,4,true)
    else
        Box("ed_ap",abX,abY,abW,24,inB(abX,abY,abW,24,CR) and T.accentHi or T.accent,3,CR)
        Txt("ed_ap_t",abX+abW/2,abY+12,"Apply via setgc",T.text,12,4,true)
    end

    if S.diffPanelOpen and #S.diffResults>0 then
        local dpW=320; local dpX=x+w-dpW-PAD; local dpY=bbY-math.min(#S.diffResults,8)*18-12
        Box("ed_diff_bg",dpX,dpY,dpW,math.min(#S.diffResults,8)*18+28,T.panel2,20,CR)
        Outline("ed_diff_o",dpX,dpY,dpW,math.min(#S.diffResults,8)*18+28,T.border,21,CR)
        Txt("ed_diff_hdr",dpX+8,dpY+6,"VALUE DIFF (click to close)",T.sub,10,21)
        for i=1,math.min(#S.diffResults,8) do
            local r=S.diffResults[i]; local dy=dpY+20+(i-1)*18
            local col=r.match and T.hintOk or T.err
            local sym=r.match and "✓" or "✗"
            Txt("ed_diff_"..i,dpX+8,dy,sym.." "..r.key.." = "..r.requested..(r.match and "" or " (got "..r.actual..")"),col,10,21)
        end
        for i=#S.diffResults+1,9 do hide("ed_diff_"..i) end
    else
        for _,id in ipairs({"ed_diff_bg","ed_diff_o","ed_diff_hdr"}) do hide(id) end
        for i=1,9 do hide("ed_diff_"..i) end
    end

    if S.crossSearchOpen then
        local csW=w-60; local csH=math.min(#S.crossSearchResults*16+52,200)
        local csX=x+30; local csY=codeY+20
        Box("ed_cs_bg",csX,csY,csW,csH,T.panel2,22,CR)
        Outline("ed_cs_o",csX,csY,csW,csH,T.accent,23,CR)
        Txt("ed_cs_lbl",csX+8,csY+6,"CROSS-TAB SEARCH",T.accent,10,23)
        local csiX=csX+130; local csiW=csW-200
        Box("ed_cs_inp",csiX,csY+3,csiW,16,T.bg,23,2)
        Outline("ed_cs_inp_o",csiX,csY+3,csiW,16,S.crossSearchFocused and T.accent or T.border,24,2)
        local csd=S.crossSearchQuery..(S.crossSearchFocused and (math.floor(tick()*2)%2==0 and "|" or "") or "")
        Txt("ed_cs_q",csiX+4,csY+5,csd=="" and not S.crossSearchFocused and "search all tabs…" or csd,csd=="" and T.sub or T.text,10,24)
        local csbX=csiX+csiW+4
        Box("ed_cs_btn",csbX,csY+3,52,16,inB(csbX,csY+3,52,16) and T.accentHi or T.accent,23,CR)
        Txt("ed_cs_btn_t",csbX+26,csY+11,"Search",T.text,10,24,true)
        Txt("ed_cs_esc",csX+csW-46,csY+6,"ESC close",T.sub,9,23)
        if #S.crossSearchResults>0 then
            for i=1,math.min(#S.crossSearchResults,8) do
                local r=S.crossSearchResults[i]; local ry2=csY+24+(i-1)*16
                local hov=inB(csX+4,ry2,csW-8,15)
                Box("ed_cs_r_"..i,csX+4,ry2,csW-8,15,hov and T.panel or T.surface,23)
                local lbl="["..r.tabLabel..":"..r.lineIdx.."] "..r.line:match("^%s*(.-)%s*$")
                if #lbl>72 then lbl=lbl:sub(1,72).."…" end
                Txt("ed_cs_rt_"..i,csX+8,ry2+2,lbl,T.sub,10,24)
            end
            for i=#S.crossSearchResults+1,9 do hide("ed_cs_r_"..i); hide("ed_cs_rt_"..i) end
        elseif S.crossSearchQuery~="" then
            Txt("ed_cs_none",csX+8,csY+28,"No matches across "..#S.tabs.." tabs",T.sub,10,23)
            for i=1,9 do hide("ed_cs_r_"..i); hide("ed_cs_rt_"..i) end
        else
            for i=1,9 do hide("ed_cs_r_"..i); hide("ed_cs_rt_"..i) end
            hide("ed_cs_none")
        end
    else
        for _,id in ipairs({"ed_cs_bg","ed_cs_o","ed_cs_lbl","ed_cs_inp","ed_cs_inp_o",
            "ed_cs_q","ed_cs_btn","ed_cs_btn_t","ed_cs_esc","ed_cs_none"}) do hide(id) end
        for i=1,9 do hide("ed_cs_r_"..i); hide("ed_cs_rt_"..i) end
    end
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

    Box("st_bg",cx,cy,cw,ch,T.surface,2,CR)
    Outline("st_bg_o",cx,cy,cw,ch,T.border,3,CR)

    local sbW=12; local sbX=cx+cw-sbW-2
    Box("st_sb_track",sbX,cy+4,sbW,ch-8,T.panel2,3,6)

    local lx=cx+14
    S.settingsScroll=math.max(0,math.min(S.settingsMaxScroll,S.settingsScroll))
    local ry=cy-S.settingsScroll

    ry=ry+10
    Box("st_s1_tag",lx,ry,cw-28,18,T.tag,3)
    Txt("st_s1_lbl",lx+8,ry+3,"MENU HOTKEY",T.accent,10,4)
    ry=ry+26
    Txt("st_s1_sub",lx,ry,"Press button then tap any key to rebind",T.sub,11,4)
    ry=ry+18

    local btnW=140; local btnH=26; local btnY=ry
    local listening=S.listeningForKey
    Box("st_keybtn",lx,btnY,btnW,btnH,listening and T.accentDim or T.panel2,3,CR)
    Outline("st_keybtn_o",lx,btnY,btnW,btnH,listening and T.accent or T.border,3,CR)
    Txt("st_keytxt",lx+btnW/2,btnY+btnH/2,
        listening and "Press any key…" or S.menuKeyName,
        listening and T.accentHi or T.text,12,4,true)
    Txt("st_keynote",lx+btnW+12,btnY+7,"Current: "..S.menuKeyName,T.sub,11,4)
    ry=ry+btnH+16

    Box("st_div1",cx+8,ry,cw-16,1,T.sep,3)
    ry=ry+10

    Box("st_s2_tag",lx,ry,cw-28,18,T.tag,3)
    Txt("st_s2_lbl",lx+8,ry+3,"DIFF GUTTER",T.accent,10,4)
    ry=ry+26
    Box("st_dif1",lx,ry+1,10,10,T.diffAdd,3)
    Txt("st_dif1t",lx+16,ry,"New line (added since load)",T.sub,11,4)
    ry=ry+16
    Box("st_dif2",lx,ry+1,10,10,T.diffChg,3)
    Txt("st_dif2t",lx+16,ry,"Modified line",T.sub,11,4)
    ry=ry+22

    Box("st_div2",cx+8,ry,cw-16,1,T.sep,3)
    ry=ry+10

    Box("st_s3_tag",lx,ry,cw-28,18,T.tag,3)
    Txt("st_s3_lbl",lx+8,ry+3,"AUTO-APPLY",T.accent,10,4)
    ry=ry+26
    Txt("st_aa_sub",lx,ry,"Keeps ACS values alive after gun events (fire, reload, equip)",T.sub,11,4)
    ry=ry+18

    local aaOn=S.autoApply
    local aaBtnW=100; local aaBtnH=26
    Box("st_aatog",lx,ry,aaBtnW,aaBtnH,aaOn and T.success or T.panel2,3,CR)
    Outline("st_aatog_o",lx,ry,aaBtnW,aaBtnH,aaOn and T.success or T.border,3,CR)
    Txt("st_aatog_t",lx+aaBtnW/2,ry+aaBtnH/2,
        aaOn and "● ON" or "○ OFF",
        aaOn and T.bg or T.textDim,12,4,true)

    Txt("st_aaint_l",lx+aaBtnW+12,ry+7,"Every",T.sub,11,4)
    local aiX=lx+aaBtnW+58; local aiW=48
    local aiVal=tonumber(S.autoApplyIntervalInput)
    local aiLow=aiVal and aiVal>0 and aiVal<1
    Box("st_aaint",aiX,ry+2,aiW,22,T.panel2,3)
    Outline("st_aaint_o",aiX,ry+2,aiW,22,
        S.autoApplyFocused and T.accent or (aiLow and T.warn or T.border),4,CR)
    local aiDisp=S.autoApplyIntervalInput..(S.autoApplyFocused and (math.floor(tick()*2)%2==0 and "|" or "") or "")
    Txt("st_aaint_t",aiX+4,ry+6,aiDisp,aiLow and T.warn or T.text,11,4)
    Txt("st_aaint_s",aiX+aiW+6,ry+7,"sec",T.sub,11,4)

    ry=ry+aaBtnH+6
    if aaOn then
        Txt("st_aacnt",lx,ry,"Applied "..S.autoApplyCount.." time(s) this session — interval: "
            ..S.autoApplyInterval.."s",T.success,11,4)
    else
        Txt("st_aacnt",lx,ry,"Toggle ON to start. Only applies while Editor tab is active.",T.sub,11,4)
    end
    ry=ry+22
    if aiLow then
        Txt("st_aa_warn",lx,ry,"⚠ Low interval values (<1s) can cause crashes or freezes.",T.warn,10,4)
    else
        hide("st_aa_warn")
    end
    ry=ry+(aiLow and 14 or 0)

    Box("st_div3",cx+8,ry,cw-16,1,T.sep,3); ry=ry+10

    Box("st_s_theme_tag",lx,ry,cw-28,18,T.tag,3)
    Txt("st_s_theme_lbl",lx+8,ry+3,"THEME",T.accent,10,4)
    ry=ry+26
    local thW=math.floor((cw-28-4*(#THEMES-1))/#THEMES)
    for i,th in ipairs(THEMES) do
        local tx=lx+(i-1)*(thW+4)
        local active=S.themeIdx==i
        Box("st_th_"..i,tx,ry,thW,22,active and T.accent or T.panel2,3,CR)
        Txt("st_th_t"..i,tx+thW/2,ry+11,th.name,active and T.text or T.sub,10,4,true)
    end
    ry=ry+30

    Box("st_div4b",cx+8,ry,cw-16,1,T.sep,3); ry=ry+10

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
    ry=ry+4

    Box("st_div4",cx+8,ry,cw-16,1,T.sep,3); ry=ry+10
    Box("st_s5_tag",lx,ry,cw-28,18,T.tag,3)
    Txt("st_s5_lbl",lx+8,ry+3,"PRESETS",T.accent,10,4)
    ry=ry+24
    Txt("st_pre_sub",lx,ry,"Save editor content as a named preset. Apply to load into a new tab.",T.sub,11,4)
    ry=ry+18

    local piW=cw-28-70-8; local piX=lx
    Box("st_pre_ni",piX,ry,piW,22,T.panel2,3)
    Outline("st_pre_nio",piX,ry,piW,22,S.presetNameFocused and T.accent or T.border,3)
    local pnd=S.presetNameInput..(S.presetNameFocused and (math.floor(tick()*2)%2==0 and "|" or "") or "")
    if pnd=="" and not S.presetNameFocused then
        Txt("st_pre_nt",piX+6,ry+4,"Preset name…",T.sub,11,4)
    else Txt("st_pre_nt",piX+6,ry+4,pnd,T.text,11,4) end
    local savX=piX+piW+6
    Box("st_pre_sav",savX,ry,64,22,inB(savX,ry,64,22) and T.accentHi or T.accent,3)
    Txt("st_pre_savt",savX+32,ry+11,"Save",T.text,11,4,true)
    ry=ry+30

    local presets=S.presets
    if #presets==0 then
        Txt("st_pre_empty",lx,ry,"No presets saved yet.",T.sub,11,4); ry=ry+16
    else
        for i=1,math.min(#presets,6) do
            local p=presets[i]; local sel=S.presetSel==i
            Box("st_pre_"..i,lx,ry,cw-28,20,sel and T.accentDim or T.panel2,3)
            Txt("st_pre_n"..i,lx+6,ry+3,p.name.." ("..#p.lines.." lines)",sel and T.text or T.sub,11,4)
            local apX=lx+cw-28-60; local delX=apX+32
            Box("st_pre_ap"..i,apX,ry+2,28,16,inB(apX,ry+2,28,16) and T.accentHi or T.accent,3)
            Txt("st_pre_apt"..i,apX+14,ry+10,"Apply",T.text,9,4,true)
            Box("st_pre_del"..i,delX,ry+2,24,16,inB(delX,ry+2,24,16) and Color3.fromRGB(120,30,30) or T.panel2,3)
            Txt("st_pre_delt"..i,delX+12,ry+10,"✕",T.sub,10,4,true)
            ry=ry+22
        end
    end
    for i=#presets+1,8 do
        hide("st_pre_"..i); hide("st_pre_n"..i)
        hide("st_pre_ap"..i); hide("st_pre_apt"..i)
        hide("st_pre_del"..i); hide("st_pre_delt"..i)
    end
    local totalH=math.max(1,(ry+20)-(cy-S.settingsScroll))
    local visH=ch
    local maxScroll=math.max(0,totalH-visH)
    S.settingsMaxScroll=maxScroll
    S.settingsScroll=math.max(0,math.min(maxScroll,S.settingsScroll))
    if totalH>visH then
        local thumbH=math.max(24,math.floor(visH/totalH*visH))
        local trackH=visH-8
        local thumbY=cy+4+math.floor(S.settingsScroll/math.max(1,maxScroll)*(trackH-thumbH))
        thumbY=math.max(cy+4,math.min(cy+4+trackH-thumbH,thumbY))
        Box("st_sb_thumb",sbX,thumbY,sbW,thumbH,T.borderHi,4,4)
    else hide("st_sb_thumb") end
end

local function handleInput(dt)
    if not S.visible then return end
    local x,y,w,h=S.x,S.y,S.w,S.h
    local click=input.clicked["m1"]
    local held=input.held["m1"]
    local mx,my=getMouse().X,getMouse().Y

    if click and inB(x+w-28,y+7,22,20) then
        S.visible=false; hidePrefix(""); setrobloxinput(true); return
    end

    if click and inB(x,y,w,TITLE_H) and not inB(x+w-28,y+7,22,20) then
        S.dragging=true; S.dragOX=mx-x; S.dragOY=my-y
    end
    if S.dragging then
        if held then S.x=mx-S.dragOX; S.y=my-S.dragOY else S.dragging=false end
    end

    if click and inB(x,y+TITLE_H,110,TAB_H) then
        S.tab="browser"; S.focused=false; S.pathFocused=false; S.searchFocused=false end
    if click and inB(x+110,y+TITLE_H,110,TAB_H) then
        S.tab="editor"; S.pathFocused=false end
    if click and inB(x+220,y+TITLE_H,110,TAB_H) then
        S.tab="settings"; S.focused=false; S.pathFocused=false; S.searchFocused=false end

    if S.tab=="settings" then
        local cx=x+PAD; local lx=cx+14; local cw=w-PAD*2
        local ch=h-HEADER_H-PAD*2
        local sbW2=12; local sbX=cx+cw-sbW2-2

        if wheelDelta~=0 and inB(cx,y+HEADER_H+PAD,cw,ch) then
            S.settingsScroll=math.max(0,S.settingsScroll+wheelDelta*12)
            wheelDelta=0
        end
        if (held or click) and inB(sbX,y+HEADER_H+PAD+4,sbW2+4,ch-8) then
            S.settingsScrollDrag=true
        end
        if not held then S.settingsScrollDrag=false end
        if S.settingsScrollDrag then
            local relY=math.max(0,math.min(1,(mouse.Y-(y+HEADER_H+PAD+4))/math.max(1,ch-8)))
            S.settingsScroll=math.floor(relY*math.max(1,S.settingsMaxScroll))
        end

        local ry=y+HEADER_H+PAD-S.settingsScroll
        ry=ry+10; ry=ry+26; ry=ry+18
        local btnY=ry
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
        ry=ry+26+16
        ry=ry+10
        ry=ry+26
        ry=ry+16
        ry=ry+22
        ry=ry+10
        ry=ry+26
        ry=ry+18
        local aaY=ry
        if click and inB(lx,aaY,100,26) then
            S.autoApply=not S.autoApply; S.autoApplyTimer=0
            if not S.autoApply then S.autoApplyCount=0 end
        end
        local aiX=lx+100+58; local aiY=aaY+2
        if click and inB(aiX,aiY,48,22) then
            S.autoApplyFocused=true
        elseif click then
            if S.autoApplyFocused then
                local v=tonumber(S.autoApplyIntervalInput)
                if v and v>0 then S.autoApplyInterval=v
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
                        if v and v>0 then S.autoApplyInterval=v
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

        local themeRy = y+HEADER_H+PAD - S.settingsScroll + 10+26+18+42+10+26+16+22+10+26+18+32+22+10+26
        local thW2=math.floor((cw-28-4*(#THEMES-1))/#THEMES)
        for i=1,#THEMES do
            local ttx=lx+(i-1)*(thW2+4)
            if click and inB(ttx,themeRy,thW2,22) then
                S.themeIdx=i; applyTheme(i); saveTheme(i)
            end
        end

        local piW2=cw-28-70-8; local piX2=lx
        local ry2=y+HEADER_H+PAD
        ry2=ry2+10+26+18+26+16+10+26+16+22+10+26+18+26+22+10+10+26+30+10+26+18+24+18+30
        if click and inB(piX2,ry2,piW2,22) then
            S.presetNameFocused=true
        elseif click and not inB(piX2+piW2+6,ry2,64,22) then
            S.presetNameFocused=false
        end
        if S.presetNameFocused then
            local typeKeys={"a","b","c","d","e","f","g","h","i","j","k","l","m",
                "n","o","p","q","r","s","t","u","v","w","x","y","z",
                "0","1","2","3","4","5","6","7","8","9","space","minus","backspace","enter"}
            for _,k in ipairs(typeKeys) do
                if keyRepeating(k,dt) then
                    if k=="backspace" then S.presetNameInput=S.presetNameInput:sub(1,-2)
                    elseif k=="enter" then S.presetNameFocused=false
                    else
                        local c=charMap[k] or k
                        if #c==1 then
                            if isShift() then c=c:upper() end
                            S.presetNameInput=S.presetNameInput..c
                        end
                    end
                end
            end
        end
        if click and inB(piX2+piW2+6,ry2,64,22) and S.presetNameInput~="" then
            savePreset(S.presetNameInput, S.lines)
            S.presetNameInput=""; S.presetNameFocused=false
        end
        local listRy=ry2+30
        for i=1,math.min(#S.presets,6) do
            local apX=piX2+(cw-28)-60; local delX=apX+32
            if click and inB(apX,listRy+2,28,16) then applyPreset(i) end
            if click and inB(delX,listRy+2,24,16) then
                table.remove(S.presets,i)
                S.presetSel=math.min(S.presetSel,math.max(1,#S.presets))
            end
            if click and inB(piX2,listRy,cw-28,20) then S.presetSel=i end
            listRy=listRy+22
        end
        return
    end

    if S.tab=="browser" then
        local cy=y+HEADER_H+PAD
        local lh=h-HEADER_H-PAD*2-28
        local cx=x+PAD; local cw_full=w-PAD*2
        local subTab=S.browserSubTab
        local subBarH=24
        local panelY=cy+subBarH+2
        local panelH=lh-subBarH-2

        local stW=cw_full/2
        if click and inB(cx,cy,stW,subBarH) then S.browserSubTab="tool" end
        if click and inB(cx+stW,cy,stW,subBarH) then S.browserSubTab="game" end

        if subTab=="tool" then
            local lw=SIDEBAR_W; local rx=cx+lw+PAD; local rw=cw_full-lw-PAD
            local tsY2=panelY+26; local tsH2=20; local tsW2=lw-16
            if click and inB(cx+4,tsY2,tsW2,tsH2) then
                S.toolSearchFocused=true; setrobloxinput(false)
            elseif click and not inB(cx+4,tsY2,tsW2,tsH2) then
                S.toolSearchFocused=false
            end
            if S.toolSearchFocused then
                for _,k in ipairs({"a","b","c","d","e","f","g","h","i","j","k","l","m",
                    "n","o","p","q","r","s","t","u","v","w","x","y","z",
                    "0","1","2","3","4","5","6","7","8","9","space","minus","backspace"}) do
                    if keyRepeating(k,dt) then
                        if k=="backspace" then S.toolSearch=S.toolSearch:sub(1,-2)
                        else
                            local ch=charMap[k] or k
                            if #ch==1 then
                                if isShift() then ch=ch:upper() end
                                S.toolSearch=S.toolSearch..ch
                            end
                        end
                        S.toolScroll=0
                    end
                end
            end
            local filteredTools={}
            local tsq=S.toolSearch:lower()
            for _,t in ipairs(S.tools) do
                if tsq=="" or t.label:lower():find(tsq,1,true) then
                    table.insert(filteredTools,t)
                end
            end

            local toolListY=panelY+50; local scanBtnY=panelY+panelH-32
            local toolVis=math.floor((scanBtnY-toolListY-4)/22)
            local slY=panelY+28; local loadBtnY=panelY+panelH-32
            local sVis=math.floor((loadBtnY-slY-4)/22)
            local navItems=S.navItems or {}

            if wheelDelta~=0 and inB(rx,slY,rw,loadBtnY-slY) then
                S.navScroll=math.max(0,math.min(math.max(0,#navItems-sVis),S.navScroll+wheelDelta)); wheelDelta=0
            end
            if #navItems>sVis and (held or click) and inB(rx+rw-12,slY,13,loadBtnY-slY) then
                S.navScroll=math.floor(math.max(0,math.min(1,(mouse.Y-slY)/math.max(1,loadBtnY-slY)))*math.max(1,#navItems-sVis))
            end

            if click and inB(cx,scanBtnY,lw,28) then
                S.tools=scanTools(); S.toolSel=1; S.toolScroll=0
                if #S.tools==0 then S.browserStatus="No tools in backpack"; S.browserStatusColor=T.warn
                else
                    local tool=S.tools[1].inst
                    S.navStack={{inst=tool,name=tool.Name}}; S.navItems=buildNavItems(tool); S.navScroll=0; S.navSel=1
                    S.browserStatus="Found "..#S.tools.." tool(s)"; S.browserStatusColor=T.success
                end
            end

            local sbW2=8; local sbX2=cx+lw-sbW2-2
            local maxToolScroll2=math.max(0,#filteredTools-toolVis)

            if wheelDelta~=0 and inB(cx,toolListY,lw,scanBtnY-toolListY) then
                S.toolScroll=math.max(0,math.min(maxToolScroll2,S.toolScroll+wheelDelta))
                wheelDelta=0
            end
            if #filteredTools>toolVis and (held or click) and inB(sbX2,toolListY,sbW2+4,scanBtnY-toolListY) then
                local trackH=scanBtnY-toolListY-2
                local rel=math.max(0,math.min(1,(mouse.Y-toolListY)/math.max(1,trackH)))
                S.toolScroll=math.floor(rel*math.max(1,maxToolScroll2))
            end

            for i=1,toolVis do
                local absIdx=i+S.toolScroll
                local ft=filteredTools[absIdx]
                if ft and click and inB(cx+1,toolListY+(i-1)*22,lw-sbW2-4,21) then
                    S.toolSel=absIdx; local tool=ft.inst
                    S.navStack={{inst=tool,name=tool.Name}}; S.navItems=buildNavItems(tool); S.navScroll=0; S.navSel=1
                    S.browserStatus=ft.label; S.browserStatusColor=T.sub
                end
            end

            if #S.pinnedScripts>0 then
                local pinY=scanBtnY+32
                for i=1,math.min(#S.pinnedScripts,4) do
                    if click and inB(cx,pinY+14+(i-1)*18,lw,17) then
                        local p=S.pinnedScripts[i]
                        if p.inst then
                            if p.isValue then
                                local hint=p.inst.ClassName
                                local tmpl={hint=="BoolValue" and "false" or hint=="StringValue" and "" or "0"}
                                local snap={lines=tmpl,originalLines=deepCopy(tmpl),scroll=0,scrollX=0,cursorLine=1,cursorChar=1,
                                    currentPath="[Value] "..p.name,currentInst=nil,editValueInst=p.inst,editValueType=hint,
                                    editorStatus="Type value",editorStatusColor=nil,searchOpen=false,searchQuery="",
                                    searchMatches={},searchMatchIdx=1,undoStack={},redoStack={}}
                                saveActiveTab()
                                if #S.lines==0 and S.currentPath=="" then S.tabs[S.activeTab]=snap; restoreTabSnapshot(snap)
                                elseif #S.tabs<MAX_TABS then table.insert(S.tabs,snap); restoreTabSnapshot(snap); S.activeTab=#S.tabs
                                else S.tabs[S.activeTab]=snap; restoreTabSnapshot(snap) end; S.tab="editor"
                            elseif p.isScript then
                                local lines,err=decompileToLines(p.inst)
                                if lines then openInTab(lines,p.inst:GetFullName(),p.inst); S.tab="editor"
                                else S.browserStatus=err; S.browserStatusColor=T.err end
                            end
                        end
                    end
                end
            end

            if click and inB(rx+2,panelY+3,18,18) and #S.navStack>1 then
                table.remove(S.navStack)
                S.navItems=buildNavItems(S.navStack[#S.navStack].inst); S.navScroll=0; S.navSel=1
            end

            for i=1,sVis do
                local item=navItems[i+S.navScroll]
                if item and click and inB(rx+1,slY+(i-1)*22,rw-10,21) then
                    local absIdx=i+S.navScroll
                    if S.navSel==absIdx and item.isContainer and item.hasChildren then
                        table.insert(S.navStack,{inst=item.inst,name=item.name})
                        S.navItems=buildNavItems(item.inst); S.navScroll=0; S.navSel=1
                    else S.navSel=absIdx end
                end
            end

            local selEntry=navItems[S.navSel]
            if selEntry and selEntry.inst then
                local pinBtnW=38; local loadW=rw-pinBtnW-2
                if click and inB(rx+loadW+2,loadBtnY,pinBtnW,28) then
                    local path=selEntry.inst:GetFullName(); local found=false
                    for i2,p in ipairs(S.pinnedScripts) do
                        if p.path==path then table.remove(S.pinnedScripts,i2); found=true; break end
                    end
                    if not found then table.insert(S.pinnedScripts,{name=selEntry.name,path=path,
                        inst=selEntry.inst,isScript=selEntry.isScript,isValue=selEntry.isValue}) end
                end
            end

            -- Tool browser load button
            local loadW2=selEntry and 38 or 0
            if click and selEntry and inB(rx,loadBtnY,rw-loadW2-(loadW2>0 and 2 or 0),28) then
                local rtIsVal = selEntry.inst and isValueType(selEntry.inst)
                local rtIsSc  = selEntry.inst and isScriptType(selEntry.inst)
                if rtIsVal then
                    local hint = selEntry.inst.ClassName
                    local tmpl = hint=="BoolValue" and {"-- Set BoolValue: "..selEntry.inst.Name,"-- Type: true or false","false"}
                        or hint=="StringValue" and {"-- Set StringValue: "..selEntry.inst.Name,"",""}
                        or {"-- Set "..hint..": "..selEntry.inst.Name,"-- Type a number","0"}
                    local snap = {lines=tmpl,originalLines=deepCopy(tmpl),scroll=0,scrollX=0,cursorLine=3,cursorChar=1,
                        currentPath="[Value] "..selEntry.inst.Name.." ["..hint.."]",currentInst=nil,
                        editValueInst=selEntry.inst,editValueType=hint,editorStatus="Type value, then Set Value",
                        editorStatusColor=nil,searchOpen=false,searchQuery="",searchMatches={},searchMatchIdx=1,
                        undoStack={},redoStack={}}
                    saveActiveTab()
                    if #S.lines==0 and S.currentPath=="" then S.tabs[S.activeTab]=snap; restoreTabSnapshot(snap)
                    elseif #S.tabs<MAX_TABS then table.insert(S.tabs,snap); restoreTabSnapshot(snap); S.activeTab=#S.tabs
                    else S.tabs[S.activeTab]=snap; restoreTabSnapshot(snap) end
                    S.tab="editor"
                elseif rtIsSc then
                    local lines,err = decompileToLines(selEntry.inst)
                    if lines then openInTab(lines,selEntry.inst:GetFullName(),selEntry.inst); S.tab="editor"
                    else S.browserStatus=err; S.browserStatusColor=T.err end
                elseif selEntry.isContainer and selEntry.hasChildren then
                    table.insert(S.navStack,{inst=selEntry.inst,name=selEntry.name})
                    S.navItems=buildNavItems(selEntry.inst); S.navScroll=0; S.navSel=1
                end
            end

        else
            -- GAME BROWSER input
            local rw=cw_full
            local inputY=panelY+4; local inputH=26
            local gcBtnW=36; local goBtnW=32
            local inputW=rw-gcBtnW-goBtnW-16
            local goX=cx+inputW+4; local gcX=goX+goBtnW+4
            local filterY=inputY+inputH+4
            local slY=filterY+22; local loadBtnY2=panelY+panelH-32
            local sVis=math.floor((loadBtnY2-slY-4)/22)

            if click and inB(gcX,inputY,gcBtnW,inputH) then
                S.gcBrowseMode=not S.gcBrowseMode; S.gcBulkSel={}
            end

            if S.gcBrowseMode then
                local fW2=52
                if click and inB(cx,filterY,fW2,18) then S.gcBrowseFilter="config" end
                if click and inB(cx+fW2+2,filterY,fW2,18) then S.gcBrowseFilter="all" end
                local scanX=cx+fW2*2+8
                if click and inB(scanX,filterY,60,18) then
                    local res,err=browseGCAll(S.gcBrowseFilter)
                    if res then S.gcBrowseResults=res; S.gcBrowseStatus=#res.." entries"; S.gcBrowseScroll=0; S.scriptSel=1
                    else S.gcBrowseStatus="Error: "..(err or "?") end
                end
            else
                local filters={"all","scripts","values","parts","folders","humanoid"}
                local fW=math.floor(rw/#filters)-1
                for fi,fk in ipairs(filters) do
                    if click and inB(cx+(fi-1)*(fW+1),filterY,fW,18) then
                        S.explorerFilter=fk
                        if S.scriptSearch~="" then
                            S.scriptSearchResults=searchAllScripts(S.scriptSearch,fk)
                            S.scriptSel=1; S.scriptSearchScroll=0
                        end
                    end
                end
            end

            if click and inB(cx,inputY,inputW,inputH) then
                S.scriptSearchFocused=true; S.pathFocused=false; S.focused=false
                setrobloxinput(false)
            elseif click then
                S.scriptSearchFocused=false
            end

            local function doSearch()
                S.scriptSearchResults=searchAllScripts(S.scriptSearch,S.explorerFilter)
                S.scriptSel=1; S.scriptSearchScroll=0; S.scriptSearchFocused=false
            end
            if click and inB(goX,inputY,goBtnW,inputH) then doSearch() end

            if S.scriptSearchFocused then
                if isCtrl() and input.clicked["v"] then
                    local ok,clip=pcall(getclipboard)
                    if ok and type(clip)=="string" then S.scriptSearch=S.scriptSearch..clip:gsub("[^-V]","") end
                end
                local typeKeys={"a","b","c","d","e","f","g","h","i","j","k","l","m",
                    "n","o","p","q","r","s","t","u","v","w","x","y","z",
                    "0","1","2","3","4","5","6","7","8","9",
                    "space","minus","plus","lbracket","rbracket","semicolon",
                    "quote","comma","period","slash","backslash","tilde","backspace","enter"}
                for _,k in ipairs(typeKeys) do
                    if keyRepeating(k,dt) then
                        if k=="backspace" then
                            S.scriptSearch=S.scriptSearch:sub(1,-2)
                            if S.scriptSearch=="" then S.scriptSearchResults={} end
                        elseif k=="enter" then doSearch()
                        else
                            local c=charMap[k] or k
                            if #c==1 then
                                if isShift() and shiftMap[c] then c=shiftMap[c]
                                elseif isShift() then c=c:upper() end
                                S.scriptSearch=S.scriptSearch..c
                            end
                        end
                    end
                end
            end

            local displayItems=S.gcBrowseMode and S.gcBrowseResults or S.scriptSearchResults
            if wheelDelta~=0 then
                if S.gcBrowseMode then S.gcBrowseScroll=math.max(0,math.min(math.max(0,#displayItems-sVis),S.gcBrowseScroll+wheelDelta))
                else S.scriptSearchScroll=math.max(0,math.min(math.max(0,#displayItems-sVis),S.scriptSearchScroll+wheelDelta)) end
                wheelDelta=0
            end
            if #displayItems>sVis and (held or click) and inB(cx+rw-12,slY,13,loadBtnY2-slY) then
                local relY=math.max(0,math.min(1,(mouse.Y-slY)/math.max(1,loadBtnY2-slY)))
                local scr=math.floor(relY*math.max(1,#displayItems-sVis))
                if S.gcBrowseMode then S.gcBrowseScroll=scr else S.scriptSearchScroll=scr end
            end
            local listScroll=S.gcBrowseMode and S.gcBrowseScroll or S.scriptSearchScroll

            for i=1,sVis do
                local sc=displayItems[i+listScroll]
                if sc and click and inB(cx,slY+(i-1)*22,rw-10,21) then
                    local absIdx=i+listScroll
                    if S.gcBrowseMode then
                        if S.gcBulkSel[absIdx] then S.gcBulkSel[absIdx]=nil else S.gcBulkSel[absIdx]=true end
                    end
                    S.scriptSel=absIdx
                end
            end

            if S.gcBrowseMode then
                local selCount=0; for _ in pairs(S.gcBulkSel) do selCount=selCount+1 end
                if selCount>0 then
                    local bvX=cx; local bvW=rw-66
                    if click and inB(bvX,loadBtnY2-26,bvW,20) then S.gcBulkFocused=true
                    elseif click then S.gcBulkFocused=false end
                    if S.gcBulkFocused then
                        for _,k in ipairs({"0","1","2","3","4","5","6","7","8","9","period","minus","a","b","c","d","e","f","backspace","enter"}) do
                            if keyRepeating(k,dt) then
                                if k=="backspace" then S.gcBulkValue=S.gcBulkValue:sub(1,-2)
                                elseif k=="enter" then S.gcBulkFocused=false
                                else local c=charMap[k] or k; if #c==1 then S.gcBulkValue=S.gcBulkValue..c end end
                            end
                        end
                    end
                    if click and inB(cx+rw-62,loadBtnY2-26,60,20) and S.gcBulkValue~="" then
                        local toSet={}; local applied=0
                        for idx in pairs(S.gcBulkSel) do
                            local entry=S.gcBrowseResults[idx]
                            if entry then
                                if entry.vtype=="number" and tonumber(S.gcBulkValue) then toSet[entry.key]=tonumber(S.gcBulkValue); applied=applied+1
                                elseif entry.vtype=="boolean" then toSet[entry.key]=(S.gcBulkValue=="true"); applied=applied+1
                                else toSet[entry.key]=S.gcBulkValue; applied=applied+1 end
                            end
                        end
                        if next(toSet) then pcall(setgc,toSet) end
                        S.gcBrowseStatus="Set "..applied; S.gcBulkSel={}; S.gcBulkValue=""; S.gcBulkFocused=false
                    end
                end
            end

            -- Game browser load button
            local sc2=displayItems[S.scriptSel]
            if click and sc2 and inB(cx,loadBtnY2,rw,28) then
                if S.gcBrowseMode then
                    pushUndo(); local line=sc2.key.." = "..sc2.val
                    if #S.lines==0 then S.lines={line}
                    else table.insert(S.lines,S.cursorLine+1,line); S.cursorLine=S.cursorLine+1; S.cursorChar=#line+1 end
                    saveActiveTab(); S.browserStatus="Inserted: "..line; S.browserStatusColor=T.success
                else
                    local rtIsVal = sc2.inst and isValueType(sc2.inst)
                    local rtIsSc  = sc2.inst and isScriptType(sc2.inst)
                    if rtIsVal then
                        local hint = sc2.inst.ClassName
                        local tmpl = hint=="BoolValue" and {"false"} or hint=="StringValue" and {""} or {"0"}
                        local snap = {lines=tmpl,originalLines=deepCopy(tmpl),scroll=0,scrollX=0,cursorLine=1,cursorChar=1,
                            currentPath="[Value] "..sc2.inst.Name,currentInst=nil,editValueInst=sc2.inst,editValueType=hint,
                            editorStatus="Type value",editorStatusColor=nil,searchOpen=false,searchQuery="",
                            searchMatches={},searchMatchIdx=1,undoStack={},redoStack={}}
                        saveActiveTab()
                        if #S.lines==0 and S.currentPath=="" then S.tabs[S.activeTab]=snap; restoreTabSnapshot(snap)
                        elseif #S.tabs<MAX_TABS then table.insert(S.tabs,snap); restoreTabSnapshot(snap); S.activeTab=#S.tabs
                        else S.tabs[S.activeTab]=snap; restoreTabSnapshot(snap) end
                        S.tab="editor"
                    elseif rtIsSc then
                        local lines,err = decompileToLines(sc2.inst)
                        if lines then openInTab(lines,sc2.inst:GetFullName(),sc2.inst); S.tab="editor"
                        else S.browserStatus=err; S.browserStatusColor=T.err end
                    end
                end
            end
        end  -- end game browser else
    end  -- end browser tab

    if S.tab=="editor" then
        local edY,pathBarY,searchBarY,liBarY,codeY,codeH,codeW,codeStartX,tabBarY=edLayout()
        local visLines=math.floor(codeH/LINE_H)
        local totalLines=#S.lines
        local maxScroll=math.max(0,totalLines-visLines)
        local sbX=x+w-SB_W-2

        local numTabs=math.max(1,#S.tabs)
        local tabW=math.min(150,math.floor((w-28)/numTabs))
        for i=1,numTabs do
            local tx=x+(i-1)*tabW
            if click and inB(tx,tabBarY+2,tabW-1,TAB_BAR_H-4) then
                if inB(tx+tabW-18,tabBarY+2,16,TAB_BAR_H-4) then
                    closeTab(i)
                elseif i~=S.activeTab then
                    switchTab(i)
                end
            end
        end
        local plusX=x+numTabs*tabW
        if numTabs<MAX_TABS and click and inB(plusX,tabBarY+4,20,TAB_BAR_H-8) then
            newTab(); S.tab="editor"
        end

        local maxLineLen=0
        for _,l in ipairs(S.lines) do if #l>maxLineLen then maxLineLen=#l end end
        local visChars=math.floor(codeW/CHAR_W)
        local maxScrollX=math.max(0,maxLineLen-visChars)

        local rbW=64; local rbX=x+w-rbW-PAD
        if S.currentInst and click and inB(rbX,pathBarY+3,rbW,16) then
            local lines,err=decompileToLines(S.currentInst)
            if lines then
                S.lines=lines; S.originalLines=deepCopy(lines)
                S.scroll=math.max(0,math.min(maxScroll,S.scroll))
                S.cursorLine=math.min(S.cursorLine,math.max(1,#lines))
                S.editorStatus="Reloaded "..#lines.." lines"; S.editorStatusColor=T.success
                saveActiveTab()
            else S.editorStatus="Reload failed"; S.editorStatusColor=T.err end
        end

        if isCtrl() and input.clicked["z"] then doUndo() end
        if isCtrl() and input.clicked["y"] then doRedo() end

        if isCtrl() and isShift() and input.clicked["f"] then
            S.crossSearchOpen=not S.crossSearchOpen
            S.crossSearchFocused=S.crossSearchOpen
            S.crossSearchResults={}
        end

        if S.crossSearchOpen then
            if input.clicked["escape"] then
                S.crossSearchOpen=false; S.crossSearchFocused=false
            end
            local csX=x+30; local csiX=csX+130; local csiW=S.w-60-200
            local csbX=csiX+csiW+4
            if click and inB(csiX,codeY+23,csiW,16) then S.crossSearchFocused=true
            elseif click and not inB(csbX,codeY+23,52,16) then S.crossSearchFocused=false end
            if click and inB(csbX,codeY+23,52,16) then
                S.crossSearchResults=runCrossSearch(S.crossSearchQuery)
            end
            for i=1,math.min(#S.crossSearchResults,8) do
                local r=S.crossSearchResults[i]
                local ry2=codeY+40+(i-1)*16+(20)
                if click and inB(csX+4,ry2,S.w-68,15) then
                    switchTab(r.tabIdx)
                    S.cursorLine=r.lineIdx; S.cursorChar=1
                    S.scroll=math.max(0,r.lineIdx-5)
                    S.crossSearchOpen=false; S.crossSearchFocused=false
                end
            end
            if S.crossSearchFocused then
                local typeKeys={"a","b","c","d","e","f","g","h","i","j","k","l","m",
                    "n","o","p","q","r","s","t","u","v","w","x","y","z",
                    "0","1","2","3","4","5","6","7","8","9","space","minus","backspace","enter"}
                for _,k in ipairs(typeKeys) do
                    if keyRepeating(k,dt) then
                        if k=="backspace" then S.crossSearchQuery=S.crossSearchQuery:sub(1,-2)
                        elseif k=="enter" then
                            S.crossSearchResults=runCrossSearch(S.crossSearchQuery)
                            S.crossSearchFocused=false
                        else
                            local c=charMap[k] or k
                            if #c==1 then
                                if isShift() and shiftMap[c] then c=shiftMap[c]
                                elseif isShift() then c=c:upper() end
                                S.crossSearchQuery=S.crossSearchQuery..c
                            end
                        end
                    end
                end
            end
        end

        if isCtrl() and input.clicked["v"] and S.focused then
            local ok,clip=pcall(getclipboard)
            if ok and type(clip)=="string" then
                pushUndo()
                local clipLines={}
                for ln in (clip.."\n"):gmatch("([^\n]*)\n") do
                    table.insert(clipLines, ln:gsub("[^\32-\126]",""))
                end
                if #clipLines==1 then
                    local cur=S.lines[S.cursorLine] or ""
                    S.lines[S.cursorLine]=cur:sub(1,S.cursorChar-1)..clipLines[1]..cur:sub(S.cursorChar)
                    S.cursorChar=S.cursorChar+#clipLines[1]
                else
                    local cur=S.lines[S.cursorLine] or ""
                    local before=cur:sub(1,S.cursorChar-1)
                    local after=cur:sub(S.cursorChar)
                    S.lines[S.cursorLine]=before..clipLines[1]
                    for i=2,#clipLines-1 do
                        table.insert(S.lines, S.cursorLine+i-1, clipLines[i])
                    end
                    local lastIdx=S.cursorLine+#clipLines-1
                    table.insert(S.lines, lastIdx, clipLines[#clipLines]..after)
                    S.cursorLine=lastIdx; S.cursorChar=#clipLines[#clipLines]+1
                end
            end
        end

        if isCtrl() and input.clicked["g"] then
            S.lineJumpOpen=not S.lineJumpOpen
            S.lineJumpInput=""; S.lineJumpFocused=S.lineJumpOpen
        end
        if S.lineJumpOpen then
            if input.clicked["escape"] then
                S.lineJumpOpen=false; S.lineJumpFocused=false; S.lineJumpInput=""
            end
            if S.lineJumpFocused then
                local numKeys={"0","1","2","3","4","5","6","7","8","9","backspace","enter"}
                for _,k in ipairs(numKeys) do
                    if keyRepeating(k,dt) then
                        if k=="backspace" then S.lineJumpInput=S.lineJumpInput:sub(1,-2)
                        elseif k=="enter" then
                            local ln=tonumber(S.lineJumpInput)
                            if ln then
                                ln=math.max(1,math.min(ln,math.max(1,#S.lines)))
                                S.cursorLine=ln; S.cursorChar=1
                                S.scroll=math.max(0,math.min(math.max(0,#S.lines-visLines),ln-math.floor(visLines/2)))
                            end
                            S.lineJumpOpen=false; S.lineJumpFocused=false; S.lineJumpInput=""
                        else S.lineJumpInput=S.lineJumpInput..k end
                    end
                end
            end
        end

        if isCtrl() and input.clicked["f"] then
            S.searchOpen=not S.searchOpen
            if S.searchOpen then S.searchFocused=true
            else S.searchFocused=false; S.searchQuery=""; S.searchMatches={} end
        end
        if S.searchOpen and input.clicked["escape"] then
            S.searchOpen=false; S.searchFocused=false; S.searchQuery=""; S.searchMatches={}
        end

        if S.searchOpen then
            local qx=x+PAD+40; local qw=220
            if click and inB(qx,searchBarY+3,qw,16) then
                S.searchFocused=true; S.focused=false
            end
            if S.searchFocused then
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

        if wheelDelta~=0 then
            if inB(x,codeY,w,codeH) then
                S.scroll=math.max(0,math.min(maxScroll,S.scroll+wheelDelta))
            end
            wheelDelta=0
        end

        if click and inB(sbX,codeY,SB_W+2,codeH) then S.scrollDragging=true end
        if not held then S.scrollDragging=false end
        if S.scrollDragging and totalLines>visLines then
            local tbH=codeH-4; local sH=math.max(20,tbH*(visLines/totalLines))
            local ratio=(my-codeY-sH/2)/math.max(1,tbH-sH)
            S.scroll=math.max(0,math.min(maxScroll,math.floor(ratio*maxScroll+0.5)))
        end

        local hsbY=codeY+codeH; local hsbStartX=x+LN_W+DIFF_W
        if click and inB(hsbStartX,hsbY,codeW,HSB_H) then S.scrollXDragging=true end
        if not held then S.scrollXDragging=false end
        if S.scrollXDragging and maxScrollX>0 then
            local thW=math.max(30,codeW*(visChars/math.max(1,maxLineLen)))
            local ratio=(mx-hsbStartX-thW/2)/math.max(1,codeW-thW)
            S.scrollX=math.max(0,math.min(maxScrollX,math.floor(ratio*maxScrollX+0.5)))
        end

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
                if keyRepeating(k,dt) and not isCtrl() then
                    local cur=S.lines[S.cursorLine] or ""
                    if k=="backspace" then
                        pushUndo()
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
                        pushUndo()
                        local before=cur:sub(1,S.cursorChar-1); local after=cur:sub(S.cursorChar)
                        local indent=before:match("^(%s*)") or ""
                        S.lines[S.cursorLine]=before
                        table.insert(S.lines,S.cursorLine+1,indent..after)
                        S.cursorLine=S.cursorLine+1; S.cursorChar=#indent+1; S.scrollX=0
                        if S.cursorLine>S.scroll+visLines then S.scroll=S.scroll+1 end
                    elseif k=="tab" then
                        pushUndo()
                        S.lines[S.cursorLine]=cur:sub(1,S.cursorChar-1).."    "..cur:sub(S.cursorChar)
                        S.cursorChar=S.cursorChar+4
                        if S.cursorChar>S.scrollX+visChars then S.scrollX=S.cursorChar-visChars end
                    else
                        local c=charMap[k] or k
                        if #c==1 then
                            pushUndo()
                            if isShift() and shiftMap[c] then c=shiftMap[c]
                            elseif isShift() then c=c:upper() end
                            S.lines[S.cursorLine]=cur:sub(1,S.cursorChar-1)..c..cur:sub(S.cursorChar)
                            S.cursorChar=S.cursorChar+1
                            if S.cursorChar>S.scrollX+visChars then S.scrollX=S.cursorChar-visChars end
                        end
                    end
                    break
                end
            end
        end

        local rvW=60; local rvX=x+w-150-PAD-rvW-4
        if S.originalLines and #S.originalLines>0 and not S.editValueInst then
            if click and inB(rvX,y+h-BBH+6,rvW,24) then
                pushUndo()
                S.lines=deepCopy(S.originalLines)
                S.cursorLine=1; S.cursorChar=1; S.scroll=0
                S.editorStatus="Reverted to original"; S.editorStatusColor=T.warn
                S.diffPanelOpen=false
            end
        end

        if S.diffPanelOpen then
            local dpH=math.min(#S.diffResults,8)*18+28
            local dpY=y+h-BBH-dpH-4
            if click and inB(x+w-320-PAD,dpY,320,dpH) then
                S.diffPanelOpen=false
            end
        end

        local abW=150; local abX=x+w-abW-PAD; local abY=y+h-BBH+6
        if click and inB(abX,abY,abW,24) then
            if S.editValueInst then
                local rawVal=""
                for _,l in ipairs(S.lines) do
                    local trimmed=l:match("^%s*(.-)%s*$")
                    if trimmed~="" then rawVal=trimmed; break end
                end
                local ok,err=pcall(function()
                    local vtype=S.editValueType
                    if vtype=="BoolValue" then
                        S.editValueInst.Value=(rawVal=="true" or rawVal=="1")
                    elseif vtype=="NumberValue" or vtype=="IntValue"
                        or vtype=="DoubleConstrainedValue" or vtype=="IntConstrainedValue" then
                        S.editValueInst.Value=tonumber(rawVal) or S.editValueInst.Value
                    else
                        S.editValueInst.Value=rawVal
                    end
                end)
                if ok then
                    S.editorStatus="Value set to: "..rawVal; S.editorStatusColor=T.success
                else
                    S.editorStatus="Set failed: "..(err or "?"); S.editorStatusColor=T.err
                end
            else
                local applied,failed,notInGC=applyLinesGC(S.lines)
                local parts={}
                if applied>0 then table.insert(parts,"Applied "..applied) end
                if #notInGC>0 then
                    local ng=#notInGC>3 and table.concat(notInGC,",",1,3).."…" or table.concat(notInGC,",")
                    table.insert(parts,"Not in GC: "..ng); S.editorStatusColor=T.warn
                elseif #failed>0 then
                    table.insert(parts,"Parse err: "..table.concat(failed,",",1,math.min(3,#failed)))
                    S.editorStatusColor=T.warn
                else S.editorStatusColor=T.success end
                S.editorStatus=table.concat(parts," | ")
                if applied>0 then
                    local appliedPairs={}
                    for _,line in ipairs(S.lines) do
                        local k,v=line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
                        if k and v~="" then table.insert(appliedPairs,{key=k,value=v}) end
                    end
                    if #appliedPairs>0 then
                        S.diffResults=runValueDiff(appliedPairs)
                        S.diffPanelOpen=true
                    end
                end
            end
        end
    end  -- end editor tab
end  -- end handleInput

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

    if S.autoApply and S.tab=="editor" and #S.lines>0 then
        S.autoApplyTimer=S.autoApplyTimer+dt
        if S.autoApplyTimer>=S.autoApplyInterval then
            S.autoApplyTimer=0
            S.autoApplyCount=S.autoApplyCount+1
            applyLinesGC(S.lines)
        end
    end

    local anyTyping = S.pathFocused or S.searchFocused or S.scriptSearchFocused
        or S.autoApplyFocused or S.listeningForKey or S.lineJumpFocused or S.gcBulkFocused
        or S.crossSearchFocused or S.presetNameFocused or S.toolSearchFocused
        or (S.tab=="editor" and S.focused)
        or (S.tab=="browser" and S.browserSubTab=="game" and S.scriptSearchFocused)
    setrobloxinput(not anyTyping)

    renderWindow()

    if S.tab~=prevTab then
        if prevTab=="editor" then saveActiveTab() end
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
