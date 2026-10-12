local bladeSkill = fk.CreateSkill{
  name = "#sa__blade_skill",
  attached_equip = "sa__blade",
  tags = { Skill.Compulsory },
}
bladeSkill:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bladeSkill.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastPlaySound("./packages/standard_cards/audio/card/blade")
    room:setEmotion(player, "./packages/standard_cards/image/anim/blade")
    for _, p in ipairs(data.tos) do
      room:addPlayerMark(p, "@@sa__blade")
      local record = p:getTableMark(MarkEnum.RevealProhibited)
      table.insertTable(record, {"m", "d"})
      room:setPlayerMark(p, MarkEnum.RevealProhibited, record)
      data.extra_data = data.extra_data or {}
      data.extra_data.sa__bladeRevealProhibited = data.extra_data.sa__bladeRevealProhibited or {}
      data.extra_data.sa__bladeRevealProhibited[tostring(p.id)] = (data.extra_data.sa__bladeRevealProhibited[tostring(p.id)] or 0) + 1
    end
  end,
})
bladeSkill:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.sa__bladeRevealProhibited
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.sa__bladeRevealProhibited) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark("@@sa__blade") > 0 then
        room:removePlayerMark(p, "@@sa__blade", num)
        local record = p:getTableMark(MarkEnum.RevealProhibited)
        table.removeOne(record, "m")
        table.removeOne(record, "d")
        room:setPlayerMark(p, MarkEnum.RevealProhibited, #record == 0 and 0 or record)
      end
    end
    data.sa__bladeRevealProhibited = nil
  end,
})

bladeSkill:addTest(function(room, me)
  local card = room:printCard("sa__blade")
  local comp2 = room.players[2]

  FkTest.runInRoom(function()
    room:useCard {
      from = me,
      tos = { me },
      card = card,
    }
    FkTest.setNextReplies(comp2, { "__cancel" })
    room:useCard {
      from = me,
      tos = { comp2 },
      card = Fk:cloneCard("slash"),
    }
  end)
  lu.assertEquals(comp2:getMark(MarkEnum.RevealProhibited), 0) -- 没卵用
end)

Fk:loadTranslationTable{
  ["sa__blade"] = "青龙偃月刀",
  [":sa__blade"] = "装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：锁定技，当你使用【杀】时，此牌的使用结算结束之前，此【杀】的目标角色不能明置武将牌。",

  ["@@sa__blade"] = "青龙偃月刀",
}

return bladeSkill
