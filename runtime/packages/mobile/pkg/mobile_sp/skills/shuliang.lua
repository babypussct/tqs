local shuliang = fk.CreateSkill {
  name = "shuliang",
}

Fk:loadTranslationTable{
  ["shuliang"] = "输粮",
  [":shuliang"] = "一名角色结束阶段，若其手牌数小于其体力值，你可以移去一张“粮”，然后该角色摸两张牌。",

  ["#shuliang-invoke"] = "输粮：你可以移去一张“粮”，令 %dest 摸两张牌",

  ["$shuliang1"] = "将军驰劳，酒肉慰劳。",
  ["$shuliang2"] = "将军，牌来了。",
}

shuliang:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  expand_pile = "lifeng_liang",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(shuliang.name) and
      target.phase == Player.Finish and not target.dead and
      target:getHandcardNum() < target.hp and
      #player:getPile("lifeng_liang") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        skill_name = shuliang.name,
        pattern = ".|.|.|lifeng_liang|.|.",
        prompt = "#shuliang-invoke::" .. target.id,
        expand_pile = "lifeng_liang",
      }
    )
    if #cards > 0 then
      event:setCostData(self, { cards = cards, tos = {target} })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = shuliang.name
    local room = player.room
    room:moveCards({
      from = player,
      ids = event:getCostData(self).cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = skillName,
    })
    if target:isAlive() then
      target:drawCards(2, skillName)
    end
  end,
})

return shuliang
