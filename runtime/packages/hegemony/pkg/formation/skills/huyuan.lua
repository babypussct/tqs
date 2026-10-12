
local huyuan = fk.CreateSkill{
  name = "ld__huyuan",
}

Fk:loadTranslationTable{
  ["ld__huyuan"] = "护援",
  [":ld__huyuan"] = "当与你势力相同的角色成为【杀】的目标时，你可以将一张牌当【调虎离山】对其他势力角色使用（不能为当前回合角色）。",

  ["#ld__huyuan-invoke"] = "护援：你可以将一张牌当【调虎离山】使用",

  ["$ld__huyuan1"] = "拼将性命，定保曹公周全。",
  ["$ld__huyuan2"] = "舍命献马，护我曹公！",
}

local H = require "packages.hegemony.util"

huyuan:addEffect(fk.TargetConfirming, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(huyuan.name) and data.card and
        data.card.trueName == "slash" and
        H.compareKingdomWith(player, target) and not player:isNude()) then
      return false
    end
    local card = Fk:cloneCard("lure_tiger")
    return table.find(player.room.alive_players, function(p)
      return p ~= player.room:getCurrent() and player:canUseTo(card, p) and
        H.compareKingdomWith(player, p, true)
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard("lure_tiger")
    local targets = table.filter(room.alive_players, function(p)
      return p ~= room:getCurrent() and player:canUseTo(card, p) and
        H.compareKingdomWith(player, p, true)
    end)
    local use = room:askToUseVirtualCard(player, {
      name = "lure_tiger",
      skill_name = huyuan.name,
      prompt = "#ld__huyuan-invoke",
      extra_data = {
        must_targets = table.map(targets, Util.IdMapper),
      },
      cancelable = true,
      card_filter = {
        n = 1,
      },
      skip = true,
    })
    if use then
      event:setCostData(self, { extra_data = use })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

return huyuan
