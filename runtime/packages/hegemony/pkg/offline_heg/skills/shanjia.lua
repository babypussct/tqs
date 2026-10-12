local shanjia = fk.CreateSkill {
  name = "ofl_heg__shanjia",
}

Fk:loadTranslationTable{
  ["ofl_heg__shanjia"] = "缮甲",
  [":ofl_heg__shanjia"] = "出牌阶段开始时，你可以摸X张牌（X为与你势力相同的角色数），然后弃置一张牌，"..
  "若此牌为装备牌，你可以视为使用一张不计入次数的【杀】。",

  ["#ofl_heg__shanjia-discard"] = "缮甲：弃置一张牌，若为装备牌则视为使用【杀】",
  ["#ofl_heg__shanjia-slash"] = "缮甲：你可以视为使用一张【杀】",

  ["$ofl_heg__shanjia1"] = "缮甲厉兵，伺机而行。",
  ["$ofl_heg__shanjia2"] = "战，当取精锐之兵，而弃驽钝也。",
}

local H = require "packages.hegemony.util"

shanjia:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shanjia.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #table.filter(room.alive_players, function (p)
      return H.compareKingdomWith(p, player)
    end)
    player:drawCards(n, shanjia.name)
    if player.dead then return end
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = shanjia.name,
      cancelable = false,
      prompt = "#ofl_heg__shanjia-discard",
      skip = true,
    })
    if #cards > 0 then
      local yes = Fk:getCardById(cards[1]).type == Card.TypeEquip
      room:throwCard(cards, shanjia.name, player, player)
      if player.dead or not yes then return end
      room:askToUseVirtualCard(player, {
        name = "slash",
        skill_name = shanjia.name,
        prompt = "#ofl_heg__shanjia-slash",
        extra_data = {
          bypass_times = true,
          extraUse = true,
        }
      })
    end
  end,
})

return shanjia
