local fudi = fk.CreateSkill{
  name = "ld__fudi",
}

Fk:loadTranslationTable{
  ["ld__fudi"] = "附敌",
  [":ld__fudi"] = "当你受到伤害后，你可以交给伤害来源一张手牌，若如此做，你对与其势力相同的角色中体力值最大且不小于你的一名角色造成1点伤害。",
  ["#ld__fudi-give"] = "附敌：你可以交给 %src 一张手牌，然后对其势力体力最大的角色造成1点伤害",
  ["#ld__fudi-choose"] = "附敌：选择要造成伤害的目标",

  ["$ld__fudi1"] = "弃暗投明，为明公计！",
  ["$ld__fudi2"] = "绣虽有降心，奈何贵营难容。",
}

local H = require "packages.hegemony.util"

fudi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fudi.name) and
      data.from and data.from ~= player and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = fudi.name,
      prompt = "#ld__fudi-give:" .. data.from.id,
      cancelable = true,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:obtainCard(data.from, event:getCostData(self).cards, false, fk.ReasonGive)
    if player.dead then return end
    local p = data.from
    local x = player.hp
    if not p or p.dead then return end
    local targets = {} ---@type ServerPlayer[]
    for _, _p in ipairs(room.alive_players) do
      if H.compareKingdomWith(_p, p) then
        if _p.hp >= x then
          if _p.hp > x then
            targets = {}
            x = _p.hp
          end
          table.insert(targets, _p)
        end
      end
    end
    local to
    if #targets == 0 then return
    elseif #targets == 1 then
      to = targets[1]
    else
      to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#ld__fudi-choose",
        skill_name = fudi.name,
        cancelable = false,
      })[1]
    end
    room:damage {
      from = player,
      to = to,
      damage = 1,
      skillName = fudi.name,
    }
  end,
})

return fudi
