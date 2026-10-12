local qiuyuan = fk.CreateSkill{
  name = "m_ex__qiuyuan",
}

Fk:loadTranslationTable{
  ["m_ex__qiuyuan"] = "求援",
  [":m_ex__qiuyuan"] = "当你成为【杀】的目标时，你可以令另一名其他角色交给你一张除【杀】以外的基本牌，否则也成为此【杀】的目标。",

  ["#m_ex__qiuyuan-choose"] = "求援：令另一名其他角色交给你一张不为【杀】的基本牌，否则其成为此【杀】额外目标",
  ["#m_ex__qiuyuan-give"] = "求援：你需交给 %dest 一张不为【杀】的基本牌，否则成为此【杀】额外目标",

  ["$m_ex__qiuyuan1"] = "这是最后的希望了。",
  ["$m_ex__qiuyuan2"] = "诛此国贼者，加官进爵！",
}

qiuyuan:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(qiuyuan.name) and data.card.trueName == "slash" then
      local tos = data:getAllTargets()
      return table.find(player.room.alive_players, function (p)
        return p ~= data.from and p ~= player and not table.contains(tos, p)
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = data:getAllTargets()
    local targets = table.filter(room.alive_players, function (p)
      return p ~= data.from and p ~= player and not table.contains(tos, p)
    end)
    targets = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#m_ex__qiuyuan-choose",
      skill_name = qiuyuan.name,
      cancelable = true,
    })
    if #targets > 0 then
      event:setCostData(self, {tos = targets})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local ids = table.filter(to:getCardIds("h"), function(id)
      local card = Fk:getCardById(id)
      return card.type == Card.TypeBasic and card.trueName ~= "slash"
    end)
    local cards = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = qiuyuan.name,
      cancelable = true,
      pattern = tostring(Exppattern{ id = ids }),
      prompt = "#m_ex__qiuyuan-give::"..player.id,
    })
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, qiuyuan.name, nil, true, to)
    else
      data:addTarget(to, nil, true)
    end
  end,
})

return qiuyuan
