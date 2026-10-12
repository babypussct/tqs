local yuyan = fk.CreateSkill {
  name = "os__yuyan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__yuyan"] = "御严",
  [":os__yuyan"] = "锁定技，当你成为体力值大于你的角色【杀】的目标时，其须交给你一张点数大于此【杀】点数的牌（若此【杀】无点数则改为非基本牌），"..
  "否则取消此目标。",

  ["#os__yuyan-card1"] = "御严：交给 %src 一张非基本牌，否则取消此目标",
  ["#os__yuyan-card2"] = "御严：交给 %src 一张点数大于 %arg 的牌，否则取消此目标",

  ["$os__yuyan1"] = "正直敢言，不惧圣怒。",
  ["$os__yuyan2"] = "威武不能屈，方为大丈夫。",
}

yuyan:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuyan.name) and data.card.trueName == "slash" and
      data.from.hp > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pattern
    local prompt
    if data.card.number < 1 then
      pattern = ".|.|.|.|.|^basic"
      prompt = "#os__yuyan-card1:" .. player.id
    else
      pattern = ".|" .. data.card.number + 1 .. "~K"
      prompt = "#os__yuyan-card2:" .. player.id .. "::" .. data.card.number
    end
    local card
    if not data.from.dead then
      card = room:askToCards(data.from, {
        min_num = 1,
        max_num = 1,
        pattern = pattern,
        skill_name = yuyan.name,
        cancelable = true,
        prompt = prompt,
      })
    end
    if #card > 0 then
      room:moveCardTo(card, Player.Hand, player, fk.ReasonGive, yuyan.name, nil, false, data.from)
    else
      data:cancelTarget(player)
    end
  end,
})

return yuyan
