
local tongling = fk.CreateSkill {
  name = "nos_heg__tongling",
}

Fk:loadTranslationTable {
  ["nos_heg__tongling"] = "通令",
  [":nos_heg__tongling"] = "出牌阶段内限一次，当你对势力与你不同的角色造成伤害后，你可以选择一名势力与你相同的角色，"..
  "令其可以对受到此伤害的角色使用一张牌，然后若此牌造成过伤害，则你与其各摸两张牌，否则受到伤害的角色获得你对其造成伤害的牌。",

  ["#nos_heg__tongling-choose"] = "通令：选择一名同势力角色，其可以对 %dest 使用一张牌",
  ["#nos_heg__tongling-use"] = "通令：你可以对 %dest 使用一张牌，若造成伤害则与 %src 各摸两张牌",

  ["$nos_heg__tongling1"] = "孝直溢美之言，特以此小利报之，还望笑纳。",
  ["$nos_heg__tongling2"] = "孟起，莫非甘心为他人座下之客。",
}

local H = require "packages.hegemony.util"

tongling:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(tongling.name) and player.phase == Player.Play and
      player:usedSkillTimes(tongling.name, Player.HistoryPhase) == 0 and not data.to.dead and
      H.compareKingdomWith(player, data.to, true)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getAlivePlayers(false), function(p)
      return H.compareKingdomWith(p, player)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#nos_heg__tongling-choose::" .. data.to.id,
      skill_name = tongling.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local use = room:askToPlayCard(to, {
      skill_name = tongling.name,
      prompt = "#nos_heg__tongling-use:"..player.id..":"..data.to.id,
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
        exclusive_targets = { data.to.id },
      },
    })
    if use then
      if use.damageDealt then
        if not player.dead then
          player:drawCards(2, tongling.name)
        end
        if not to.dead then
          to:drawCards(2, tongling.name)
        end
      elseif room:getCardArea(data.card) == Card.Processing and not data.to.dead then
        room:moveCardTo(data.card, Card.PlayerHand, data.to, fk.ReasonJustMove, tongling.name, nil, true, data.to)
      end
    end
  end,
})

return tongling
