local chunlao = fk.CreateSkill{
  name = "ol_heg__chunlao",
  attached_skill_name = "ol_heg__chunlao_other&",
}

Fk:loadTranslationTable{
  ["ol_heg__chunlao"] = "醇醪",
  [":ol_heg__chunlao"] = "与你势力相同的角色可以移去一枚“阴阳鱼”或“珠联璧合”标记，视为使用一张【酒】。",

  ["$ol_heg__chunlao1"] = "唉，帐中不可无酒啊！",
  ["$ol_heg__chunlao2"] = "无碍，且饮一杯！",
}

local H = require "packages.hegemony.util"

local chunlao_spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local players = room.alive_players
    local chengpus = table.filter(players, function(p) return p:hasShownSkill(chunlao.name) end)
    local chunlao_map = {}
  for _, p in ipairs(players) do
    local will_attach = false
    for _, chengpu in ipairs(chengpus) do
      if H.compareKingdomWith(chengpu, p) then
        will_attach = true
        break
      end
    end
    chunlao_map[p] = will_attach
  end
    for p, v in pairs(chunlao_map) do
      if v ~= p:hasSkill("ol_heg__chunlao_other&") then
        room:handleAddLoseSkills(p, v and chunlao.attached_skill_name or "-" .. chunlao.attached_skill_name, nil, false, true)
      end
    end
  end,
}

local addLoseEffect = function (self, player, _)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    if H.compareKingdomWith(player, p) then
      room:handleAddLoseSkills(p, chunlao.attached_skill_name, nil, false, true)
    end
  end
end
chunlao:addAcquireEffect(addLoseEffect)
chunlao:addLoseEffect(addLoseEffect)
chunlao:addEffect(fk.AfterPropertyChange,chunlao_spec)
chunlao:addEffect(fk.GeneralRevealed, chunlao_spec)
chunlao:addEffect(fk.GeneralHidden, chunlao_spec)
chunlao:addEffect(fk.Deathed, chunlao_spec)

return chunlao