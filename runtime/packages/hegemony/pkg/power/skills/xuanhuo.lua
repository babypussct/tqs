local xuanhuo = fk.CreateSkill {
  name = "ld__xuanhuo",
  attached_skill_name = "ld__xuanhuo_other&",
  related_skills = {
    "xuanhuo__hs__wusheng",
    "xuanhuo__hs__paoxiao",
    "xuanhuo__hs__longdan",
    "xuanhuo__hs__tieqi",
    "xuanhuo__hs__liegong",
    "xuanhuo__hs__kuanggu",
  },
}

Fk:loadTranslationTable {
  ["ld__xuanhuo"] = "眩惑",
  [":ld__xuanhuo"] = "势力与你相同的其他角色的出牌阶段限一次，其可以交给你一张手牌，然后其弃置一张牌，"..
  "选择并获得下列技能中当前场上没有的一个直到回合结束：〖武圣〗〖咆哮〗〖龙胆〗〖铁骑〗〖烈弓〗〖狂骨〗。",

  ["$ld__xuanhuo1"] = "给你的，十倍奉还给我！",
  ["$ld__xuanhuo2"] = "重用许靖，以眩远近。",
}

local H = require "packages.hegemony.util"

local spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local players = room.alive_players
    local fazhengs = table.filter(players, function(p) return p:hasShownSkill(xuanhuo.name) end)
    local xuanhuo_map = {}
    for _, p in ipairs(players) do
      local will_attach = false
      for _, fazheng in ipairs(fazhengs) do
        if (fazheng ~= p and H.compareKingdomWith(fazheng, p)) then
          will_attach = true
          break
        end
      end
      xuanhuo_map[p] = will_attach
    end
    for p, v in pairs(xuanhuo_map) do
      if v ~= p:hasSkill("ld__xuanhuo_other&") then
        room:handleAddLoseSkills(p, v and xuanhuo.attached_skill_name or "-" .. xuanhuo.attached_skill_name, nil, false,
          true)
      end
    end
  end,
}

xuanhuo:addEffect(fk.AfterPropertyChange, spec)
xuanhuo:addEffect(fk.GeneralRevealed, spec)
xuanhuo:addEffect(fk.GeneralHidden, spec)
xuanhuo:addEffect(fk.Deathed, spec)

local addLoseEffect = function (self, player)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    if p ~= player and H.compareKingdomWith(player, p) then
      room:handleAddLoseSkills(p, xuanhuo.attached_skill_name, nil, false, true)
    end
  end
end
xuanhuo:addAcquireEffect(addLoseEffect)
xuanhuo:addLoseEffect(addLoseEffect)

return xuanhuo
