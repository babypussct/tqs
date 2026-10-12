local liulis = fk.CreateSkill {
  name = "os__liulis",
}

Fk:loadTranslationTable{
  ["os__liulis"] = "流俪",
  [":os__liulis"] = "当一名角色成为伤害牌的目标后，你可以弃置其场上的一张红色牌，令此牌对其无效，然后若其受伤状态与你相同，你摸两张牌。",

  ["#os__liulis"] = "流俪：你可弃置 %dest 场上的一张红色牌，令%arg对其无效",
  ["#os__liulis-discard"] = "流俪：弃置%dest场上的一张红色牌",

  ["$os__liulis1"] = "每忆数载情深，更忧生死别离。",
  ["$os__liulis2"] = "居安防微杜渐，危时方得无忧。",
}

liulis:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(liulis.name) and data.card.is_damage_card and table.find(target:getCardIds("ej"), function(id)
      return Fk:getCardById(id).color == Card.Red
    end)
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = liulis.name,
      prompt = "#os__liulis::" .. target.id .. ":" .. data.card:toLogString(),
      data = data,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCards(player, {
      target = target,
      flag = "ej",
      min = 1,
      max = 1,
      pattern = ".|.|red",
      skill_name = liulis.name,
      prompt = "#os__liulis-discard::" .. target.id,
    })
    room:throwCard(card, liulis.name, target, player)
    data:setNullified(target)
    if target:isWounded() == player:isWounded() and player:isAlive() then
      player:drawCards(2, liulis.name)
    end
  end,
})

return liulis
