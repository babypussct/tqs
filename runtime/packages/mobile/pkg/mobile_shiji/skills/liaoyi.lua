local liaoyi = fk.CreateSkill {
  name = "liaoyi",
}

Fk:loadTranslationTable{
  ["liaoyi"] = "疗疫",
  [":liaoyi"] = "其他角色回合开始时，若其手牌数小于体力值且场上“仁”数量不小于X，则你可以令其获得X张“仁”；若其手牌数大于体力值，"..
  "则可以令其将X张手牌置入“仁”区（X为其手牌数与体力值之差，且至多为4）。",

  ["#liaoyi1-invoke"] = "疗疫：你可以令 %dest 获得%arg张“仁”",
  ["#liaoyi2-invoke"] = "疗疫：你可以令 %dest 将%arg张手牌置入“仁”区",
  ["#liaoyi-choose"] = "疗疫：获得%arg张“仁”区牌",
  ["#liaoyi-put"] = "疗疫：你需将%arg张手牌置入“仁”区",

  ["$liaoyi1"] = "麻黄之汤，或可疗伤寒之疫。",
  ["$liaoyi2"] = "望闻问切，因病施治。",
}

local U = require "packages.utility.utility"

liaoyi:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(liaoyi.name) and target ~= player and not target.dead then
      local n = target:getHandcardNum() - target.hp
      return n ~= 0 and #U.GetRenPile(player.room) >= math.min(-n, 4)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local n = target:getHandcardNum() - target.hp
    local prompt
    if n < 0 then
      prompt = "#liaoyi1-invoke::"..target.id..":"..math.min(-n, 4)
    else
      prompt = "#liaoyi2-invoke::"..target.id..":"..math.min(n, 4)
    end
    if player.room:askToSkillInvoke(player, {
      skill_name = liaoyi.name,
      prompt = prompt,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = target:getHandcardNum() - target.hp
    if n < 0 then
      n = math.min(-n, 4)
      local cards = room:askToChooseCards(target, {
        target = target,
        min = n,
        max = n,
        flag = {
          card_data = {{"@$RenPile", U.GetRenPile(room)}}
        },
        prompt = "#liaoyi-choose:::"..n,
        skill_name = liaoyi.name,
      })
      room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonJustMove, liaoyi.name, nil, true, target)
    else
      n = math.min(n, 4)
      local cards = room:askToCards(target, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = liaoyi.name,
        prompt = "#liaoyi-put:::"..n,
        cancelable = false,
      })
      U.AddToRenPile(target, cards, liaoyi.name)
    end
  end,
})

return liaoyi
