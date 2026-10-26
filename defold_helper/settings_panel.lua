-- Stack Rush settings presentation with injected product services.
local factory = {}

function factory.new(options)
  options = options or {}
  local localization = assert(options.localization, "A localization catalog is required")
  local settings_store = assert(options.settings_store, "A settings store is required")
  local localized_text = assert(options.localized_text, "A localized text renderer is required")
  local audio = options.audio or {play=function() end, stop=function() end}
  local on_action = options.on_action or function() end
  local open_url = options.open_url or function(url)
    local api = rawget(_G, "sys")
    if url and api and api.open_url then api.open_url(url) end
  end
  local enable_privacy = options.enable_privacy ~= false
  local M = {}
  local INK = {0.96, 0.95, 0.91, 1}

  function M.create(locale, settings)
    local panel = { locale = locale, settings = settings or settings_store.load(), nodes = {},
      buttons = {}, entry_nodes = {}, state = { ads_held = true }, visible = false }
    local function box(id, x, y, width, height, color)
      local node = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(width, height, 0))
      gui.set_id(node, (options.node_prefix or "privacy_center_") .. id)
      gui.set_color(node, vmath.vector4(color[1], color[2], color[3], color[4]))
      panel.nodes[#panel.nodes + 1] = node
      return node
    end
    local function text(id, x, y, scale)
      local node = gui.new_text_node(vmath.vector3(x, y, 0), "")
      gui.set_id(node, (options.node_prefix or "privacy_center_") .. id)
      gui.set_font(node, "hud_font")
      gui.set_color(node, vmath.vector4(INK[1], INK[2], INK[3], INK[4]))
      gui.set_scale(node, vmath.vector3(scale, scale, 1))
      panel.nodes[#panel.nodes + 1] = node
      return node
    end
    local function button(id, y)
      panel.buttons[id] = {
        hit = box(id, 360, y, 540, 82, {0.12, 0.19, 0.24, 1}),
        label = text(id .. "_label", 360, y, 0.58),
      }
    end
    panel.entry = box("entry", 606, 70, 172, 72, {0.08, 0.13, 0.17, 0.94})
    panel.entry_label = text("entry_label", 627, 70, 0.53)
    -- A compact sliders icon uses the same flat geometry as the game.
    for index = 1, 3 do
      local y = 86 - (index - 1) * 16
      box("entry_line_" .. index, 553, y, 26, 3, INK)
      box("entry_knob_" .. index, index == 2 and 548 or 559, y, 5, 9, INK)
    end
    for _, node in ipairs(panel.nodes) do
      panel.entry_nodes[node] = true
      gui.set_yanchor(node, gui.ANCHOR_BOTTOM)
    end
    box("scrim", 360, 640, 2880, 5120, {0.01, 0.02, 0.03, 0.82})
    box("panel", 360, 640, 620, 780, {0.055, 0.09, 0.12, 1})
    box("accent", 360, 1028, 620, 4, {0.27, 0.82, 0.70, 1})
    panel.title = text("title", 360, 956, 0.80)
    panel.body = text("body", 360, 810, 0.50)
    if gui.set_size then gui.set_size(panel.body, vmath.vector3(1040, 420, 0)) end
    if gui.set_line_break then gui.set_line_break(panel.body, true) end
    panel.error = text("error", 360, 304, 0.44)
    button("sound", 842)
    button("language", 736)
    button("primary", 610)
    button("policy", 504)
    button("close", 382)
    for index = 1, 5 do button("locale_" .. index, 860 - (index - 1) * 90) end
    button("previous", 382)
    button("next", 382)
    panel.page_label = text("page_label", 360, 304, 0.44)
    panel.language_page = 1
    M.render(panel)
    return panel
  end

  function M.render(panel)
    localized_text.set_locale(panel.locale)
    local strings, state = localization.copy(panel.locale), panel.state
    for _, node in ipairs(panel.nodes) do gui.set_enabled(node, panel.entry_nodes[node] or panel.visible) end
    localized_text.set(panel.entry_label, strings.settings, function(node) localized_text.fit(node, 116, 0.53, 0.36) end)
    if not panel.visible then return end
    local root = panel.mode == "settings"
    local title, body = strings.settings, ""
    local primary, policy, close = strings.privacy_ad_settings, strings.privacy_policy, strings.back
    local primary_enabled, policy_enabled = enable_privacy, enable_privacy
    if root then
      close = strings.close
    elseif panel.mode == "languages" then
      title, close = strings.language, strings.back
    elseif panel.mode == "ad_settings" then
      title = strings.privacy_ad_settings
      body = state.ads_held and strings.ads_settings_unavailable
        or state.ads_enabled and strings.ads_settings_enabled or strings.ads_settings_disabled
      primary = state.ads_enabled and strings.privacy_stop_ads or strings.ads_notice_accept
      primary_enabled = state.ads_enabled == true or state.ads_held ~= true
      policy, policy_enabled = strings.privacy_provider_choices, state.cmp_available == true
    elseif panel.mode == "ads_notice" then
      title, body = strings.ads_notice_title, strings.ads_notice_body
      primary, close = strings.ads_notice_accept, strings.cancel
      primary_enabled = state.ads_held ~= true
    end
    if state.choice_storage_failed and not root and panel.mode ~= "languages" then body = strings.privacy_save_failed end
    localized_text.set(panel.title, title, function(node) localized_text.fit(node, 550, 0.80, 0.52) end)
    localized_text.set(panel.body, body)
    localized_text.set(panel.error, panel.save_failed and strings.settings_save_failed or "",
      function(node) localized_text.fit(node, 550, 0.44, 0.34) end)
    gui.set_enabled(panel.page_label, panel.mode == "languages" and not panel.save_failed)
    if panel.mode == "languages" then
      localized_text.set(panel.page_label, tostring(panel.language_page) .. " / " .. math.ceil(#localization.locales() / 5))
    end
    local labels = {
      sound = strings.sound .. "   " .. (panel.settings.sound_enabled and strings.sound_on or strings.sound_off),
      language = strings.language .. "   " .. strings.language_name,
      primary = primary, policy = policy, close = close,
    }
    local positions = root and (enable_privacy
      and {sound=842,language=736,primary=610,policy=504,close=382}
      or {sound=790,language=670,close=480}) or {primary=650,policy=540,close=430}
    for id, button in pairs(panel.buttons) do
      local selector = panel.mode == "languages"
      local row = tonumber(id:match("^locale_(%d+)$"))
      local entry = row and localization.locales()[(panel.language_page - 1) * 5 + row]
      local enabled = (id == "sound" or id == "language") and root
        or id == "primary" and not selector and primary_enabled
        or id == "policy" and not selector and policy_enabled
        or id == "close"
        or row and selector and entry ~= nil
        or id == "previous" and selector and panel.language_page > 1
        or id == "next" and selector and panel.language_page < math.ceil(#localization.locales() / 5)
      gui.set_enabled(button.hit, enabled)
      gui.set_enabled(button.label, enabled)
      local text_value = entry and entry.name or id == "previous" and "<" or id == "next" and ">" or labels[id] or ""
      localized_text.set(button.label, text_value, function(node) localized_text.fit(node, row and 490 or selector and 280 or 500, 0.58, 0.36) end,
        entry and entry.id or panel.locale)
      local x = selector and id == "previous" and 130 or selector and id == "next" and 590 or 360
      local y = row and 860 - (row - 1) * 90 or selector and 382 or positions[id] or 382
      gui.set_position(button.hit, vmath.vector3(x, y, 0))
      gui.set_position(button.label, vmath.vector3(x, y, 0))
      if gui.set_size then
        gui.set_size(button.hit, vmath.vector3(selector and (id == "previous" or id == "next") and 100
          or selector and id == "close" and 300 or 540, 82, 0))
      end
      gui.set_color(button.hit, entry and entry.id == panel.locale
        and vmath.vector4(0.10, 0.32, 0.29, 1) or vmath.vector4(0.12, 0.19, 0.24, 1))
    end
    gui.set_color(panel.buttons.sound.hit, panel.settings.sound_enabled
      and vmath.vector4(0.10, 0.32, 0.29, 1) or vmath.vector4(0.16, 0.19, 0.22, 1))
  end

  function M.open(panel, mode)
    if not enable_privacy and mode ~= "languages" then mode = "settings" end
    panel.visible, panel.mode, panel.pressed, panel.save_failed = true, mode or "settings", nil, false
    for _, node in ipairs(panel.nodes) do gui.move_above(node, nil) end
    M.render(panel)
  end

  local function change_option(panel, id, locale)
    local next_settings = { sound_enabled = panel.settings.sound_enabled, locale = panel.settings.locale }
    if id == "sound" then next_settings.sound_enabled = not next_settings.sound_enabled
    else next_settings.locale = locale end
    panel.save_failed = not settings_store.save(next_settings)
    if panel.save_failed then return end
    panel.settings.sound_enabled, panel.settings.locale = next_settings.sound_enabled, next_settings.locale
    panel.locale = next_settings.locale or panel.locale
    if not panel.settings.sound_enabled then audio.stop() end
    return true
  end

  function M.handle_input(panel, phase, x, y)
    if phase ~= "pressed" and phase ~= "released" then return panel.visible == true end
    local pressed = phase == "pressed"
    if not panel.visible then
      if pressed then panel.entry_pressed = gui.pick_node(panel.entry, x, y) end
      if panel.entry_pressed then
        if not pressed then
          panel.entry_pressed = false
          if gui.pick_node(panel.entry, x, y) then M.open(panel); audio.play(panel.settings, "click") end
        end
        return true
      end
      return false
    end
    if pressed then
      panel.pressed = nil
      for id, button in pairs(panel.buttons) do
        if gui.is_enabled(button.hit) and gui.pick_node(button.hit, x, y) then panel.pressed = id end
      end
      return true
    end
    local id = panel.pressed
    panel.pressed = nil
    if not id or not gui.pick_node(panel.buttons[id].hit, x, y) then return true end
    panel.save_failed = false
    if id == "sound" then
      change_option(panel, id)
    elseif id == "language" then
      panel.mode = "languages"
      for index, entry in ipairs(localization.locales()) do
        if entry.id == panel.locale then panel.language_page = math.ceil(index / 5) end
      end
    elseif id == "previous" then
      panel.language_page = math.max(1, panel.language_page - 1)
    elseif id == "next" then
      panel.language_page = math.min(math.ceil(#localization.locales() / 5), panel.language_page + 1)
    elseif id:match("^locale_") then
      local row = tonumber(id:match("(%d+)$"))
      local entry = localization.locales()[(panel.language_page - 1) * 5 + row]
      if entry and change_option(panel, "language", entry.id) then panel.mode = "settings" end
    elseif id == "policy" then
      if panel.mode == "ad_settings" then on_action("privacy_options_requested")
      else open_url(localization.policy_url(panel.locale)) end
    elseif id == "close" then
      if panel.mode == "settings" or panel.mode == "ads_notice" and panel.resume_reward then
        panel.resume_reward, panel.visible = false, false
      elseif panel.mode == "ads_notice" then panel.mode = "ad_settings"
      else panel.mode = "settings" end
    elseif id == "primary" then
      if panel.mode == "settings" then panel.mode = "ad_settings"
      elseif panel.mode == "ads_notice" then
        on_action("advertising_choice_selected", { enabled = true })
        if panel.resume_reward then
          on_action("watch_rewarded_ad_requested")
          panel.visible = false
        else panel.mode = "ad_settings" end
        panel.resume_reward = false
      elseif panel.mode == "ad_settings" then
        if panel.state.ads_enabled then
          on_action("advertising_choice_selected", { enabled = false })
        else
          panel.resume_reward, panel.mode = false, "ads_notice"
        end
      end
    end
    audio.play(panel.settings, "click")
    M.render(panel)
    return true
  end

  function M.on_message(panel, state)
    panel.state = state or {}
    M.render(panel)
  end

  return M
end

return factory
