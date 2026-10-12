local shenzhuo = fk.CreateSkill {
  name = "shenzhuo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shenzhuo"] = "神著",
  [":shenzhuo"] = "锁定技，当你使用非转化且非虚拟的【杀】结算结束后，你须选择一项：1.摸一张牌，令你于本回合内使用【杀】的次数上限+1；"..
  "2.摸三张牌，令你于本回合内不能使用【杀】。",

  ["shenzhuo_draw1"] = "摸1张牌，可以继续出杀",
  ["shenzhuo_draw3"] = "摸3张牌，本回合不能出杀",
  ["@@shenzhuo-turn"] = "神著 禁止出杀",

  ["$shenzhuo1"] = "力引强弓百斤，矢除贯手著棼！",
  ["$shenzhuo2"] = "箭既已在弦上，吾又岂能不发！",
}

shenzhuo:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shenzhuo.name) and data.card.trueName == "slash" and
      not data.card:isVirtual()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "shenzhuo_draw1", "shenzhuo_draw3" },
      skill_name = shenzhuo.name,
    })
    if choice == "shenzhuo_draw1" then
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-turn", 1)
      player:drawCards(1, shenzhuo.name)
    else
      room:setPlayerMark(player, "@@shenzhuo-turn", 1)
      player:drawCards(3, shenzhuo.name)
    end
  end,
})
shenzhuo:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("@@shenzhuo-turn") > 0 and card.trueName == "slash"
  end,
})

return shenzhuo
