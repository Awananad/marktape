--[[
    ██╗   ██╗ █████╗ ██████╗ ██╗  ██╗████████╗ █████╗ ██████╗ ███████╗
    ███╗ ███║██╔══██╗██╔══██╗██║ ██╔╝╚══██╔══╝██╔══██╗██╔══██╗██╔════╝
    ████████║███████║██████╔╝█████╔╝    ██║   ███████║██████╔╝█████╗
    ██╔══██║██╔══██║██╔══██╗██╔═██╗    ██║   ██╔══██║██╔═══╝ ██╔══╝
    ██║  ██║██║  ██║██║  ██║██║  ██╗   ██║   ██║  ██║██║     ███████╗
    ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚══════╝
    Da Strike v8 — Precise Speed / Clean Camera
]]
local Players=game:GetService("Players")
local RS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local TS=game:GetService("TweenService")
local Stats=game:GetService("Stats")
local LP=Players.LocalPlayer
local Camera=workspace.CurrentCamera

local Config={
    Aimbot={Enabled=false,Bind=Enum.UserInputType.MouseButton2,BindIsKB=false,BindMode="Hold",
        PredictionX=0.12,PredictionY=0.12,AutoPrediction=false,Smooth=5,HitPart="Head",
        FOVRadius=200,ShowFOV=true,RagdollCheck=true},
    Speed={Enabled=false,Bind=Enum.KeyCode.LeftShift,BindIsKB=true,BindMode="Press",Value=0.5,
        CamLag=3.5,CamFOV=15,CamTilt=4,CamSmooth=0.07},
    Menu={Bind=Enum.KeyCode.RightControl,BindIsKB=true,AnimSpeed=0.25},
    Misc={ShowBindList=true,ShowWatermark=true,MenuOpacity=1.0,
        WatermarkAnim="Pulse",WatermarkAnimSpeed=1.0},
}

local State={AimHold=false,AimPressed=false,SpeedHold=false,SpeedPressed=false,
    LockedTarget=nil,MenuOpen=true,MenuTweening=false,
    CamLagOffset=Vector3.new(0,0,0),CamFOVCurrent=0,CamTiltCurrent=0,
    BaseFOV=70,IsMoving=false}

local PingTiers={
    {max=40,px=0.04,py=0.04},{max=60,px=0.06,py=0.06},{max=80,px=0.085,py=0.085},
    {max=100,px=0.11,py=0.11},{max=130,px=0.135,py=0.135},{max=160,px=0.16,py=0.16},
    {max=200,px=0.19,py=0.19},{max=250,px=0.22,py=0.22},{max=999,px=0.28,py=0.28},
}

local T={
    accent=Color3.fromRGB(200,55,55),accentH=Color3.fromRGB(225,72,72),
    bg=Color3.fromRGB(16,16,28),bg2=Color3.fromRGB(22,22,36),bg3=Color3.fromRGB(30,30,48),
    text=Color3.fromRGB(215,215,228),dim=Color3.fromRGB(115,115,145),
    border=Color3.fromRGB(42,42,62),togOn=Color3.fromRGB(200,55,55),
    togOff=Color3.fromRGB(48,48,68),inputBG=Color3.fromRGB(25,25,40),
    slFill=Color3.fromRGB(200,55,55),slBG=Color3.fromRGB(30,30,48),
    green=Color3.fromRGB(55,200,85),yellow=Color3.fromRGB(220,180,50),orange=Color3.fromRGB(230,130,50),
}
local ModeColors={Always=T.green,Hold=T.accent,Press=T.yellow}
local TL,TU={},{}
local function tl(o,p,k) table.insert(TL,{o,p,k}) end
local function tu(fn) table.insert(TU,fn) end
local FOVCircle,FOVExists,LockLine,LockCircle

local function deriveTheme()
    local r,g,b=T.accent.R*255,T.accent.G*255,T.accent.B*255
    T.accentH=Color3.fromRGB(math.min(255,r+25),math.min(255,g+17),math.min(255,b+17))
    T.togOn=T.accent;T.slFill=T.accent;ModeColors.Hold=T.accent
    local br,bg_,bb=T.bg.R*255,T.bg.G*255,T.bg.B*255
    T.bg2=Color3.fromRGB(math.min(255,br+6),math.min(255,bg_+6),math.min(255,bb+8))
    T.bg3=Color3.fromRGB(math.min(255,br+14),math.min(255,bg_+14),math.min(255,bb+20))
    T.border=Color3.fromRGB(math.min(255,br+26),math.min(255,bg_+26),math.min(255,bb+34))
    T.togOff=Color3.fromRGB(math.min(255,br+32),math.min(255,bg_+32),math.min(255,bb+40))
    T.inputBG=Color3.fromRGB(math.min(255,br+9),math.min(255,bg_+9),math.min(255,bb+12))
    T.slBG=Color3.fromRGB(math.min(255,br+14),math.min(255,bg_+14),math.min(255,bb+20))
end
local function applyTheme()
    deriveTheme()
    for _,l in ipairs(TL) do pcall(function() l[1][l[2]]=T[l[3]] end) end
    for _,fn in ipairs(TU) do pcall(fn) end
    pcall(function() if FOVCircle then FOVCircle.Color=T.accent end end)
end
local Presets={
    {"MarkTape",Color3.fromRGB(200,55,55),Color3.fromRGB(16,16,28)},
    {"Midnight",Color3.fromRGB(55,120,220),Color3.fromRGB(12,14,24)},
    {"Emerald",Color3.fromRGB(55,200,85),Color3.fromRGB(14,20,16)},
    {"Phantom",Color3.fromRGB(160,100,255),Color3.fromRGB(18,14,26)},
    {"Sakura",Color3.fromRGB(230,100,160),Color3.fromRGB(22,14,20)},
    {"Cyber",Color3.fromRGB(255,170,30),Color3.fromRGB(22,18,12)},
    {"Arctic",Color3.fromRGB(50,200,220),Color3.fromRGB(14,18,22)},
    {"Mono",Color3.fromRGB(180,180,190),Color3.fromRGB(20,20,20)},
}

local function make(c,p)
    local o=Instance.new(c);for k,v in pairs(p) do if k~="Parent" then o[k]=v end end
    if p.Parent then o.Parent=p.Parent end;return o
end
local function tw(obj,props,dur,cb)
    local t=TS:Create(obj,TweenInfo.new(dur or 0.2,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),props)
    if cb then t.Completed:Connect(cb) end;t:Play();return t
end
local function keyName(key,isKB)
    if isKB then return tostring(key):gsub("Enum.KeyCode.","") end
    local m={[Enum.UserInputType.MouseButton1]="MB1",[Enum.UserInputType.MouseButton2]="MB2",
        [Enum.UserInputType.MouseButton3]="MB3"}
    return m[key] or tostring(key):gsub("Enum.UserInputType.","")
end
local function getPing()
    local p=0;pcall(function() p=LP:GetNetworkPing()*1000 end)
    if p<=0 then pcall(function() p=tonumber(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) or 0 end) end
    return math.floor(p)
end
local function getAutoPred()
    local ping=getPing();for _,t in ipairs(PingTiers) do if ping<=t.max then return t.px,t.py end end
    return 0.28,0.28
end
local function lerp(a,b,t) return a+(b-a)*t end

local RagStates={[Enum.HumanoidStateType.Ragdoll]=1,[Enum.HumanoidStateType.FallingDown]=1,
    [Enum.HumanoidStateType.Physics]=1,[Enum.HumanoidStateType.Dead]=1,[Enum.HumanoidStateType.GettingUp]=1}
local function isRagdolled(ch)
    if not ch then return true end;local hum=ch:FindFirstChildOfClass("Humanoid");if not hum then return true end
    local ok,st=pcall(function() return hum:GetState() end)
    if ok and RagStates[st] then return true end;if hum.PlatformStand then return true end
    for _,n in ipairs({"Ragdolled","Ragdoll","IsRagdolled"}) do
        local v=ch:FindFirstChild(n);if v and v:IsA("BoolValue") and v.Value then return true end end
    local ra=false;pcall(function()
        if ch:GetAttribute("Ragdolled") or ch:GetAttribute("Ragdoll") or hum:GetAttribute("Ragdolled") or hum:GetAttribute("Ragdoll") then ra=true end
    end);if ra then return true end
    local hm=false;for _,d in ipairs(ch:GetDescendants()) do
        if d:IsA("Motor6D") and d.Enabled~=false and d.Part0 and d.Part1 and d.Part0:IsDescendantOf(ch) and d.Part1:IsDescendantOf(ch) then hm=true;break end
    end;if not hm then return true end;return false
end
local function isAlive(plr)
    if not plr then return false end;local ch=plr.Character;if not ch then return false end
    local h=ch:FindFirstChildOfClass("Humanoid");if not h or h.Health<=0 then return false end
    return ch:FindFirstChild("HumanoidRootPart")~=nil
end
local function isValidTarget(plr)
    if not isAlive(plr) then return false end
    if Config.Aimbot.RagdollCheck and isRagdolled(plr.Character) then return false end;return true
end
local function isAimActive()
    if not Config.Aimbot.Enabled then return false end;local m=Config.Aimbot.BindMode
    if m=="Always" then return true end;if m=="Hold" then return State.AimHold end
    if m=="Press" then return State.AimPressed end;return false
end
local function isSpeedActive()
    if not Config.Speed.Enabled then return false end;local m=Config.Speed.BindMode
    if m=="Always" then return true end;if m=="Hold" then return State.SpeedHold end
    if m=="Press" then return State.SpeedPressed end;return false
end
local function matchBind(input,bk,bkb)
    if bkb then return input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==bk
    else return input.UserInputType==bk end
end

task.spawn(function() task.wait(0.5);State.BaseFOV=Camera.FieldOfView end)

--================================================================--
--                      SCREEN GUI                                --
--================================================================--
local Gui=make("ScreenGui",{Name="MT_v8",ZIndexBehavior=Enum.ZIndexBehavior.Sibling,ResetOnSpawn=false})
pcall(function() Gui.Parent=game:GetService("CoreGui") end)
if not Gui.Parent then Gui.Parent=LP:WaitForChild("PlayerGui") end

local MenuContainer=make("CanvasGroup",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,GroupTransparency=0,Parent=Gui})
local Main=make("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.new(0,580,0,580),
    Position=UDim2.new(0.5,0,0.5,0),BackgroundColor3=T.bg,BorderSizePixel=0,Parent=MenuContainer})
make("UICorner",{CornerRadius=UDim.new(0,6),Parent=Main});tl(Main,"BackgroundColor3","bg")
local mainStroke=make("UIStroke",{Color=T.border,Thickness=1,Parent=Main});tl(mainStroke,"Color","border")
local MainScale=make("UIScale",{Scale=1,Parent=Main})

local function animOpen()
    if State.MenuTweening then return end;State.MenuTweening=true;State.MenuOpen=true
    MenuContainer.Visible=true;MenuContainer.GroupTransparency=1;MainScale.Scale=0.92
    tw(MenuContainer,{GroupTransparency=0},Config.Menu.AnimSpeed)
    tw(MainScale,{Scale=1},Config.Menu.AnimSpeed,function() State.MenuTweening=false end)
end
local function animClose()
    if State.MenuTweening then return end;State.MenuTweening=true;State.MenuOpen=false
    tw(MenuContainer,{GroupTransparency=1},Config.Menu.AnimSpeed)
    tw(MainScale,{Scale=0.92},Config.Menu.AnimSpeed,function() MenuContainer.Visible=false;State.MenuTweening=false end)
end
local function toggleMenu() if State.MenuOpen then animClose() else animOpen() end end

local Header=make("Frame",{Size=UDim2.new(1,0,0,36),BackgroundColor3=T.bg2,BorderSizePixel=0,Parent=Main})
tl(Header,"BackgroundColor3","bg2")
make("UICorner",{CornerRadius=UDim.new(0,6),Parent=Header})
local hP=make("Frame",{Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,1,-8),BackgroundColor3=T.bg2,BorderSizePixel=0,Parent=Header})
tl(hP,"BackgroundColor3","bg2")
local hTitle=make("TextLabel",{Size=UDim2.new(0,100,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,
    Text="MARKTAPE",TextColor3=T.accent,Font=Enum.Font.GothamBold,TextSize=14,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=Header});tl(hTitle,"TextColor3","accent")
make("TextLabel",{Size=UDim2.new(0,150,1,0),Position=UDim2.new(0,108,0,0),BackgroundTransparency=1,
    Text="| Da Strike v8",TextColor3=T.dim,Font=Enum.Font.Gotham,TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=Header})
local CloseBtn=make("TextButton",{Size=UDim2.new(0,36,0,36),Position=UDim2.new(1,-36,0,0),
    BackgroundTransparency=1,Text="×",TextColor3=T.dim,Font=Enum.Font.GothamBold,TextSize=20,Parent=Header})
CloseBtn.MouseEnter:Connect(function() tw(CloseBtn,{TextColor3=T.accent},0.15) end)
CloseBtn.MouseLeave:Connect(function() tw(CloseBtn,{TextColor3=T.dim},0.15) end)
CloseBtn.MouseButton1Click:Connect(animClose)
local accentLine=make("Frame",{Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,0,36),
    BackgroundColor3=T.accent,BorderSizePixel=0,Parent=Main});tl(accentLine,"BackgroundColor3","accent")

do local dr,dS,sP
    Header.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true;dS=i.Position;sP=Main.Position end end)
    Header.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end)
    UIS.InputChanged:Connect(function(i) if dr and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-dS;Main.Position=UDim2.new(sP.X.Scale,sP.X.Offset+d.X,sP.Y.Scale,sP.Y.Offset+d.Y) end end)
end

local TabBar=make("Frame",{Size=UDim2.new(1,0,0,32),Position=UDim2.new(0,0,0,38),BackgroundColor3=T.bg2,BorderSizePixel=0,Parent=Main})
tl(TabBar,"BackgroundColor3","bg2")
local ContentArea=make("Frame",{Size=UDim2.new(1,-20,1,-80),Position=UDim2.new(0,10,0,74),
    BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true,Parent=Main})
local allTabs={}
local function addTab(name,order)
    local btn=make("TextButton",{Size=UDim2.new(0,116,1,0),Position=UDim2.new(0,(order-1)*116,0,0),
        BackgroundTransparency=1,Text=name,TextColor3=T.dim,Font=Enum.Font.GothamSemibold,TextSize=12,Parent=TabBar})
    local ind=make("Frame",{Size=UDim2.new(0.6,0,0,2),Position=UDim2.new(0.2,0,1,-2),
        BackgroundColor3=T.accent,BorderSizePixel=0,Visible=false,Parent=btn})
    make("UICorner",{CornerRadius=UDim.new(0,1),Parent=ind});tl(ind,"BackgroundColor3","accent")
    local content=make("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
        BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=T.accent,Visible=false,
        CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Parent=ContentArea})
    tl(content,"ScrollBarImageColor3","accent")
    make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8),Parent=content})
    make("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,8),Parent=content})
    local tab={Btn=btn,Ind=ind,Content=content};table.insert(allTabs,tab)
    btn.MouseButton1Click:Connect(function()
        for _,t2 in ipairs(allTabs) do t2.Content.Visible=false;t2.Ind.Visible=false;tw(t2.Btn,{TextColor3=T.dim},0.15) end
        content.Visible=true;ind.Visible=true;tw(btn,{TextColor3=T.text},0.15)
    end);return content
end

-- Bind Mode Popup
local activePopupCB,popupJust=nil,false
local BindPopup=make("Frame",{Size=UDim2.new(0,120,0,0),AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundColor3=T.bg,BorderSizePixel=0,Visible=false,ZIndex=10,Parent=Gui})
tl(BindPopup,"BackgroundColor3","bg")
make("UICorner",{CornerRadius=UDim.new(0,5),Parent=BindPopup})
local popSt=make("UIStroke",{Color=T.accent,Thickness=1,Parent=BindPopup});tl(popSt,"Color","accent")
make("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder,Parent=BindPopup})
make("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),Parent=BindPopup})
local popScale=make("UIScale",{Scale=1,Parent=BindPopup})
local popBtns={}
for i,mode in ipairs({"Always","Hold","Press"}) do
    local ic=mode=="Always" and "⚡ " or mode=="Hold" and "✊ " or "👆 "
    local mb=make("TextButton",{Size=UDim2.new(1,0,0,26),BackgroundColor3=T.bg2,BackgroundTransparency=0.5,
        Text=ic..mode,TextColor3=T.text,Font=Enum.Font.GothamSemibold,TextSize=11,LayoutOrder=i,Parent=BindPopup})
    make("UICorner",{CornerRadius=UDim.new(0,4),Parent=mb});popBtns[mode]=mb
    mb.MouseEnter:Connect(function() tw(mb,{BackgroundColor3=ModeColors[mode],BackgroundTransparency=0.15},0.1) end)
    mb.MouseLeave:Connect(function() tw(mb,{BackgroundColor3=T.bg2,BackgroundTransparency=0.5},0.1) end)
    mb.MouseButton1Click:Connect(function() if activePopupCB then activePopupCB(mode) end;BindPopup.Visible=false end)
end
local function showPopup(anchor,curMode,cb)
    activePopupCB=cb;popupJust=true;task.delay(0.15,function() popupJust=false end)
    local ap,as=anchor.AbsolutePosition,anchor.AbsoluteSize
    BindPopup.Position=UDim2.new(0,math.clamp(ap.X,0,Camera.ViewportSize.X-130),0,ap.Y+as.Y+4)
    for mode,mb2 in pairs(popBtns) do
        if mode==curMode then mb2.TextColor3=ModeColors[mode];mb2.BackgroundTransparency=0.1
        else mb2.TextColor3=T.text;mb2.BackgroundTransparency=0.5 end
    end;popScale.Scale=0.9;BindPopup.Visible=true;tw(popScale,{Scale=1},0.15)
end
UIS.InputBegan:Connect(function(input)
    if not BindPopup.Visible or popupJust then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.MouseButton2 then
        local p=input.Position;local pp,ps=BindPopup.AbsolutePosition,BindPopup.AbsoluteSize
        if p.X<pp.X or p.X>pp.X+ps.X or p.Y<pp.Y or p.Y>pp.Y+ps.Y then BindPopup.Visible=false end
    end
end)

--================================================================--
--                   CONTROL BUILDERS                             --
--================================================================--
local function addSection(parent,name,order)
    local sec=make("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundColor3=T.bg2,BorderSizePixel=0,LayoutOrder=order or 0,Parent=parent})
    tl(sec,"BackgroundColor3","bg2")
    make("UICorner",{CornerRadius=UDim.new(0,5),Parent=sec})
    local st=make("UIStroke",{Color=T.border,Thickness=1,Transparency=0.5,Parent=sec});tl(st,"Color","border")
    make("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),Parent=sec})
    make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6),Parent=sec})
    local lbl=make("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=name,
        TextColor3=T.accent,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=0,Parent=sec})
    tl(lbl,"TextColor3","accent");return sec
end

local function addToggle(parent,name,default,order,cb)
    local fr=make("Frame",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,LayoutOrder=order,Parent=parent})
    make("TextLabel",{Size=UDim2.new(1,-50,1,0),BackgroundTransparency=1,Text=name,
        TextColor3=T.text,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Parent=fr})
    local bg=make("Frame",{Size=UDim2.new(0,36,0,18),Position=UDim2.new(1,-36,0.5,-9),
        BackgroundColor3=default and T.togOn or T.togOff,BorderSizePixel=0,Parent=fr})
    make("UICorner",{CornerRadius=UDim.new(1,0),Parent=bg})
    local ci=make("Frame",{Size=UDim2.new(0,14,0,14),
        Position=default and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7),
        BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Parent=bg})
    make("UICorner",{CornerRadius=UDim.new(1,0),Parent=ci})
    local on=default
    tu(function() bg.BackgroundColor3=on and T.togOn or T.togOff end)
    make("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Parent=fr})
        .MouseButton1Click:Connect(function()
            on=not on;tw(bg,{BackgroundColor3=on and T.togOn or T.togOff})
            tw(ci,{Position=on and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)})
            if cb then cb(on) end
        end)
end

local function addSlider(parent,name,min,max,def,step,order,cb)
    local fr=make("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,LayoutOrder=order,Parent=parent})
    make("TextLabel",{Size=UDim2.new(0.7,0,0,16),BackgroundTransparency=1,Text=name,
        TextColor3=T.text,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Parent=fr})
    local vl=make("TextLabel",{Size=UDim2.new(0.3,0,0,16),Position=UDim2.new(0.7,0,0,0),BackgroundTransparency=1,
        Text=step>=1 and tostring(math.floor(def)) or string.format("%.2f",def),
        TextColor3=T.accent,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right,Parent=fr})
    tl(vl,"TextColor3","accent")
    local bar=make("Frame",{Size=UDim2.new(1,0,0,6),Position=UDim2.new(0,0,0,24),BackgroundColor3=T.slBG,BorderSizePixel=0,Parent=fr})
    tl(bar,"BackgroundColor3","slBG");make("UICorner",{CornerRadius=UDim.new(1,0),Parent=bar})
    local r0=math.clamp((def-min)/(max-min),0,1)
    local fill=make("Frame",{Size=UDim2.new(r0,0,1,0),BackgroundColor3=T.slFill,BorderSizePixel=0,Parent=bar})
    tl(fill,"BackgroundColor3","slFill");make("UICorner",{CornerRadius=UDim.new(1,0),Parent=fill})
    local knob=make("Frame",{Size=UDim2.new(0,12,0,12),Position=UDim2.new(r0,-6,0.5,-6),
        BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=3,Parent=bar})
    make("UICorner",{CornerRadius=UDim.new(1,0),Parent=knob})
    local val,sliding=def,false
    local function sv(v) val=math.clamp(v,min,max);local d=(val-min)/(max-min)
        fill.Size=UDim2.new(d,0,1,0);knob.Position=UDim2.new(d,-6,0.5,-6)
        vl.Text=step>=1 and tostring(math.floor(val)) or string.format("%.2f",val) end
    local function upd(input) local r2=math.clamp((input.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        val=math.clamp(math.floor((min+(max-min)*r2)/step+0.5)*step,min,max);sv(val);if cb then cb(val) end end
    local ha=make("TextButton",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,0,18),BackgroundTransparency=1,Text="",Parent=fr})
    ha.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true;upd(i) end end)
    UIS.InputChanged:Connect(function(i) if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end end)
    return {GetValue=function() return val end,SetValue=function(v) sv(v);if cb then cb(val) end end}
end

local function addDropdown(parent,name,opts,def,order,cb)
    local fr=make("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=order,Parent=parent})
    make("TextLabel",{Size=UDim2.new(0.5,0,1,0),BackgroundTransparency=1,Text=name,
        TextColor3=T.text,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Parent=fr})
    local idx=1;for i,o in ipairs(opts) do if o==def then idx=i end end
    local btn=make("TextButton",{Size=UDim2.new(0.46,0,0,24),Position=UDim2.new(0.54,0,0,2),
        BackgroundColor3=T.inputBG,BorderSizePixel=0,Text="◀  "..opts[idx].."  ▶",
        TextColor3=T.text,Font=Enum.Font.Gotham,TextSize=11,Parent=fr})
    tl(btn,"BackgroundColor3","inputBG")
    make("UICorner",{CornerRadius=UDim.new(0,4),Parent=btn})
    local ds=make("UIStroke",{Color=T.border,Thickness=1,Parent=btn});tl(ds,"Color","border")
    btn.MouseButton1Click:Connect(function()
        idx=idx%#opts+1;btn.Text="◀  "..opts[idx].."  ▶";if cb then cb(opts[idx]) end
    end)
end

local function addKeybind(parent,name,defKey,defIsKB,defMode,order,keyCb,modeCb)
    local fr=make("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=order,Parent=parent})
    make("TextLabel",{Size=UDim2.new(0.5,0,1,0),BackgroundTransparency=1,Text=name,
        TextColor3=T.text,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Parent=fr})
    local key,isKB,mode,listening=defKey,defIsKB,defMode,false
    local btn=make("TextButton",{Size=UDim2.new(0.46,0,0,24),Position=UDim2.new(0.54,0,0,2),
        BackgroundColor3=T.inputBG,BorderSizePixel=0,Text="",TextColor3=ModeColors[defMode] or T.accent,
        Font=Enum.Font.GothamSemibold,TextSize=11,Parent=fr})
    tl(btn,"BackgroundColor3","inputBG")
    make("UICorner",{CornerRadius=UDim.new(0,4),Parent=btn})
    local bs=make("UIStroke",{Color=T.border,Thickness=1,Parent=btn});tl(bs,"Color","border")
    local hint=make("TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,2),
        BackgroundTransparency=1,Text="rmb → mode",TextColor3=Color3.fromRGB(70,70,90),
        Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Right,Parent=fr,Visible=false})
    local function ut()
        if mode=="Always" then btn.Text="⚡ Always" else btn.Text=keyName(key,isKB).."  ·  "..mode end
        btn.TextColor3=ModeColors[mode] or T.accent
    end;ut();tu(function() ut() end)
    btn.MouseEnter:Connect(function() hint.Visible=true end);btn.MouseLeave:Connect(function() hint.Visible=false end)
    btn.MouseButton1Click:Connect(function()
        if listening then return end;BindPopup.Visible=false;listening=true;btn.Text="[  ...  ]";btn.TextColor3=T.accentH end)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton2 and not listening then
            showPopup(btn,mode,function(nm)
                mode=nm;ut();State.AimHold=false;State.AimPressed=false;State.SpeedHold=false;State.SpeedPressed=false;State.LockedTarget=nil
                if modeCb then modeCb(nm) end end) end end)
    UIS.InputBegan:Connect(function(input)
        if not listening then return end
        if input.UserInputType==Enum.UserInputType.Keyboard then
            if input.KeyCode==Enum.KeyCode.Escape then listening=false;ut();return end
            key=input.KeyCode;isKB=true
        elseif input.UserInputType==Enum.UserInputType.MouseButton2 or input.UserInputType==Enum.UserInputType.MouseButton3 then
            key=input.UserInputType;isKB=false
        else return end;listening=false;ut();if keyCb then keyCb(key,isKB) end
    end)
end

local function addKeybindSimple(parent,name,defKey,defIsKB,order,cb)
    local fr=make("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=order,Parent=parent})
    make("TextLabel",{Size=UDim2.new(0.6,0,1,0),BackgroundTransparency=1,Text=name,
        TextColor3=T.text,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Parent=fr})
    local key,isKB,listening=defKey,defIsKB,false
    local btn=make("TextButton",{Size=UDim2.new(0.35,0,0,22),Position=UDim2.new(0.65,0,0.5,-11),
        BackgroundColor3=T.inputBG,BorderSizePixel=0,Text=keyName(defKey,defIsKB),
        TextColor3=T.accent,Font=Enum.Font.GothamSemibold,TextSize=11,Parent=fr})
    tl(btn,"BackgroundColor3","inputBG");tl(btn,"TextColor3","accent")
    make("UICorner",{CornerRadius=UDim.new(0,4),Parent=btn})
    local s2=make("UIStroke",{Color=T.border,Thickness=1,Parent=btn});tl(s2,"Color","border")
    btn.MouseButton1Click:Connect(function() listening=true;btn.Text="[...]";btn.TextColor3=T.accentH end)
    UIS.InputBegan:Connect(function(input)
        if not listening then return end
        if input.UserInputType==Enum.UserInputType.Keyboard then
            if input.KeyCode==Enum.KeyCode.Escape then listening=false;btn.Text=keyName(key,isKB);btn.TextColor3=T.accent;return end
            key=input.KeyCode;isKB=true
        elseif input.UserInputType==Enum.UserInputType.MouseButton2 or input.UserInputType==Enum.UserInputType.MouseButton3 then
            key=input.UserInputType;isKB=false
        else return end;listening=false;btn.Text=keyName(key,isKB);btn.TextColor3=T.accent
        if cb then cb(key,isKB) end
    end)
end

local function addStatus(parent,text,order)
    return make("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text=text,
        TextColor3=T.dim,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=order,Parent=parent})
end

local function addColorPicker(parent,name,default,order,cb)
    local fr=make("Frame",{Size=UDim2.new(1,0,0,100),BackgroundTransparency=1,LayoutOrder=order,Parent=parent})
    local preview=make("Frame",{Size=UDim2.new(0,28,0,14),Position=UDim2.new(1,-28,0,2),
        BackgroundColor3=default,BorderSizePixel=0,Parent=fr})
    make("UICorner",{CornerRadius=UDim.new(0,4),Parent=preview})
    make("UIStroke",{Color=Color3.fromRGB(60,60,80),Thickness=1,Parent=preview})
    make("TextLabel",{Size=UDim2.new(1,-36,0,16),BackgroundTransparency=1,Text=name,
        TextColor3=T.text,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Parent=fr})
    local rV,gV,bV=math.floor(default.R*255),math.floor(default.G*255),math.floor(default.B*255)
    local function buildCh(chN,yO,init,col)
        make("TextLabel",{Size=UDim2.new(0,14,0,12),Position=UDim2.new(0,0,0,yO+4),BackgroundTransparency=1,
            Text=chN,TextColor3=col,Font=Enum.Font.GothamBold,TextSize=10,Parent=fr})
        local nL=make("TextLabel",{Size=UDim2.new(0,28,0,12),Position=UDim2.new(1,-28,0,yO+4),BackgroundTransparency=1,
            Text=tostring(init),TextColor3=T.text,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Right,Parent=fr})
        local bar=make("Frame",{Size=UDim2.new(1,-50,0,8),Position=UDim2.new(0,18,0,yO+6),
            BackgroundColor3=Color3.fromRGB(35,35,50),BorderSizePixel=0,Parent=fr})
        make("UICorner",{CornerRadius=UDim.new(1,0),Parent=bar})
        local rt=init/255
        local fl=make("Frame",{Size=UDim2.new(rt,0,1,0),BackgroundColor3=col,BorderSizePixel=0,Parent=bar})
        make("UICorner",{CornerRadius=UDim.new(1,0),Parent=fl})
        local kn=make("Frame",{Size=UDim2.new(0,10,0,10),Position=UDim2.new(rt,-5,0.5,-5),
            BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=3,Parent=bar})
        make("UICorner",{CornerRadius=UDim.new(1,0),Parent=kn})
        local sl=false
        local hit=make("TextButton",{Size=UDim2.new(1,8,0,18),Position=UDim2.new(0,-4,0,yO),
            BackgroundTransparency=1,Text="",Parent=fr})
        local function setV(v) v=math.clamp(math.floor(v),0,255);local r2=v/255
            fl.Size=UDim2.new(r2,0,1,0);kn.Position=UDim2.new(r2,-5,0.5,-5);nL.Text=tostring(v);return v end
        hit.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sl=true end end)
        UIS.InputChanged:Connect(function(i) if sl and i.UserInputType==Enum.UserInputType.MouseMovement then
            local r2=math.clamp((i.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
            local nv=setV(r2*255)
            if chN=="R" then rV=nv elseif chN=="G" then gV=nv else bV=nv end
            preview.BackgroundColor3=Color3.fromRGB(rV,gV,bV);if cb then cb(Color3.fromRGB(rV,gV,bV)) end
        end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sl=false end end)
        return {SetVal=setV}
    end
    local chR=buildCh("R",22,rV,Color3.fromRGB(220,60,60))
    local chG=buildCh("G",46,gV,Color3.fromRGB(60,220,60))
    local chB=buildCh("B",70,bV,Color3.fromRGB(60,100,220))
    return {SetColor=function(c) rV=math.floor(c.R*255);gV=math.floor(c.G*255);bV=math.floor(c.B*255)
        chR.SetVal(rV);chG.SetVal(gV);chB.SetVal(bV);preview.BackgroundColor3=c end}
end

--================================================================--
--                      BUILD TABS                                --
--================================================================--
local tabAim  = addTab("AIMBOT",   1)
local tabMove = addTab("MOVEMENT", 2)
local tabCfg  = addTab("CONFIG",   3)
local tabMisc = addTab("MISC",     4)
allTabs[1].Content.Visible=true;allTabs[1].Ind.Visible=true;allTabs[1].Btn.TextColor3=T.text

-- AIMBOT
local secAim=addSection(tabAim,"Aimbot",1)
addToggle(secAim,"Enable",Config.Aimbot.Enabled,1,function(v) Config.Aimbot.Enabled=v end)
addKeybind(secAim,"Bind",Config.Aimbot.Bind,Config.Aimbot.BindIsKB,Config.Aimbot.BindMode,2,
    function(k,kb) Config.Aimbot.Bind=k;Config.Aimbot.BindIsKB=kb end,
    function(m) Config.Aimbot.BindMode=m end)
addDropdown(secAim,"Hit Part",
    {"Head","HumanoidRootPart","UpperTorso","LowerTorso","Torso","LeftUpperArm","RightUpperArm"},
    Config.Aimbot.HitPart,3,function(v) Config.Aimbot.HitPart=v end)
addSlider(secAim,"Smooth",1,20,Config.Aimbot.Smooth,0.5,4,function(v) Config.Aimbot.Smooth=v end)

local secRag=addSection(tabAim,"Ragdoll Filter",2)
addToggle(secRag,"Skip Ragdolled",Config.Aimbot.RagdollCheck,1,function(v) Config.Aimbot.RagdollCheck=v end)

local secPred=addSection(tabAim,"Prediction",3)
addToggle(secPred,"Auto Prediction",Config.Aimbot.AutoPrediction,1,function(v) Config.Aimbot.AutoPrediction=v end)
local predXSl=addSlider(secPred,"Prediction X",0,0.5,Config.Aimbot.PredictionX,0.01,2,function(v) Config.Aimbot.PredictionX=v end)
local predYSl=addSlider(secPred,"Prediction Y",0,0.5,Config.Aimbot.PredictionY,0.01,3,function(v) Config.Aimbot.PredictionY=v end)
local autoPredLbl=addStatus(secPred,"Auto: waiting...",4)

local secFOV=addSection(tabAim,"Field of View",4)
addSlider(secFOV,"FOV Radius",50,500,Config.Aimbot.FOVRadius,10,1,function(v) Config.Aimbot.FOVRadius=v end)
addToggle(secFOV,"Show FOV Circle",Config.Aimbot.ShowFOV,2,function(v) Config.Aimbot.ShowFOV=v end)

local secLock=addSection(tabAim,"Target Lock",5)
local lockLbl=addStatus(secLock,"Target: None",1)
local ragLbl=addStatus(secLock,"",2)
local modeLbl=addStatus(secLock,"Mode: Hold",3)

-- MOVEMENT
local secSpd=addSection(tabMove,"CFrame Speed",1)
addToggle(secSpd,"Enable",Config.Speed.Enabled,1,function(v)
    Config.Speed.Enabled=v;if not v then State.SpeedHold=false;State.SpeedPressed=false end end)
addKeybind(secSpd,"Bind",Config.Speed.Bind,Config.Speed.BindIsKB,Config.Speed.BindMode,2,
    function(k,kb) Config.Speed.Bind=k;Config.Speed.BindIsKB=kb end,
    function(m) Config.Speed.BindMode=m end)

-- ★ Speed: 0.01 → 1.00, step 0.01
addSlider(secSpd,"Speed",0.01,1,Config.Speed.Value,0.01,3,function(v) Config.Speed.Value=v end)

local spdLbl=addStatus(secSpd,"Status: OFF",4)
addStatus(secSpd,"Range: 0.01 – 1.00 (precise control)",5)

-- Camera Effects
local secCam=addSection(tabMove,"Camera Effects",2)
addSlider(secCam,"Camera Lag",0,8,Config.Speed.CamLag,0.5,1,function(v) Config.Speed.CamLag=v end)
addSlider(secCam,"FOV Boost",0,40,Config.Speed.CamFOV,1,2,function(v) Config.Speed.CamFOV=v end)
addSlider(secCam,"Camera Tilt",0,12,Config.Speed.CamTilt,0.5,3,function(v) Config.Speed.CamTilt=v end)
addSlider(secCam,"Cam Smooth",0.02,0.2,Config.Speed.CamSmooth,0.01,4,function(v) Config.Speed.CamSmooth=v end)
addStatus(secCam,"Camera stays behind while model runs ahead",5)
addStatus(secCam,"FOV widens during sprint for motion feel",6)
addStatus(secCam,"Tilt adds roll when strafing sideways",7)

-- CONFIG
local secMCfg=addSection(tabCfg,"Menu Settings",1)
addKeybindSimple(secMCfg,"Menu Toggle Bind",Config.Menu.Bind,Config.Menu.BindIsKB,1,function(k,kb)
    Config.Menu.Bind=k;Config.Menu.BindIsKB=kb end)
addSlider(secMCfg,"Animation Speed",0.1,1.0,Config.Menu.AnimSpeed,0.05,2,function(v) Config.Menu.AnimSpeed=v end)

local secHelp=addSection(tabCfg,"Bind Modes",2)
for i,txt in ipairs({"RMB on bind → mode popup","⚡ Always","✊ Hold","👆 Press","LMB → rebind"}) do addStatus(secHelp,txt,i) end

-- MISC
local secPresets=addSection(tabMisc,"Theme Presets",1)
local presetNames={};for _,p in ipairs(Presets) do table.insert(presetNames,p[1]) end
local accentPicker,bgPicker
addDropdown(secPresets,"Preset",presetNames,"MarkTape",1,function(v)
    for _,p in ipairs(Presets) do if p[1]==v then
        T.accent=p[2];T.bg=p[3];applyTheme()
        if accentPicker then accentPicker.SetColor(p[2]) end
        if bgPicker then bgPicker.SetColor(p[3]) end;break end end
end)

local secAcc=addSection(tabMisc,"Accent Color",2)
accentPicker=addColorPicker(secAcc,"Accent",T.accent,1,function(c) T.accent=c;applyTheme() end)

local secBGC=addSection(tabMisc,"Background Color",3)
bgPicker=addColorPicker(secBGC,"Background",T.bg,1,function(c) T.bg=c;applyTheme() end)

local secOp=addSection(tabMisc,"Opacity",4)
addSlider(secOp,"Menu Opacity",0.3,1.0,Config.Misc.MenuOpacity,0.05,1,function(v)
    Config.Misc.MenuOpacity=v;Main.BackgroundTransparency=1-v end)

local secWM=addSection(tabMisc,"Watermark",5)
addToggle(secWM,"Show Watermark",Config.Misc.ShowWatermark,1,function(v) Config.Misc.ShowWatermark=v end)
addDropdown(secWM,"Animation",{"None","Pulse","Shake","Rainbow"},Config.Misc.WatermarkAnim,2,function(v) Config.Misc.WatermarkAnim=v end)
addSlider(secWM,"Anim Speed",0.3,3.0,Config.Misc.WatermarkAnimSpeed,0.1,3,function(v) Config.Misc.WatermarkAnimSpeed=v end)

local secBL=addSection(tabMisc,"Bind List",6)
addToggle(secBL,"Show Bind List",Config.Misc.ShowBindList,1,function(v) Config.Misc.ShowBindList=v end)
addStatus(secBL,"Drag to reposition (menu open only)",2)

--================================================================--
--                      BIND LIST                                 --
--================================================================--
local BindList=make("Frame",{AnchorPoint=Vector2.new(1,0),Size=UDim2.new(0,200,0,0),
    AutomaticSize=Enum.AutomaticSize.Y,Position=UDim2.new(1,-12,0,36),
    BackgroundColor3=T.bg,BackgroundTransparency=0.15,BorderSizePixel=0,Parent=Gui})
tl(BindList,"BackgroundColor3","bg")
make("UICorner",{CornerRadius=UDim.new(0,5),Parent=BindList})
local blStroke=make("UIStroke",{Color=T.accent,Thickness=1,Transparency=0.4,Parent=BindList});tl(blStroke,"Color","accent")
make("UIPadding",{PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),Parent=BindList})
make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),Parent=BindList})
local blTitle=make("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="BINDS",
    TextColor3=T.accent,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=0,Parent=BindList})
tl(blTitle,"TextColor3","accent")
make("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=T.border,BorderSizePixel=0,LayoutOrder=1,Parent=BindList})

local function makeBindEntry(name,order)
    local fr=make("Frame",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,LayoutOrder=order,Visible=false,Parent=BindList})
    local dot=make("Frame",{Size=UDim2.new(0,8,0,8),Position=UDim2.new(0,0,0.5,-4),BackgroundColor3=T.dim,BorderSizePixel=0,Parent=fr})
    make("UICorner",{CornerRadius=UDim.new(1,0),Parent=dot})
    local nL=make("TextLabel",{Size=UDim2.new(0,70,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,
        Text=name,TextColor3=T.text,Font=Enum.Font.GothamSemibold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,Parent=fr})
    local mL=make("TextLabel",{Size=UDim2.new(0,80,1,0),Position=UDim2.new(1,-80,0,0),BackgroundTransparency=1,
        Text="",TextColor3=T.dim,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Right,Parent=fr})
    return {Frame=fr,Dot=dot,Name=nL,Mode=mL}
end

local blAimbot=makeBindEntry("Aimbot",2)
local blAimSub=make("TextLabel",{Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,Text="",
    TextColor3=T.dim,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=3,Visible=false,Parent=BindList})
local blSpeed=makeBindEntry("Speed",4)
local blSpeedSub=make("TextLabel",{Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,Text="",
    TextColor3=T.dim,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=5,Visible=false,Parent=BindList})

do local dr,dS,sP
    BindList.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 and State.MenuOpen then dr=true;dS=i.Position;sP=BindList.Position end end)
    BindList.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end)
    UIS.InputChanged:Connect(function(i) if dr and i.UserInputType==Enum.UserInputType.MouseMovement then
        if not State.MenuOpen then dr=false;return end
        local d=i.Position-dS;BindList.Position=UDim2.new(sP.X.Scale,sP.X.Offset+d.X,sP.Y.Scale,sP.Y.Offset+d.Y) end end)
end

--================================================================--
--                    DRAWING OBJECTS                              --
--================================================================--
pcall(function()
    FOVCircle=Drawing.new("Circle");FOVCircle.Color=T.accent;FOVCircle.Thickness=1.5
    FOVCircle.NumSides=80;FOVCircle.Filled=false;FOVCircle.Visible=false;FOVCircle.Transparency=0.7
    FOVCircle.Radius=200;FOVExists=true
end)
pcall(function()
    LockLine=Drawing.new("Line");LockLine.Color=T.green;LockLine.Thickness=1.5;LockLine.Visible=false;LockLine.Transparency=0.6
end)
pcall(function()
    LockCircle=Drawing.new("Circle");LockCircle.Color=T.green;LockCircle.Thickness=2
    LockCircle.NumSides=40;LockCircle.Filled=false;LockCircle.Visible=false;LockCircle.Transparency=0.5;LockCircle.Radius=18
end)

--================================================================--
--                      WATERMARK                                 --
--================================================================--
local wmBasePos=UDim2.new(0,10,0,6)
local WM=make("Frame",{AnchorPoint=Vector2.new(0,0),Size=UDim2.new(0,380,0,24),
    Position=wmBasePos,BackgroundColor3=T.bg,BackgroundTransparency=0.2,BorderSizePixel=0,
    Visible=Config.Misc.ShowWatermark,Parent=Gui})
tl(WM,"BackgroundColor3","bg")
make("UICorner",{CornerRadius=UDim.new(0,4),Parent=WM})
local wmStroke=make("UIStroke",{Color=T.accent,Thickness=1,Transparency=0.4,Parent=WM});tl(wmStroke,"Color","accent")
local wmBar=make("Frame",{Size=UDim2.new(0,3,1,-6),Position=UDim2.new(0,4,0,3),
    BackgroundColor3=T.accent,BorderSizePixel=0,Parent=WM})
tl(wmBar,"BackgroundColor3","accent");make("UICorner",{CornerRadius=UDim.new(1,0),Parent=wmBar})
local wmLabel=make("TextLabel",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1,Text="marktape.cc | loading...",
    TextColor3=T.text,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Parent=WM})
local wmScale=make("UIScale",{Scale=1,Parent=WM})

local wmTweening,wmLastVisible=false,Config.Misc.ShowWatermark
local function showWM()
    if wmTweening then return end;wmTweening=true;WM.Visible=true;wmScale.Scale=0.9
    tw(WM,{BackgroundTransparency=0.2},0.2);tw(wmScale,{Scale=1},0.2,function() wmTweening=false end)
end
local function hideWM()
    if wmTweening then return end;wmTweening=true
    tw(WM,{BackgroundTransparency=1},0.2);tw(wmScale,{Scale=0.9},0.2,function() WM.Visible=false;wmTweening=false end)
end

local function getClosest()
    local best,bestD=nil,Config.Aimbot.FOVRadius
    local mp=UIS:GetMouseLocation()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LP and isValidTarget(plr) then
            local ch=plr.Character;local part=ch:FindFirstChild(Config.Aimbot.HitPart) or ch:FindFirstChild("Head")
            if part then local sp,vis=Camera:WorldToViewportPoint(part.Position)
                if vis then local d=(Vector2.new(sp.X,sp.Y)-mp).Magnitude;if d<bestD then bestD=d;best=plr end end
            end
        end
    end;return best
end

-- Input
UIS.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if matchBind(input,Config.Menu.Bind,Config.Menu.BindIsKB) then toggleMenu();return end
    if matchBind(input,Config.Aimbot.Bind,Config.Aimbot.BindIsKB) then
        local m=Config.Aimbot.BindMode
        if m=="Hold" then State.AimHold=true;if Config.Aimbot.Enabled then State.LockedTarget=getClosest() end
        elseif m=="Press" then State.AimPressed=not State.AimPressed
            if State.AimPressed and Config.Aimbot.Enabled then State.LockedTarget=getClosest() else State.LockedTarget=nil end end
    end
    if matchBind(input,Config.Speed.Bind,Config.Speed.BindIsKB) then
        local m=Config.Speed.BindMode
        if m=="Hold" then State.SpeedHold=true end
        if m=="Press" then State.SpeedPressed=not State.SpeedPressed end
    end
end)
UIS.InputEnded:Connect(function(input)
    if matchBind(input,Config.Aimbot.Bind,Config.Aimbot.BindIsKB) then
        if Config.Aimbot.BindMode=="Hold" then State.AimHold=false;State.LockedTarget=nil end end
    if matchBind(input,Config.Speed.Bind,Config.Speed.BindIsKB) then
        if Config.Speed.BindMode=="Hold" then State.SpeedHold=false end end
end)

-- Auto pred
task.spawn(function()
    while task.wait(0.5) do
        if Config.Aimbot.AutoPrediction then
            local px,py=getAutoPred();Config.Aimbot.PredictionX=px;Config.Aimbot.PredictionY=py
            predXSl.SetValue(px);predYSl.SetValue(py)
            local ping=getPing()
            autoPredLbl.Text=string.format("Auto: %dms → X:%.2f Y:%.2f",ping,px,py)
            autoPredLbl.TextColor3=ping<80 and T.green or ping<150 and T.yellow or T.accent
        else autoPredLbl.Text="Auto: disabled";autoPredLbl.TextColor3=T.dim end
    end
end)

-- WM text
task.spawn(function()
    local frames,last=0,tick()
    RS.RenderStepped:Connect(function() frames=frames+1 end)
    while task.wait(0.5) do
        local now=tick();local fps=math.floor(frames/(now-last));frames=0;last=now
        wmLabel.Text=string.format("marktape.cc  |  v8  |  %dfps  |  %dms  |  %s",fps,getPing(),os.date("%H:%M:%S"))
    end
end)

-- WM anim
local wmAnimTime=0
RS:BindToRenderStep("WM_Anim",Enum.RenderPriority.Last.Value+1,function(dt)
    if Config.Misc.ShowWatermark~=wmLastVisible then
        wmLastVisible=Config.Misc.ShowWatermark
        if wmLastVisible then showWM() else hideWM() end
    end
    if not Config.Misc.ShowWatermark or not WM.Visible then return end
    local anim=Config.Misc.WatermarkAnim;local speed=Config.Misc.WatermarkAnimSpeed
    wmAnimTime=wmAnimTime+dt*speed
    if anim=="None" then
        wmScale.Scale=1;WM.Position=wmBasePos;wmStroke.Color=T.accent;wmBar.BackgroundColor3=T.accent
        wmLabel.TextColor3=T.text;wmStroke.Transparency=0.4;wmBar.BackgroundTransparency=0
    elseif anim=="Pulse" then
        wmScale.Scale=1+math.sin(wmAnimTime*2)*0.03;WM.Position=wmBasePos
        wmStroke.Color=T.accent;wmBar.BackgroundColor3=T.accent;wmLabel.TextColor3=T.text
        wmStroke.Transparency=0.2+math.sin(wmAnimTime*2)*0.2
        wmBar.BackgroundTransparency=0.15-math.sin(wmAnimTime*2)*0.15
    elseif anim=="Shake" then
        wmScale.Scale=1
        local ox=math.sin(wmAnimTime*17.3)*1.5+math.cos(wmAnimTime*23.7)*0.75
        local oy=math.cos(wmAnimTime*13.1)*1.05+math.sin(wmAnimTime*31.3)*0.45
        WM.Position=UDim2.new(wmBasePos.X.Scale,wmBasePos.X.Offset+ox,wmBasePos.Y.Scale,wmBasePos.Y.Offset+oy)
        wmStroke.Color=T.accent;wmStroke.Transparency=0.4;wmBar.BackgroundColor3=T.accent
        wmBar.BackgroundTransparency=0;wmLabel.TextColor3=T.text
    elseif anim=="Rainbow" then
        wmScale.Scale=1;WM.Position=wmBasePos
        local hue=(wmAnimTime*0.15)%1;local rainbow=Color3.fromHSV(hue,0.8,1)
        wmStroke.Color=rainbow;wmStroke.Transparency=0.2;wmBar.BackgroundColor3=rainbow
        wmBar.BackgroundTransparency=0;wmLabel.TextColor3=Color3.fromHSV((hue+0.1)%1,0.3,1)
    end
end)

--================================================================--
--                    MAIN RENDER LOOP                             --
--================================================================--
RS.RenderStepped:Connect(function(dt)
    Camera=workspace.CurrentCamera
    local mp=UIS:GetMouseLocation()
    local aimActive=isAimActive()
    local spdActive=isSpeedActive()

    if State.BaseFOV==0 or State.BaseFOV==nil then State.BaseFOV=Camera.FieldOfView end

    -- FOV circle
    if FOVExists and FOVCircle then
        FOVCircle.Position=Vector2.new(mp.X,mp.Y);FOVCircle.Radius=Config.Aimbot.FOVRadius
        FOVCircle.Visible=Config.Aimbot.Enabled and Config.Aimbot.ShowFOV end

    -- Target
    local target=State.LockedTarget
    if aimActive and Config.Aimbot.BindMode=="Always" and (not target or not isAlive(target)) then
        State.LockedTarget=getClosest();target=State.LockedTarget end
    if not aimActive then if State.LockedTarget then State.LockedTarget=nil end;target=nil end
    if target and not isAlive(target) then State.LockedTarget=nil;target=nil
        if aimActive then State.LockedTarget=getClosest();target=State.LockedTarget end end

    -- Status
    if target then
        if not isValidTarget(target) then
            lockLbl.Text="Target: "..target.Name.." (ragdoll)";lockLbl.TextColor3=T.orange
            ragLbl.Text="⚠ Waiting...";ragLbl.TextColor3=T.yellow
        else lockLbl.Text="Target: "..target.Name;lockLbl.TextColor3=T.green;ragLbl.Text="✓ Locked";ragLbl.TextColor3=T.green end
    else lockLbl.Text=aimActive and "Searching..." or "Target: None"
        lockLbl.TextColor3=aimActive and T.yellow or T.dim;ragLbl.Text="" end
    modeLbl.Text="Mode: "..Config.Aimbot.BindMode;modeLbl.TextColor3=ModeColors[Config.Aimbot.BindMode] or T.dim

    local spdOn=spdActive
    spdLbl.Text=spdOn and("ON x"..string.format("%.2f",Config.Speed.Value).." ["..Config.Speed.BindMode.."]") or("OFF ["..Config.Speed.BindMode.."]")
    spdLbl.TextColor3=spdOn and T.green or T.dim

    -- Lock visuals
    local sv2=target and isValidTarget(target) and aimActive and Config.Aimbot.Enabled
    if LockLine then
        if sv2 then local ch=target.Character;local part=ch:FindFirstChild(Config.Aimbot.HitPart) or ch:FindFirstChild("Head")
            if part then local sp,vis=Camera:WorldToViewportPoint(part.Position)
                if vis then LockLine.From=Vector2.new(mp.X,mp.Y);LockLine.To=Vector2.new(sp.X,sp.Y);LockLine.Visible=true
                    if LockCircle then LockCircle.Position=Vector2.new(sp.X,sp.Y);LockCircle.Visible=true end
                else LockLine.Visible=false;if LockCircle then LockCircle.Visible=false end end
            else LockLine.Visible=false;if LockCircle then LockCircle.Visible=false end end
        else LockLine.Visible=false;if LockCircle then LockCircle.Visible=false end end
    end

    -- Aimbot
    if aimActive and target and isValidTarget(target) and isAlive(LP) then
        local ch=target.Character;local part=ch:FindFirstChild(Config.Aimbot.HitPart) or ch:FindFirstChild("Head")
        if part then local vel=part.Velocity
            local pp=part.Position+Vector3.new(vel.X*Config.Aimbot.PredictionX,vel.Y*Config.Aimbot.PredictionY,vel.Z*Config.Aimbot.PredictionX)
            Camera.CFrame=Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,pp),1/Config.Aimbot.Smooth)
        end
    end

    --================================================================--
    --              CAMERA LAG / FOV / TILT (clean, no lines)         --
    --================================================================--
    local ch=LP.Character
    local moving=false
    local moveDir=Vector3.new(0,0,0)

    if ch then
        local hum=ch:FindFirstChildOfClass("Humanoid")
        if hum then moveDir=hum.MoveDirection;moving=moveDir.Magnitude>0.1 end
    end

    local smooth=Config.Speed.CamSmooth

    if spdActive and moving and ch then
        State.CamLagOffset=State.CamLagOffset:Lerp(moveDir*Config.Speed.CamLag,smooth)
        State.CamFOVCurrent=lerp(State.CamFOVCurrent,Config.Speed.CamFOV,smooth*1.5)
        local camRight=Camera.CFrame.RightVector
        local sideways=moveDir:Dot(camRight)
        State.CamTiltCurrent=lerp(State.CamTiltCurrent,-sideways*Config.Speed.CamTilt,smooth)
    else
        State.CamLagOffset=State.CamLagOffset:Lerp(Vector3.new(0,0,0),smooth*2)
        State.CamFOVCurrent=lerp(State.CamFOVCurrent,0,smooth*2)
        State.CamTiltCurrent=lerp(State.CamTiltCurrent,0,smooth*2)
        if State.CamLagOffset.Magnitude<0.01 then State.CamLagOffset=Vector3.new(0,0,0) end
        if math.abs(State.CamFOVCurrent)<0.1 then State.CamFOVCurrent=0 end
        if math.abs(State.CamTiltCurrent)<0.01 then State.CamTiltCurrent=0 end
    end

    -- Apply camera lag
    if State.CamLagOffset.Magnitude>0.01 then
        Camera.CFrame=CFrame.new(Camera.CFrame.Position-State.CamLagOffset)*Camera.CFrame.Rotation
    end

    -- Apply FOV
    if math.abs(State.CamFOVCurrent)>0.1 then
        Camera.FieldOfView=State.BaseFOV+State.CamFOVCurrent
    elseif not spdActive and math.abs(Camera.FieldOfView-State.BaseFOV)>0.1 then
        Camera.FieldOfView=lerp(Camera.FieldOfView,State.BaseFOV,0.05)
    end

    -- Apply tilt
    if math.abs(State.CamTiltCurrent)>0.01 then
        Camera.CFrame=Camera.CFrame*CFrame.Angles(0,0,math.rad(State.CamTiltCurrent))
    end

    -- Bind List
    BindList.Visible=Config.Misc.ShowBindList
    local aE=Config.Aimbot.Enabled
    blAimbot.Frame.Visible=aE
    if aE then
        blAimbot.Dot.BackgroundColor3=aimActive and T.green or T.dim
        local bm=Config.Aimbot.BindMode
        blAimbot.Mode.Text=bm=="Always" and "Always" or keyName(Config.Aimbot.Bind,Config.Aimbot.BindIsKB).." · "..bm
        blAimbot.Mode.TextColor3=aimActive and ModeColors[bm] or T.dim
        if aimActive and target then
            blAimSub.Visible=true;blAimSub.Text="   → "..target.Name
            blAimSub.TextColor3=isValidTarget(target) and T.green or T.orange
        else blAimSub.Visible=false end
    else blAimSub.Visible=false end

    local sE=Config.Speed.Enabled
    blSpeed.Frame.Visible=sE
    if sE then
        blSpeed.Dot.BackgroundColor3=spdOn and T.green or T.dim
        local bm2=Config.Speed.BindMode
        blSpeed.Mode.Text=bm2=="Always" and "Always" or keyName(Config.Speed.Bind,Config.Speed.BindIsKB).." · "..bm2
        blSpeed.Mode.TextColor3=spdOn and ModeColors[bm2] or T.dim
        if spdOn then blSpeedSub.Visible=true;blSpeedSub.Text="   → x"..string.format("%.2f",Config.Speed.Value);blSpeedSub.TextColor3=T.green
        else blSpeedSub.Visible=false end
    else blSpeedSub.Visible=false end
end)

-- CFrame Speed (Heartbeat)
RS.Heartbeat:Connect(function()
    if isSpeedActive() then local ch=LP.Character
        if ch then local hrp=ch:FindFirstChild("HumanoidRootPart");local hum=ch:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health>0 then local dir=hum.MoveDirection
                if dir.Magnitude>0 then hrp.CFrame=hrp.CFrame+dir*Config.Speed.Value end end end
    end
end)
--// === ANTI-BLUR PATCH === //--
-- Fix 1: Snap UIScale to exactly 1 every frame when menu is open
RS.RenderStepped:Connect(function()
    if State.MenuOpen and not State.MenuTweening then
        if MainScale.Scale ~= 1 then
            MainScale.Scale = 1
        end
    end
end)

-- Fix 2: Force pixel-perfect rendering
Gui.IgnoreGuiInset = true

-- Fix 3: Remove CanvasGroup blur by reparenting
if MenuContainer:IsA("CanvasGroup") then
    local newContainer = Instance.new("Frame")
    newContainer.Size = UDim2.new(1,0,1,0)
    newContainer.BackgroundTransparency = 1
    newContainer.Parent = Gui
    
    for _, child in ipairs(MenuContainer:GetChildren()) do
        child.Parent = newContainer
    end
    
    MenuContainer:Destroy()
    MenuContainer = newContainer
    Main.Parent = MenuContainer
end

print("[MARKTAPE] Anti-blur patch applied")

print("[MARKTAPE] Da Strike v8.0 — Precise Speed + Clean Camera")
