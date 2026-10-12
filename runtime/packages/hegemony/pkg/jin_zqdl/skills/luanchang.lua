

local luanchang = fk.CreateSkill{
  name = "heg__luanchang",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["heg__luanchang"] = "乱常",
  [":heg__luanchang"] = "限定技，与你势力相同的角色受到过伤害的回合结束时，你可以令当前回合角色将所有手牌（至少一张）当【万箭齐发】使用。",

  ["#heg__luanchang-invoke"] = "乱常：是否令 %dest 将所有手牌当【万箭齐发】使用？",
}

local H = require "packages.hegemony.util"

luanchang:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(luanchang.name) and
      player:usedSkillTimes(luanchang.name, Player.HistoryGame) == 0 and
      #player.room.logic:getActualDamageEvents(1, function (e)
        return H.compareKingdomWith(player, e.data.to, false)
      end, Player.HistoryTurn) > 0 and
      not target:isKongcheng() and not target.dead and target:canUse(Fk:cloneCard("archery_attack"))
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = luanchang.name,
      prompt = "#heg__luanchang-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard("archery_attack")
    card.skillName = luanchang.name
    card:addSubcards(target:getCardIds("h"))
    local targets = table.filter(room:getOtherPlayers(target), function(p)
      return not target:isProhibited(p, card)
    end)
    room:useVirtualCard("archery_attack", target:getCardIds("h"), target, targets, luanchang.name)
  end,
})

return luanchang
