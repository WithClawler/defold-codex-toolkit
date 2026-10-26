local check = require("tests.assert")

return function()
  local saved={font=_G.font,gui=_G.gui,hash=_G.hash,vmath=_G.vmath}
  local queue, fallback_calls, inventory_calls, writes = {}, 0, 0, {}
  local catalog=require("defold_helper.localization_catalog").new({
    locales={{id="en-US",name="English",font="latin"},{id="ja-JP",name="日本語",font="jp"},{id="ko-KR",name="한국어",font="ko"}},
    copy={["en-US"]={title="Play"},["ja-JP"]={title="プレイ"},["ko-KR"]={title="시작"}},
    fonts={latin={name="latin",resource="/latin.fontc",ttf="/latin.ttf"},
      jp={name="jp",resource="/jp.fontc",runtime=false,fallbacks={"latin"}},
      ko={name="ko",resource="/ko.fontc",runtime=true,fallbacks={"latin"}}},
  })
  local original_inventory=catalog.font_text
  catalog.font_text=function(id) inventory_calls=inventory_calls+1; return original_inventory(id) end
  _G.hash=function(value) return value end
  _G.vmath={vector3=function(x,y,z) return {x=x,y=y,z=z} end}
  _G.gui={
    set_text=function(node,value) node.text=value; writes[#writes+1]=value end,
    set_font=function(node,value) node.font=value end,
    set_scale=function(node,value) node.scale=value end,
  }
  _G.font={
    add_font=function() fallback_calls=fallback_calls+1 end,
    prewarm_text=function(resource,value,callback) queue[#queue+1]={resource=resource,text=value,callback=callback} end,
  }
  local text=require("defold_helper.localized_text").new(catalog)
  local node, applied={text="old",enabled=false},0
  text.set(node,"プレイ",function(current)
    applied=applied+1
    check.equal(current.text,"プレイ")
    check.equal(current.font,"jp")
  end,"ja-JP")
  check.equal(applied,1,"explicit static fonts display synchronously despite a runtime font API")
  check.equal(#queue,0,"static glyph banks cannot enter runtime prewarming")
  check.equal(inventory_calls,0,"static preparation does not request runtime glyph inventory")
  check.equal(fallback_calls,0,"static fonts never attach runtime fallback resources")
  check.equal(#writes,1,"static text is not cleared while waiting for an unnecessary runtime job")
  check.equal(node.enabled,false)
  text.prepare("ja-JP",function() applied=applied+1 end)
  check.equal(applied,2,"the public preparation API preserves immediate static readiness")

  local stale=0
  text.set(node,"Play",function() stale=stale+1 end,"en-US")
  check.equal(#queue,1,"a font without runtime metadata keeps the existing dynamic behavior")
  check.equal(node.text,"")
  text.set(node,"プレイ",nil,"ja-JP")
  queue[1].callback(nil,nil,true)
  check.equal(stale,0,"a pending dynamic callback cannot replace a newer static locale")
  check.equal(node.text,"プレイ")
  check.equal(node.font,"jp")
  text.set(node,"시작",nil,"ko-KR")
  check.equal(#queue,2,"explicit runtime=true retains asynchronous preparation")
  check.equal(fallback_calls,1)
  queue[2].callback(nil,nil,true)
  check.equal(node.text,"시작")
  check.equal(node.font,"ko")
  _G.font,_G.gui,_G.hash,_G.vmath=saved.font,saved.gui,saved.hash,saved.vmath
end
