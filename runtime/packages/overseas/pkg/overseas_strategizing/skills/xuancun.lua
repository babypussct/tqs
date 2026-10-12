local xuancun = fk.CreateSkill {
  name = "os__xuancun",
}

Fk:loadTranslationTable{
  ["os__xuancun"] = "悬存",
  [":os__xuancun"] = "其他角色回合结束时，若你的体力值大于手牌数，你可以令其摸X张牌（X为你体力值与手牌数之差，至多为3）；"..
  "若你的手牌数大于体力值，你可以交给其两张牌并回复1点体力。",

  ["#os__xuancun-invoke"] = "悬存：你可以令 %dest 摸%arg张牌",
  ["#os__xuancun-give"] = "悬存：你可以交给 %dest 两张牌，你回复1点体力",

  ["$os__xuancun1"] = "阿斗年幼，望子龙将军仔细！",
  ["$os__xuancun2"] = "今得见将军，此儿有望生矣。",
}

xuancun:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(xuancun.name) and not target.dead and
      player.hp > player:getHandcardNum() or (player:getHandcardNum() > player.hp and #player:getCardIds("he") > 1)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = player.hp - player:getHandcardNum()
    if n > 0 then
      if room:askToSkillInvoke(player, {
        skill_name = xuancun.name,
        prompt = "#os__xuancun-invoke::"..target.id..":"..math.min(3, n),
      }) then
        event:setCostData(self, { tos = { target } })
        return true
      end
    elseif n < 0 then
      local cards = room:askToCards(player, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = xuancun.name,
        prompt = "#os__xuancun-give::"..target.id,
        cancelable = true,
      })
      if #cards > 0 then
        event:setCostData(self, { tos = { target }, cards = cards })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    if cards then
      room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, xuancun.name, nil, false, player)
      if not player.dead then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = xuancun.name,
        }
      end
    else
      target:drawCards(math.min(3, player.hp - player:getHandcardNum()), xuancun.name)
    end
  end,
})

return xuancun
