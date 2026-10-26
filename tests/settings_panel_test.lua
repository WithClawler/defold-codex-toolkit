local check = require("tests.assert")

return function()
  local saved = {gui=_G.gui,vmath=_G.vmath,font=_G.font}
  _G.vmath = {vector3=function(x,y,z) return {x=x,y=y,z=z} end, vector4=function(x,y,z,w) return {x=x,y=y,z=z,w=w} end}
  _G.gui = {
    ANCHOR_BOTTOM="bottom",
    new_box_node=function(position,size) return {position=position,size=size,enabled=true} end,
    new_text_node=function(position,text) return {position=position,text=text,enabled=true} end,
    set_id=function(node,id) node.id=id end,
    set_color=function(node,color) node.color=color end,
    set_scale=function(node,scale) node.scale=scale end,
    set_font=function(node,font) node.font=font end,
    set_text=function(node,text) node.text=text end,
    set_yanchor=function(node,anchor) node.anchor=anchor end,
    set_size=function(node,size) node.size=size end,
    set_position=function(node,position) node.position=position end,
    set_enabled=function(node,enabled) node.enabled=enabled end,
    is_enabled=function(node) return node.enabled end,
    set_line_break=function() end,move_above=function() end,
    pick_node=function(node,x,y)
      return node.enabled and math.abs(x-node.position.x)<=node.size.x/2 and math.abs(y-node.position.y)<=node.size.y/2
    end,
  }
  _G.font = nil
  local data = {locales={},copy={},fonts={latin={name="hud_font",resource="/hud.fontc",fallbacks={}}}}
  for _, id in ipairs({"en-US","ko-KR","ja-JP","zh-CN","zh-TW","nb-NO","id-ID"}) do
    data.locales[#data.locales+1]={id=id,name=id,font="latin"}
    data.copy[id]={settings="Settings",sound="Sound",sound_on="ON",sound_off="OFF",language="Language",language_name=id,
      back="Back",close="Close",settings_save_failed="Save failed",privacy_ad_settings="Ad settings",privacy_policy="Policy"}
  end
  local localization = require("defold_helper.localization_catalog").new(data)
  local text = require("defold_helper.localized_text").new(localization)
  local failure, stopped, actions = false, 0, {}
  local store = {load=function() return {sound_enabled=true} end,save=function() return not failure end}
  local api = require("defold_helper.settings_panel").new({
    localization=localization,localized_text=text,settings_store=store,enable_privacy=false,
    audio={play=function() end,stop=function() stopped=stopped+1 end},
    on_action=function(action) actions[#actions+1]=action end,
  })
  local panel = api.create("en-US")
  local function tap(node)
    local x,y=node.position.x,node.position.y
    check.equal(api.handle_input(panel,"pressed",x,y),true)
    check.equal(api.handle_input(panel,"released",x,y),true)
  end
  check.equal(api.handle_input(panel,"pressed",1,1),false)
  tap(panel.entry)
  check.equal(panel.visible,true)
  check.equal(panel.buttons.primary.hit.enabled,false,"an app without ads cannot expose ad actions")
  check.equal(panel.buttons.policy.hit.enabled,false,"an app without a policy cannot inherit a provider link")
  check.equal(api.handle_input(panel,"pressed",1,1),true,"modal captures outside presses")
  check.equal(api.handle_input(panel,"released",1,1),true,"modal captures outside releases")
  check.equal(api.handle_input(panel,"move",1,1),true,"modal captures movement without executing a release")
  failure=true
  tap(panel.buttons.sound.hit)
  check.equal(panel.settings.sound_enabled,true,"failed save keeps the live selection")
  check.equal(panel.error.text,"Save failed")
  failure=false
  tap(panel.buttons.sound.hit)
  check.equal(panel.settings.sound_enabled,false)
  check.equal(stopped,1,"turning sound off stops ongoing effects")
  tap(panel.buttons.language.hit)
  check.equal(panel.mode,"languages")
  tap(panel.buttons.next.hit)
  check.equal(panel.language_page,2)
  tap(panel.buttons.locale_1.hit)
  check.equal(panel.locale,"nb-NO")
  check.equal(panel.settings.sound_enabled,false,"changing language preserves sound selection")
  check.equal(panel.mode,"settings")
  api.open(panel,"ad_settings")
  check.equal(panel.mode,"settings","disabled product modes cannot be opened indirectly")
  tap(panel.buttons.close.hit)
  check.equal(panel.visible,false)
  check.equal(#actions,0,"an ad-free panel never dispatches provider commands")
  _G.gui,_G.vmath,_G.font=saved.gui,saved.vmath,saved.font
end
