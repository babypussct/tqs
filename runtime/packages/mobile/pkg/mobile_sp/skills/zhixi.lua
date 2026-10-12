local zhixi = fk.CreateSkill{
  name = "mobile__zhixi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__zhixi"] = "止息",
  [":mobile__zhixi"] = "锁定技，出牌阶段，你至多使用X张牌（X为你的体力值）。你使用锦囊牌后，结束出牌阶段。",

  ["@[mobile__zhixi]"] = "止息",
  ["mobile__zhixi_remains"] = "剩余",
  ["mobile__zhixi_prohibit"] = "不能出牌",
}

Fk:addQmlMark{
  name = "mobile__zhixi",
  qml_path = "",
  how_to_show = function(name, value, p)
    if p.phase == Player.Play then
      local x = p.hp - p:usedSkillTimes(zhixi.name, Player.HistoryPhase)
      if x < 1 then
        return Fk:translate("mobile__zhixi_prohibit")
      else
        return Fk:translate("mobile__zhixi_remains") .. tostring(x)
      end
    end
    return "#hidden"
  end,
}
zhixi:addEffect(fk.CardUseFinished, {
  anim_type = "negative",
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(zhixi.name) and player.phase == Player.Play
  end,
  on_use = function (self, event, target, player, data)
    if data.card.type == Card.TypeTrick then
      player:endPlayPhase()
    end
  end,
})
zhixi:addEffect("prohibit", {
  prohibit_use = function(self, player)
    return player:hasSkill(zhixi.name) and player.phase == Player.Play and
      player:usedSkillTimes(zhixi.name, Player.HistoryPhase) >= player.hp
  end,
})

zhixi:addAcquireEffect(function (self, player, is_start)
  player.room:setPlayerMark(player, "@[mobile__zhixi]", 1)
end)

zhixi:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@[mobile__zhixi]", 0)
end)

return zhixi
