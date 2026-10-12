local lihuo = fk.CreateSkill {
  name = "m_ex__lihuo",
}

Fk:loadTranslationTable{
  ["m_ex__lihuo"] = "疬火",
  [":m_ex__lihuo"] = "当你使用普通【杀】时，你可以将此【杀】改为火【杀】。若此【杀】的目标角色处于连环状态，则此【杀】造成的伤害+1。"..
  "你使用火【杀】结算结束后，每造成过2点伤害，你失去1点体力。",

  ["#m_ex__lihuo-invoke"] = "疬火：是否将%arg改为火【杀】？",

  ["$m_ex__lihuo1"] = "此火只为全歼敌寇，无需妇人之仁。",
  ["$m_ex__lihuo2"] = "战胜攻取，以火修功。"
}

lihuo:addEffect(fk.AfterCardUseDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lihuo.name) and data.card.name == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = lihuo.name,
      prompt = "#m_ex__lihuo-invoke:::"..data.card:toLogString()
    })
  end,
  on_use = function(self, event, target, player, data)
    data:changeCard("fire__slash", data.card.suit, data.card.number, lihuo.name)
    if table.find(data.tos, function (p)
      return p.chained
    end) then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
})

lihuo:addEffect(fk.CardUseFinished, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(lihuo.name) and
      data.card.name == "fire__slash" and data.damageDealt and player.hp > 0 then
      local n = 0
      for _, v in pairs(data.damageDealt) do
        n = n + v
      end
      if n > 2 then
        event:setCostData(self, {choice = n // 2})
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, event:getCostData(self).choice, lihuo.name)
  end,
})

return lihuo
