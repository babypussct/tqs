local guixin = fk.CreateSkill {
  name = "ol__guixin",
}

Fk:loadTranslationTable{
  ["ol__guixin"] = "归心",
  [":ol__guixin"] = "当你受到1点伤害后，你可以随机获得所有其他角色区域里的一张牌，然后你翻面。",

  ["#ol__guixin-choose"] = "归心：请选择优先获得牌的区域",

  ["$ol__guixin1"] = "我以四海为珍馐，欲宴天下以太平！",
  ["$ol__guixin2"] = "饮慷慨之佳醴，咏食苹之子衿。",
  ["$ol__guixin3"] = "九州毁于狼烟，本欲为能臣，奈何无治世。",
  ["$ol__guixin4"] = "欲使天下归心，心当系于天下，岂容相负。",
}

guixin:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(guixin.name) and table.find(player.room.alive_players, function (p)
      return p ~= player and not p:isAllNude()
    end)
  end,
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = guixin.name,
    }) then
      event:setCostData(self, {tos = room:getOtherPlayers(player, false)})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "$Hand", "$Equip", "$Judge" },
      skill_name = guixin.name,
      prompt = "#ol__guixin-choose",
    })
    for _, p in ipairs(room:getOtherPlayers(player)) do
      local areaMapper = {
        ["$Hand"] = "h",
        ["$Equip"] = "e",
        ["$Judge"] = "j",
      }
      if not p.dead and not p:isAllNude() then
        local id
        if #p:getCardIds(areaMapper[choice]) > 0 then
          id = room:tableRandomPick(p:getCardIds(areaMapper[choice]))
        else
          id = room:tableRandomPick(p:getCardIds("hej"))
        end
        room:obtainCard(player, id, false, fk.ReasonPrey, player, guixin.name)
        if player.dead then return end
      end
    end
    player:turnOver()
  end,
})

local AI = Fk.Ltk.AI
guixin:addAI(AI.reuse("guixin", AI.InvokeStrategy))

return guixin
