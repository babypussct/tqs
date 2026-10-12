local xuancun = fk.CreateSkill {
  name = "xuancun",
}

Fk:loadTranslationTable{
  ["xuancun"] = "悬存",
  [":xuancun"] = "其他角色回合结束时，若你的体力值大于手牌数，你可以令其摸X张牌（X为你体力值与手牌数之差且至多为2）。",

  ["#xuancun-invoke"] = "悬存：你可以令 %dest 摸%arg张牌",

  ["$xuancun1"] = "阿斗年幼，望子龙将军仔细！",
  ["$xuancun2"] = "今得见将军，此儿有望生矣。",
}

xuancun:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xuancun.name) and target ~= player and not target.dead and
      player.hp > player:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = xuancun.name,
      prompt = "#xuancun-invoke::"..target.id..":"..math.min(2, player.hp - player:getHandcardNum()),
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(math.min(2, player.hp - player:getHandcardNum()), xuancun.name)
  end,
})

return xuancun
