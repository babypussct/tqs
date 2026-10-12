local mobileZhennan = fk.CreateSkill {
  name = "mobile__zhennan",
}

Fk:loadTranslationTable{
  ["mobile__zhennan"] = "镇南",
  [":mobile__zhennan"] = "当一名角色使用普通锦囊牌指定第一个目标后，若目标中有你且目标数大于X（X为使用者的体力值且至少为1），你可以弃置一张牌，" ..
  "对一名角色造成1点伤害。",

  ["#mobile__zhennan-discard"] = "镇南：你可以弃置一张牌，对一名角色造成1点伤害",

  ["$mobile__zhennan1"] = "怎可让你再兴风作浪？",
  ["$mobile__zhennan2"] = "南中由我和夫君一起守护！",
}

mobileZhennan:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(mobileZhennan.name) and
      not player:isNude() and
      data.firstTarget and
      data.card:isCommonTrick() and
      data.from:isAlive() and
      table.contains(data.use.tos, player) and
      #data.use.tos > math.max(data.from.hp, 1)
  end,
  on_cost = function(self, event, target, player, data)
    local tos, cards = player.room:askToChooseCardsAndPlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        min_card_num = 1,
        max_card_num = 1,
        targets = player.room:getAlivePlayers(false),
        skill_name = mobileZhennan.name,
        prompt = "#mobile__zhennan-discard",
        will_throw = true,
        skip = true,
      }
    )
    if #tos > 0 and #cards > 0 then
      event:setCostData(self, { tos = tos, cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mobileZhennan.name
    local room = player.room
    room:throwCard(event:getCostData(self).cards, skillName, player, player)
    local to = event:getCostData(self).tos[1]
    if to:isAlive() then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = skillName,
      }
    end
  end,
})

return mobileZhennan
