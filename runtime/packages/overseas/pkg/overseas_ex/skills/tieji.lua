local tieji = fk.CreateSkill {
  name = "os_ex__tieji",
}

Fk:loadTranslationTable {
  ["os_ex__tieji"] = "铁骑",
  [":os_ex__tieji"] = "当你使用【杀】指定目标后，你可以令其本回合内非锁定技失效，然后进行一次判定，其需交给你一张花色与判定结果花色相同的牌，" ..
      "否则其无法响应此【杀】且此【杀】伤害+1。",

  ["@@tieji-turn"] = "铁骑",
  ["#os_ex__tieji-invoke"] = "铁骑：是否对 %dest 发动“铁骑”，令其本回合非锁定技失效？",
  ["#os_ex__tieji-give"] = "铁骑：交给 %src 一张%arg牌，否则无法响应此【杀】且此【杀】伤害+1",

  ["$os_ex__tieji1"] = "你可闪得过此一击？！",
  ["$os_ex__tieji2"] = "（马鸣声）（马蹄声）",
}

tieji:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tieji.name) and
        data.card.trueName == "slash" and not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
          skill_name = tieji.name,
          prompt = "#os_ex__tieji-invoke::" .. data.to.id,
        }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.to
    room:addPlayerMark(to, "@@tieji-turn")
    room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity .. "-turn")
    local judge = {
      who = player,
      reason = tieji.name,
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    if not data.to.dead and judge.card and judge.card.suit ~= "nosuit" then
      local card = room:askToCards(to, {
        max_num = 1,
        min_num = 1,
        include_equip = true,
        skill_name = self.name,
        cancelable = true,
        pattern = ".|.|" .. judge.card:getSuitString(),
        prompt = "#os_ex__tieji-give:" .. player.id .. "::" .. judge.card:getSuitString(true),
      })
      if #card == 0 then
        data.disresponsive = true
        data.additionalDamage = (data.additionalDamage or 0) + 1
      else
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, tieji.name, nil, false, player)
      end
    end
  end,
})

return tieji
