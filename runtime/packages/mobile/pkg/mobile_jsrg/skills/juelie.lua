local juelie = fk.CreateSkill {
  name = "m_js__juelie",
}

Fk:loadTranslationTable{
  ["m_js__juelie"] = "绝烈",
  [":m_js__juelie"] = "当你使用【杀】对目标角色造成伤害时，若你的手牌数或体力值为全场最小，此伤害+1。"..
  "当你使用【杀】指定一名角色为目标后，你可以弃置一张牌，然后弃置其一张牌。",

  ["#m_js__juelie-discard"] = "绝烈：你可以弃置一张牌，然后弃置 %dest 一张牌",

  ["$m_js__juelie1"] = "逐贼至此，必诛之方后快！",
  ["$m_js__juelie2"] = "传令所部兵马，定绝董贼后路！",
  ["$m_js__juelie3"] = "洛阳已在眼下，莫让董贼轻逃！",
  ["$m_js__juelie4"] = "火势刻不容缓，全军速速进发！"
}

juelie:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juelie.name) and
      data.card and data.card.trueName == "slash" and player.room.logic:damageByCardEffect() and
      (table.every(player.room.alive_players, function(p)
        return p:getHandcardNum() >= player:getHandcardNum()
      end) or
      table.every(player.room.alive_players, function(p)
        return p.hp >= player.hp
      end))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

juelie:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  audio_index = { 3, 4 },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juelie.name) and
      data.card.trueName == "slash" and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = juelie.name,
      cancelable = true,
      prompt = "#m_js__juelie-discard::" .. data.to.id,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, { tos = {data.to}, cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(event:getCostData(self).cards) or {}
    room:throwCard(cards, juelie.name, player, player)
    if not (player.dead or data.to.dead or data.to:isNude()) then
      cards = room:askToChooseCard(player, {
        target = data.to,
        flag = "he",
        skill_name = juelie.name,
      })
      room:throwCard(cards, juelie.name, data.to, player)
    end
  end,
})

return juelie
