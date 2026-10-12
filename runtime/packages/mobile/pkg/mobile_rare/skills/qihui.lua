local qihui = fk.CreateSkill {
  name = "qihui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qihui"] = "启诲",
  [":qihui"] = "锁定技，当你使用牌时，若你没有此牌对应类别的标记，你获得1个对应类别的“启诲”标记，然后若你拥有3个“启诲”标记，"..
  "你移除2个“启诲”标记并选择一项：1.回复1点体力；2.摸两张牌；3.你使用的下一张牌不计入次数且无次数限制。",

  ["@qihui"] = "启诲",
  ["#qihui-remove"] = "启诲：请移除两种“启诲”标记",
  ["qihui_use"] = "使用下一张牌无次数限制",

  ["$qihui1"] = "天乃高且远，安可事事自下。",
  ["$qihui2"] = "吾等当上体天心，下济黎民。",
  ["$qihui3"] = "若除贪官恶吏，天下自为之一清。",
}

qihui:addEffect(fk.CardUsing, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qihui.name) and
      not table.contains(player:getTableMark("@qihui"), data.card:getTypeString().."_char")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "@qihui", data.card:getTypeString().."_char")
    if #player:getTableMark("@qihui") == 3 then
      local choices = room:askToChoices(player, {
        choices = {"basic", "trick", "equip"},
        min_num = 2,
        max_num = 2,
        skill_name = qihui.name,
        prompt = "#qihui-remove",
        cancelable = false,
      })
      for _, choice in ipairs(choices) do
        room:removeTableMark(player, "@qihui", choice.."_char")
      end
      local all_choices = {"recover", "draw2", "qihui_use"}
      local choices = table.simpleClone(all_choices)
      if not player:isWounded() then
        table.remove(choices, 1)
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
      elseif choice == "qihui_use" then
        room:setPlayerMark(player, "qihui_use", 1)
      end
    end
  end,
})
qihui:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("qihui_use") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "qihui_use", 0)
    data.extraUse = true
  end,
})
qihui:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card)
    return card and player:getMark("qihui_use") > 0
  end,
})

return qihui
