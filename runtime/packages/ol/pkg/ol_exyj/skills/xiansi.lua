local xiansi = fk.CreateSkill {
  name = "ol_ex__xiansi",
  derived_piles = "liufeng_ni",
  attached_skill_name = "xiansi&",
}

Fk:loadTranslationTable{
  ["ol_ex__xiansi"] = "陷嗣",
  [":ol_ex__xiansi"] = "准备阶段，你可以将至多两名角色的共计至多两张牌置于你的武将牌上，称为“逆”。"..
  "其他角色可以移去两张“逆”，视为对你使用一张【杀】。",

  ["#ol_ex__xiansi-choose"] = "陷嗣：你可以将至多两名角色的共计至多两张牌置为“逆”",

  ["$ol_ex__xiansi1"] = "",
  ["$ol_ex__xiansi2"] = "",
  ["$ol_ex__xiansi3"] = "",
  ["$ol_ex__xiansi4"] = "",
}

xiansi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiansi.name) and player.phase == Player.Start and
      table.find(player.room.alive_players, function (p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isNude()
    end)
    local tos = room:askToChoosePlayers(player, {
      skill_name = xiansi.name,
      min_num = 1,
      max_num = 2,
      targets = targets,
      prompt = "#ol_ex__xiansi-choose",
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 2
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p:isNude() then
        local cards = room:askToChooseCards(player, {
          min = 1,
          max = n,
          target = p,
          flag = "he",
          skill_name = xiansi.name,
        })
        n = n - #cards
        player:addToPile("liufeng_ni", cards, true, xiansi.name)
        if n == 0 or player.dead then return end
      end
    end
  end,
})

return xiansi
