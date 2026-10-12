local zhouxuan = fk.CreateSkill {
  name = "mobile__zhouxuanz",
}

Fk:loadTranslationTable{
  ["mobile__zhouxuanz"] = "周旋",
  [":mobile__zhouxuanz"] = "出牌阶段限一次，你可以选择一名其他角色并选择一种非基本牌的类型或一种基本牌的牌名。若该角色之后"..
  "使用或打出的第一张牌与你的选择相同，你观看牌堆顶的三张牌，并分配给任意角色。",

  ["#mobile__zhouxuanz"] = "周旋：猜测一名角色使用或打出下一张牌的牌名/类别",
  ["#mobile__zhouxuanz-give"] = "周旋：你可以将这些牌任意分配，点“取消”自己保留",

  ["$mobile__zhouxuanz1"] = "孰为虎？孰为鹰？于吾都如棋子。",
  ["$mobile__zhouxuanz2"] = "群雄逐鹿之际，唯有洞明时势方有所成。",
}

zhouxuan:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#mobile__zhouxuanz",
  interaction = function()
    local names = { "trick", "equip" }
    table.insertTable(names, Fk:getAllCardNames("b", true))
    return UI.ComboBox { choices = names }
  end,
  can_use = function (self, player)
    return player:usedSkillTimes(zhouxuan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function (self, room, effect)
    room:addTableMark(effect.from, zhouxuan.name, { effect.tos[1].id, self.interaction.data })
  end,
})

local spec = {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return table.find(player:getTableMark(zhouxuan.name), function(m) return m[1] == target.id end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark(zhouxuan.name)
    local can_invoke
    for i = #mark, 1, -1 do
      if mark[i][1] == target.id then
        if mark[i][2] == data.card.trueName or mark[i][2] == data.card:getTypeString() then
          can_invoke = true
        end
        table.remove(mark, i)
      end
    end
    room:setPlayerMark(player, zhouxuan.name, mark)
    if can_invoke then
      local cards = room:getNCards(3)
      room:askToYiji(player, {
        cards = cards,
        min_num = 3,
        max_num = 3,
        skill_name = zhouxuan.name,
        expand_pile = cards,
      })
    end
  end,
}

zhouxuan:addEffect(fk.CardUsing, spec)
zhouxuan:addEffect(fk.CardResponding, spec)

return zhouxuan
