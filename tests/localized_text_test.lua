local check = require("tests.assert")

return function()
  local saved = {font=_G.font,gui=_G.gui,hash=_G.hash,vmath=_G.vmath}
  local catalog = require("defold_helper.localization_catalog").new({
    locales={{id="en-US",name="English",font="latin"},{id="ko-KR",name="한국어",font="ko"}},
    copy={["en-US"]={title="Play"},["ko-KR"]={title="시작"}},
    fonts={latin={name="latin",resource="/latin.fontc",ttf="/latin.ttf"},
      ko={name="ko",resource="/ko.fontc",ttf="/ko.ttf",fallbacks={"latin"}}},
  })
  local queue, order = {}, {}
  _G.hash = function(value) return value end
  _G.vmath = {vector3=function(x,y,z) return {x=x,y=y,z=z} end}
  _G.gui = {
    set_text=function(node,text) node.text=text end,
    set_font=function(node,font) node.font=font end,
    set_scale=function(node,scale) node.scale=scale end,
  }
  _G.font = {
    add_font=function() order[#order+1]="fallback" end,
    prewarm_text=function(resource,value,callback)
      order[#order+1]="prewarm"
      queue[#queue+1]={resource=resource,text=value,callback=callback}
    end,
  }
  local text = require("defold_helper.localized_text").new(catalog)
  local node = {enabled=false,text="old"}
  text.set(node, "시작", nil, "ko-KR")
  text.set(node, "설정", nil, "ko-KR")
  check.equal(#queue, 1, "one font preparation serves concurrent labels")
  check.equal(order[1], "fallback", "fallback faces are connected before shaping")
  check.equal(node.text, "")
  text.set(node, "Play", nil, "en-US")
  queue[1].callback(nil,nil,true)
  check.equal(node.text, "", "a previous locale cannot replace the newest requested text")
  queue[2].callback(nil,nil,true)
  check.equal(node.text, "Play")
  check.equal(node.font, "latin")
  check.equal(node.enabled, false, "font preparation cannot reveal a hidden screen")
  local second = require("defold_helper.localized_text").new(catalog)
  second.prepare("ko-KR", function() end)
  check.equal(#queue, 3, "renderer factories own their font-ready state")
  check.equal(pcall(queue[3].callback,nil,nil,false,"cache exhausted"), false)
  second.prepare("ko-KR", function() end)
  check.equal(#queue, 4, "font preparation remains retryable after failure")
  queue[4].callback(nil,nil,true)
  _G.font,_G.gui,_G.hash,_G.vmath=saved.font,saved.gui,saved.hash,saved.vmath
end
