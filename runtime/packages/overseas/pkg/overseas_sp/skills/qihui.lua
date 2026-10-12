local qihui = fk.CreateSkill {
  name = "os__qihui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__qihui"] = "启诲",
  [":os__qihui"] = "锁定技，当你使用牌时，你获得1枚此牌类别的“启诲”（每个类别标记数量上限为1），" ..
    "然后若你有3枚“启诲”，你弃2或3枚“启诲”并选择一项：1.回复1点体力；2.摸两张牌；" ..
    "3.使用的下一张牌不计入次数且无次数限制；4.令一名其他角色摸三张牌。若你弃3枚“启诲”，每个类别标记数量上限+1。",

  ["@os__qihui"] = "启诲",
  ["#os__qihui-remove"] = "启诲：移除2或3枚“启诲”，若弃3枚则数量上限+1",
  ["os__qihui_use"] = "使用下一张牌无次数限制",
  ["os__qihui_other_draw"] = "令一名其他角色摸三张牌",
  ["#os__qihui_other_draw"] = "启诲：选择一名其他角色，其摸三张牌",
  ["@os__qihui_max"] = "启诲上限",

  ["$os__qihui1"] = "君无民臣，何以名君？故知民之重也。",
  ["$os__qihui2"] = "民惟邦本，本固邦宁，奈何知而不行？",
  ["$os__qihui3"] = "君人者欲安，莫若以民为本，平政爱之。",
}

local char2type = {
  ["基"] = "basic_char",
  ["锦"] = "trick_char",
  ["装"] = "equip_char",
}

qihui:addEffect(fk.CardUsing, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(qihui.name)) then return false end
    local record = data.card:getTypeString().."_char"
    local n = math.max(1, player:getMark("@os__qihui_max"))
    for _, r in ipairs(player:getTableMark("@os__qihui")) do
      if r == record then n = n - 1 end
      if n <= 0 then return false end
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "@os__qihui", data.card:getTypeString().."_char")
    local record = player:getMark("@os__qihui")
    if #record ~= 3 then return end
    local record_suffix = {} -- ChoiceBox直接用string判断，同名需要后缀
    local suffix_count = {}
    for _, value in ipairs(record) do
      suffix_count[value] = (suffix_count[value] or 0) + 1
      if suffix_count[value] == 1 then
        table.insert(record_suffix, Fk:translate(value))
      else
        table.insert(record_suffix, Fk:translate(value) .. ":::" .. tostring(suffix_count[value]))
      end
    end
    local choices = room:askToChoices(player, {
      choices = record_suffix,
      min_num = 2,
      max_num = 3,
      skill_name = qihui.name,
      prompt = "#os__qihui-remove",
      cancelable = false,
    })
    local remove_three = #choices == 3
    if remove_three then
      room:setPlayerMark(player, "@os__qihui", 0)
    else
      for _, choice in ipairs(choices) do
        local real_choice = choice[1] -- 翻译过的‘基’等
        table.removeOne(record, char2type[real_choice])
      end
      room:setPlayerMark(player, "@os__qihui", record)
    end

    local all_choices = {"recover", "draw2", "os__qihui_use", "os__qihui_other_draw"}
    choices = table.simpleClone(all_choices)
    if not player:isWounded() then
      table.remove(choices, 1)
    end
    if #room:getOtherPlayers(player, false) == 0 then
      table.remove(choices)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = qihui.name,
    })
    if choice == "recover" then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = qihui.name,
      }
    elseif choice == "draw2" then
      player:drawCards(2, qihui.name)
    elseif choice == "os__qihui_use" then
      room:setPlayerMark(player, "os__qihui_use", 1)
    else -- if choice == "os__qihui_other_draw" then
      local to = room:askToChoosePlayers(player, {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        skill_name = qihui.name,
        prompt = "#os__qihui_other_draw",
      })[1]
      to:drawCards(3, qihui.name)
    end

    if remove_three then
      record = math.max(1, player:getMark("@os__qihui_max")) + 1
      room:setPlayerMark(player, "@os__qihui_max", record)
    end
  end,
})
qihui:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("os__qihui_use") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "os__qihui_use", 0)
    data.extraUse = true
  end,
})
qihui:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card)
    return card and player:getMark("os__qihui_use") > 0
  end,
})

qihui:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "@os__qihui", 0)
  room:setPlayerMark(player, "@os__qihui_max", 0)
end)

return qihui
