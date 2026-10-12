local yishi = fk.CreateSkill {
  name = "xing__yishi",
}

Fk:loadTranslationTable{
  ["xing__yishi"] = "义释",
  [":xing__yishi"] = "当你对其他角色造成伤害时，你可以令此伤害-1并获得其装备区里的一张牌。",

  ["#xing__yishi-invoke"] = "义释：是否令对 %dest 造成的伤害-1，获得其装备区一张牌？",

  ["$xing__yishi1"] = "昨日释忠之恩，今吾虚射以报。",
  ["$xing__yishi2"] = "君刀不砍头颅，吾箭只射盔缨。",
}

yishi:addEffect(fk.DamageCaused, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yishi.name) and
      data.to ~= player and #data.to:getCardIds("e") > 0
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = yishi.name,
      prompt = "#xing__yishi-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:changeDamage(-1)
    local card = room:askToChooseCard(player,{
      target = data.to,
      flag = "e",
      skill_name = yishi.name,
    })
    room:obtainCard(player, card, true, fk.ReasonPrey, player, yishi.name)
  end,
})

return yishi
