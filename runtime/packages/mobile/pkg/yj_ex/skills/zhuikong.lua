local zhuikong = fk.CreateSkill {
  name = "m_ex__zhuikong",
}

Fk:loadTranslationTable{
  ["m_ex__zhuikong"] = "惴恐",
  [":m_ex__zhuikong"] = "每轮限一次，其他角色的准备阶段，若其体力值不小于你，你可与其拼点。若你赢，其本回合无法使用牌指定除其以外的角色为目标；若你没赢，你获得其拼点的牌，然后其视为对你使用一张【杀】。",

  ["#m_ex__zhuikong-invoke"] = "惴恐：你可以与 %dest 拼点，若赢则其本回合使用牌只能指定自己为目标",
  ["@@m_ex__zhuikong_prohibit-turn"] = "惴恐",

  ["$m_ex__zhuikong1"] = "万事必须小心为妙。",
  ["$m_ex__zhuikong2"] = "我虽妇人，亦当铲除曹贼。",
}

zhuikong:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and not target.dead and target.phase == Player.Start and player:hasSkill(zhuikong.name)
    and player:usedSkillTimes(zhuikong.name, Player.HistoryRound) < 1 and player.hp <= target.hp and player:canPindian(target)
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = zhuikong.name,
      prompt = "#m_ex__zhuikong-invoke::"..target.id
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pindian = player:pindian({target}, zhuikong.name)
    if pindian.results[target].winner == player then
      room:addPlayerMark(target, "@@m_ex__zhuikong_prohibit-turn")
    elseif not player.dead and not target.dead then
      room:useVirtualCard("slash", nil, target, player, zhuikong.name, true)
    end
  end,
})

zhuikong:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return from and from:getMark("@@m_ex__zhuikong_prohibit-turn") > 0 and from ~= to
  end,
})

zhuikong:addEffect(fk.PindianResultConfirmed, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.from == player and data.reason == zhuikong.name and data.winner and data.winner ~= player and
      data.toCard and player.room:getCardArea(data.toCard) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.toCard, true, fk.ReasonJustMove, player, zhuikong.name)
  end,
})

return zhuikong
