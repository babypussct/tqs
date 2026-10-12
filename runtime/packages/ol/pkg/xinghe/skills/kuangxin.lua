local kuangxin = fk.CreateSkill{
  name = "kuangxin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["kuangxin"] = "狂信",
  [":kuangxin"] = "锁定技，出牌阶段开始时，你失去任意点体力，摸等量的牌并展示已损失体力值+1张手牌。结束阶段，你调整体力值与上个准备阶段相同。",

  ["#kuangxin-choice"] = "狂信：失去任意点体力，摸等量的牌，展示已损失体力值+1张手牌",
  ["#kuangxin-show"] = "狂信：请展示%arg张手牌",

  ["$kuangxin1"] = "汉庭之上，皆为窃天之贼！",
  ["$kuangxin2"] = "黄天之下，再无饥寒之祸。",
}

kuangxin:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(kuangxin.name) then
      if player.phase == Player.Play then
        return player.hp > 0
      elseif player.phase == Player.Finish then
        return player:getMark("kuangxin_hp") > 0 and player.hp ~= player:getMark("kuangxin_hp")
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Play then
      local n = room:askToNumber(player, {
        skill_name = kuangxin.name,
        prompt = "#kuangxin-choice",
        min = 1,
        max = player.hp,
      })
      room:loseHp(player, n, kuangxin.name)
      if player.dead then return end
      player:drawCards(n, kuangxin.name)
      if player.dead then return end
      if player:isKongcheng() then
        room:setPlayerMark(player, kuangxin.name, 0)
        return
      end
      local cards = player:getCardIds("h")
      n = player:getLostHp() + 1
      if #cards > n then
        cards = room:askToCards(player, {
          min_num = n,
          max_num = n,
          include_equip = false,
          skill_name = kuangxin.name,
          prompt = "#kuangxin-show:::"..n,
          cancelable = false,
        })
      end
      room:setPlayerMark(player, kuangxin.name, #cards)
      player:showCards(cards)
    elseif player.phase == Player.Finish then
      player.hp = player:getMark("kuangxin_hp")
      room:broadcastProperty(player, "hp")
    end
  end,

  can_refresh = function (self, event, target, player, data)
    return target == player and player.phase == Player.Start
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "kuangxin_hp", player.hp)
  end,
})

return kuangxin
