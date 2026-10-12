local jianliang = fk.CreateSkill{
  name = "ty_heg__jianliang",
}
local H = require "packages.hegemony.util"
jianliang:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianliang.name) and player.phase == Player.Draw and
      table.every(player.room.alive_players, function(p) return player:getHandcardNum() <= p:getHandcardNum() end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end)
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        p:drawCards(1, jianliang.name)
      end
    end
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__jianliang"] = "简亮",
  [":ty_heg__jianliang"] = "摸牌阶段开始时，若你的手牌数为全场最少，你可令与你势力相同的所有角色各摸一张牌。",

  ["$ty_heg__jianliang1"] = "岂曰少衣食，与君共袍泽！",
  ["$ty_heg__jianliang2"] = "义士同心力，粮秣应期来！",
}

return jianliang
