local addon, ns = ...

--[[
    Pixel Perfect Utilities

    Provides frame snapping to physical pixel boundaries to prevent blurry
    rendering caused by sub-pixel positioning.

    Derived from MoLib by MooreaTv (https://github.com/mooreatv/MoLib)
    Original code licensed under LGPLv3
]]

local PixelPerfect = {}
ns.PixelPerfect = PixelPerfect

-- Cache frequently used functions
local math_floor = math.floor
local math_ceil = math.ceil

-- Round to nearest pixel boundary
-- precision: 1 = whole pixel, 2 = even pixels, 0.5 = half pixels
function PixelPerfect.Round(x, precision)
    precision = precision or 1
    if precision < 1 then
        local p = math_floor(1 / precision + 0.5)
        return math_floor(x * p + 0.5) / p
    end
    return math_floor(x / precision + 0.5) * precision
end

-- Round up for dimensions (never shrink a frame)
function PixelPerfect.RoundUp(x, precision)
    precision = precision or 1
    local sign = 1
    if x < 0 then
        sign = -1
        x = -x
    end
    return sign * math_ceil(x / precision - 0.1) * precision
end

-- Singleton pixel-perfect frame (1 coordinate unit = 1 physical pixel)
local ppf

local function onPixelPerfectEvent(self)
    local w, h = GetPhysicalScreenSize()
    local parent = self:GetParent()
    self:SetSize(w, h)
    local sx = parent:GetWidth() / w
    self:SetScale(sx)
end

function PixelPerfect.GetFrame()
    if ppf then return ppf end

    ppf = CreateFrame("Frame", "DessertUIPixelPerfectFrame", UIParent)
    ppf:SetPoint("BOTTOMLEFT", 0, 0)
    onPixelPerfectEvent(ppf)
    ppf:Show()
    ppf:SetScript("OnEvent", onPixelPerfectEvent)
    ppf:RegisterEvent("DISPLAY_SIZE_CHANGED")
    ppf:RegisterEvent("UI_SCALE_CHANGED")

    return ppf
end

-- Snap a frame's position and size to physical pixel boundaries
-- resolution: 1 = pixel (default), 2 = even pixels, 0.5 = half pixels
-- from_top: true to anchor from TOPLEFT, false/nil for BOTTOMLEFT
function PixelPerfect.Snap(frame, resolution, from_top)
    resolution = resolution or 1

    local fs = frame:GetEffectiveScale()
    local ps = PixelPerfect.GetFrame():GetEffectiveScale()
    local ratio = fs / ps
    local mult = ps / fs

    -- Convert frame rect to pixel-perfect coordinates
    local x, y, w, h = frame:GetRect()
    local ppx = x * ratio
    local ppy = y * ratio
    local ppw = w * ratio
    local pph = h * ratio

    local point = "BOTTOMLEFT"
    if from_top then
        ppy = ppy + pph
        point = "TOPLEFT"
    end

    -- Round position to nearest pixel, round dimensions up
    ppx = PixelPerfect.Round(ppx, resolution)
    ppy = PixelPerfect.Round(ppy, resolution)
    ppw = PixelPerfect.RoundUp(ppw, resolution)
    pph = PixelPerfect.RoundUp(pph, resolution)

    -- Apply snapped values back in frame's coordinate space
    frame:ClearAllPoints()
    frame:SetPoint(point, nil, "BOTTOMLEFT", ppx * mult, ppy * mult)
    frame:SetSize(ppw * mult, pph * mult)
end
