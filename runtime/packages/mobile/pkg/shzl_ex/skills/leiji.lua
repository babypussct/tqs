local leiji = fk.CreateSkill{
  name = "ex__leiji",
}

Fk:loadTranslationTable{
  ["ex__leiji"] = "雷击",
  [":ex__leiji"] = "当你使用或打出【闪】后，你可以令一名其他角色进行一次判定，若结果为：♠，你对其造成2点雷电伤害；♣，你回复1点体力，"..
  "对其造成1点雷电伤害。",

  ["#ex__leiji-choose"] = "雷击：令一名角色进行判定，若为♠，你对其造成2点雷电伤害；若为♣，你回复1点体力，对其造成1点雷电伤害",

  ["$ex__leiji1"] = "成为黄天之世的祭品吧。",
  ["$ex__leiji2"] = "呼风唤雨，驱雷策电！",
}

local leiji_spec = {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(leiji.name) and target == player and data.card.name == "jink"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = leiji.name,
      prompt = "#ex__leiji-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local judge = {
      who = to,
      reason = leiji.name,
      pattern = {
        [".|.|spade,club"] = "good",
        [".|.|spade"] = "spade",
        [".|.|club"] = "club",
        ["else"] = "bad"
      },
    }
    room:judge(judge)
    if not judge.results then return false end
    if table.contains(judge.results, "spade") then
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = 2,
          damageType = fk.ThunderDamage,
          skillName = leiji.name,
        }
      end
    elseif table.contains(judge.results, "club") then
      if player:isWounded() and not player.dead then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = leiji.name,
        }
      end
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = leiji.name,
        }
      end
    end
  end,
}

leiji:addEffect(fk.CardUsing, leiji_spec)
leiji:addEffect(fk.CardResponding, leiji_spec)

return leiji
