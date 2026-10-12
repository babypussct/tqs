local qiangyong = fk.CreateSkill {
  name = "qiangyong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qiangyong"] = "羌勇",
  [":qiangyong"] = "锁定技，你使用【杀】造成伤害时，弃置受伤角色的X张牌（X为你本回合使用【杀】的次数），然后若其没有手牌，此【杀】伤害+1。",

  ["#qiangyong-discard"] = "羌勇：弃置 %dest %arg张牌",

  ["$qiangyong1"] = "诸葛小儿，可速献关纳降。",
  ["$qiangyong2"] = "未想西凉旧部，今为蜀犬耳。",
  ["$qiangyong3"] = "今日誓破西平关，以震羌胡之威！",
  ["$qiangyong4"] = "铁车军所向无敌，何惧蜀中孺子？",
}

qiangyong:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiangyong.name) and
      data.card and data.card.trueName == "slash" and
      player.room.logic:damageByCardEffect(false)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not data.to:isNude() then
      local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function (e)
        return e.data.card.trueName == "slash" and e.data.from == player
      end, Player.HistoryTurn)
      local cards = room:askToChooseCards(player, {
        target = data.to,
        min = n,
        max = n,
        flag = "he",
        skill_name = qiangyong.name,
        prompt = "#qiangyong-discard::"..data.to.id..":"..n
      })
      room:throwCard(cards, qiangyong.name, data.to, player)
    end
    if data.to:isKongcheng() then
      data:changeDamage(1)
    end
  end,
})

return qiangyong
