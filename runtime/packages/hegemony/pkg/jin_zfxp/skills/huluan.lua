
local huluan = fk.CreateSkill {
  name = "heg__huluan",
}

Fk:loadTranslationTable{
  ["heg__huluan"] = "怙乱",
  [":heg__huluan"] = "准备阶段，你可以观看至多三名角色各一张暗置的武将牌，若这些牌势力均相同，你对这些角色各造成1点伤害或令这些角色各摸两张牌。",

  ["#heg__huluan-choose"] = "怙乱：观看至多三名角色各一张暗置的武将牌，若势力均相同，对其各造成1点伤害或令其各摸两张牌",
  ["#heg__huluan-choice"] = "怙乱：选择对这些角色执行的一项",
}

local H = require "packages.hegemony.util"

huluan:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huluan.name) and player.phase == Player.Start and
      table.find(player.room.alive_players, function (p)
        return p.general == "anjiang" or p.deputyGeneral == "anjiang"
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p.general == "anjiang" or p.deputyGeneral == "anjiang"
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 3,
      prompt = "#heg__huluan-choose",
      skill_name = huluan.name,
      cancelable = true
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos or {}
    local kingdoms = {}
    for _, p in ipairs(tos) do
      local choices = { "known_both_main", "known_both_deputy" }
      if p.general ~= "anjiang" then
        table.remove(choices, 1)
      end
      if p.deputyGeneral ~= "anjiang" then
        table.remove(choices)
      end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = huluan.name,
        prompt = "#known_both-choice::"..p.id,
      })
      local general = H.viewGeneral(player, p, huluan.name, choice == "known_both_main", choice == "known_both_deputy")
      table.insertIfNeed(kingdoms, Fk.generals[general].kingdom)
    end
    if #kingdoms == 1 then
      local choice = room:askToChoice(player, {
        choices = { "damage1", "draw2" },
        skill_name = huluan.name,
        prompt = "#heg__huluan-choice",
      })
      if choice == "damage1" then
        for _, p in ipairs(tos) do
          if not p.dead then
            room:damage{
              from = player,
              to = p,
              damage = 1,
              skillName = huluan.name,
            }
          end
        end
      else
        for _, p in ipairs(tos) do
          if not p.dead then
            p:drawCards(2, huluan.name)
          end
        end
      end
    end
  end,
})

return huluan
