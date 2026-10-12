
local yicong = fk.CreateSkill {
  name = "m_heg__yicong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_heg__yicong"] = "义从",
  [":m_heg__yicong"] = "锁定技，你造成/受到伤害后，直到本轮结束，你计算与其他角色的距离-1/其他角色计算与你的距离+1。"..
  "然后若因此技能调整的对应值达到3，你从牌堆中获得一张【杀】或【闪】。",

  ["@m_heg__yicong_from-round"] = "义从-",
  ["@m_heg__yicong_to-round"] = "义从+",

  ["$m_heg__yicong1"] = "冲啊！",
  ["$m_heg__yicong2"] = "众将听令，排好阵势，御敌！",
}

yicong:addEffect(fk.Damage, {
  anim_type = "offensive",
  audio_index = 1,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@m_heg__yicong_from-round", 1)
    if player:getMark("@m_heg__yicong_from-round") > 2 then
      local card = room:getCardsFromPileByRule("slash,jink")
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, yicong.name, nil, false, player)
      end
    end
  end,
})
yicong:addEffect(fk.Damaged, {
  anim_type = "masochism",
  audio_index = 2,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@m_heg__yicong_to-round", 1)
    if player:getMark("@m_heg__yicong_to-round") > 2 then
      local card = room:getCardsFromPileByRule("slash,jink")
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, yicong.name, nil, false, player)
      end
    end
  end,
})

yicong:addEffect("distance", {
  correct_func = function (self, from, to, card)
    return -from:getMark("@m_heg__yicong_from-round") + to:getMark("@m_heg__yicong_to-round")
  end,
})

return yicong
