local wuniang = fk.CreateSkill{
  name = "ol__wuniang",
}

Fk:loadTranslationTable{
  ["ol__wuniang"] = "武娘",
  [":ol__wuniang"] = "你可将一张非基本牌当无距离限制且不可响应的【杀】使用。"..
    "然后你获得一名目标角色的一张牌，若不为基本牌，你可失去1点体力然后令所有角色的〖镇南〗视为未发动过。",

  ["#ol__wuniang"] = "武娘：你可将一张非基本牌当【杀】使用（无距离限制，不可响应）",
  ["#ol__wuniang-choose"] = "武娘：获得一名目标角色的一张牌",
  ["#ol__wuniang-invoke"] = "武娘：失去1点体力，令所有角色的〖镇南〗视为未发动过",

  ["$ol__wuniang1"] = "虽为女子身，不输男儿郎。",
  ["$ol__wuniang2"] = "剑舞轻盈，沙场克敌。",
}

wuniang:addEffect("viewas", {
  pattern = "slash",
  prompt = "#ol__wuniang",
  anim_type = "offensive",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|.|.|trick,equip",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card:addSubcards(cards)
    card.skillName = wuniang.name
    return card
  end,
  before_use = function(self, player, use)
    use.disresponsiveList = table.simpleClone(player.room.players)
  end,
  after_use = function(self, player, use)
    local room = player.room
    local skillName = wuniang.name
    if player.dead or type(use.tos) ~= "table" then return end
    local tos = {}
    for _, p in ipairs(use.tos) do
      if not (p.dead or p:isNude()) then
        table.insertIfNeed(tos, p)
      end
    end
    if #tos == 0 then
      return
    elseif #tos > 1 then
      tos = room:askToChoosePlayers(
        player,
        {
          targets = tos,
          min_num = 1,
          max_num = 1,
          prompt = "#ol__wuniang-choose",
          skill_name = skillName,
          cancelable = false
        }
      )
    end
    local cid = room:askToChooseCard(player, {
      target = tos[1],
      flag = "he",
      skill_name = skillName,
    })
    room:obtainCard(player, cid, false, fk.ReasonPrey, player, skillName)
    if player.dead then return end
    if Fk:getCardById(cid, true).type ~= Card.TypeBasic and room:askToSkillInvoke(player, {
      skill_name = skillName,
      prompt = "#ol__wuniang-invoke",
    }) then
      room:loseHp(player, 1, skillName)
      for _, p in ipairs(room.alive_players) do
        if p:hasSkill("ol__zhennan", true) then
          p:clearSkillHistory("ol__zhennan")
        end
      end
    end
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})

wuniang:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(card.skillNames, wuniang.name)
  end,
})

return wuniang
