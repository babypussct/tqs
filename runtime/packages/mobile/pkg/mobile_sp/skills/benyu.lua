
local benyu = fk.CreateSkill{
  name = "mobile__benyu",
}

Fk:loadTranslationTable{
  ["mobile__benyu"] = "贲育",
  [":mobile__benyu"] = "当你受到伤害后，若你的手牌数：小于X，你可以将手牌摸至X张（最多摸五张）；"..
  "大于X，你可以弃置至少X+1张手牌，对伤害来源造成1点伤害（X为伤害来源的手牌数）。",

  ["$mobile__benyu1"] = "择主当平天下之乱，安万民之息。",
  ["$mobile__benyu2"] = "进则立田单之功，退则违忠孝之义。",
}

benyu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(benyu.name) and
      data.from and not data.from.dead and
      (player:getHandcardNum() > data.from:getHandcardNum() or
      player:getHandcardNum() < math.min(data.from:getHandcardNum(), 5))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getHandcardNum() > data.from:getHandcardNum() then
      local num = data.from:getHandcardNum() + 1
      local cards = room:askToDiscard(player, {
        min_num = num,
        max_num = 999,
        include_equip = false,
        skill_name = benyu.name,
        prompt = "#benyu-discard::"..data.from.id..":"..num,
        cancelable = true,
        skip = true,
      })
      if #cards >= num then
        event:setCostData(self, { tos = { data.from }, cards = cards })
        return true
      end
    elseif room:askToSkillInvoke(player, {
      skill_name = benyu.name,
      prompt = "#benyu-draw:::"..math.min(data.from:getHandcardNum() - player:getHandcardNum(), 5),
    }) then
      event:setCostData(self, { tos = { data.from } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).cards then
      room:throwCard(event:getCostData(self).cards, benyu.name, player, player)
      if not data.from.dead then
        room:damage{
          from = player,
          to = data.from,
          damage = 1,
          skillName = benyu.name,
        }
      end
    else
      player:drawCards(math.min(data.from:getHandcardNum() - player:getHandcardNum(), 5), benyu.name)
    end
  end,
})

return benyu
