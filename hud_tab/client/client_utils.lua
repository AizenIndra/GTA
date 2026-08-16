scx, scy        = guiGetScreenSize()
cfX, cfY        = scx / 1920, scy / 1080
cfX             = cfX + math.abs( cfX - cfY )

sScrollValue    = 0
sScrollMaxValue = 0
scroll          = 0

-- Состояние перетаскивания скролла
scrollDrag = {
    active   = false,
    startY   = 0,
    startVal = 0,
    trackH   = 1,
}

function onClientPreRender_handler( delta )
    -- Если идёт перетаскивание — обновляем sScrollValue напрямую через мышь
    if scrollDrag.active then
        if not isCursorShowing() then
            scrollDrag.active = false
        else
            local cx, cy = getCursorPosition()
            if cx then
                cy = cy * scy
                local dy = cy - scrollDrag.startY
                local ratio = sScrollMaxValue / math.max(scrollDrag.trackH, 1)
                sScrollValue = Clamp(0, scrollDrag.startVal + dy * ratio, sScrollMaxValue)
            end
        end
    end
    scroll = scroll + ( sScrollValue - scroll ) * 8 * ( delta / 1200 )
end

function string:RemoveHex()
    local str = utf8.gsub( self, "#%x%x%x%x%x%x", "" )
    if utf8.len( str ) > 20 then
        str = utf8.sub( str, 1, 20 ) .. "..."
    end
    return str
end

function Clamp( min, a, max )
    return math.max( math.min( a, max ), min )
end

function ColorMulAlpha( color, alpha )
    if color == nil then return COLOR_WHITE end
    return alpha == 255 and color or alpha == 0 and 0 or bitReplace( color, bitExtract( color, 24, 8 ) * alpha / 255, 24, 8 )
end
