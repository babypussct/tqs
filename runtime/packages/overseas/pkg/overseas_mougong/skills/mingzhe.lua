
local mingzhe = fk.CreateSkill({
  name = "os_mou__mingzhe",
  tags = { Skill.Compulsory },
})

Fk:loadTranslationTable{
  ["os_mou__mingzhe"] = "明哲",
  [":os_mou__mingzhe"] = "锁定技，每轮限两次，当你于回合外失去牌时，你选择一名角色，若其有蓄力技，令其获得1点蓄力点；"..
  "若你失去的牌中有非基本牌，则其摸两张牌。",

  ["#os_mou__mingzhe_draw-choose"] = "明哲：选择一名角色，若其有蓄力技则其获得1点蓄力点，摸两张牌",
  ["#os_mou__mingzhe-choose"] = "明哲：选择一名角色，若其有蓄力技则其获得1点蓄力点",
  ["os_mou__mingzhe_has_charge"] = "有蓄力技",

  ["$os_mou__mingzhe1"] = "",
  ["$os_mou__mingzhe2"] = "",
}

local U = require "packages.utility.utility"

mingzhe:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  times = function (self, player)
    return 2 - player:usedSkillTimes(mingzhe.name, Player.HistoryRound)
  end,
  can_trigger = function(self, event, target, player, data)
    if
      player:hasSkill(mingzhe.name) and
      player.phase == Player.NotActive and
      player:usedSkillTimes(mingzhe.name, Player.HistoryRound) < 2
    then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Player.Hand or info.fromArea == Player.Equip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mingzhe.name
    local room = player.room
    local draw = false
    for _, move in ipairs(data) do
      if
        move.from == player and
        table.find(
          move.moveInfo,
          function(info)
            return (info.fromArea == Player.Hand or info.fromArea == Player.Equip) and Fk:getCardById(info.cardId).type ~= Card.TypeBasic
          end
        )
      then
        draw = true
        break
      end
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = room:getAlivePlayers(false),
        min_num = 1,
        max_num = 1,
        prompt = draw and "#os_mou__mingzhe_draw-choose" or "#os_mou__mingzhe-choose",
        skill_name = skillName,
        cancelable = false,
        target_tip_name = "os_mou__mingzhe",
      }
    )
    local to = tos[1]
    U.skillCharged(to, 1)
    if draw then
      to:drawCards(2, skillName)
    end
  end,
})

Fk:addTargetTip{
  name = "os_mou__mingzhe",
  target_tip = function(_, _, to_select)
    if table.find(to_select:getSkillNameList(), function(s) return Fk.skills[s]:hasTag(Skill.Charge) end) then
      return "os_mou__mingzhe_has_charge"
    end
  end,
}

return mingzhe
