local fayi = fk.CreateSkill {
  name = "m_js__fayi",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") then
      return "m_js__fayi_1v2"
    else
      return "m_js__fayi_role_mode"
    end
  end,
}

Fk:loadTranslationTable{
  ["m_js__fayi"] = "伐异",
  [":m_js__fayi"] = "当你参与议事结束后，你可以对至多两名（若为斗地主模式，则改为一名）意见与你不同的角色造成1点伤害。",

  [":m_js__fayi_1v2"] = "当你参与议事结束后，你可以对一名意见与你不同的角色造成1点伤害。",
  [":m_js__fayi_role_mode"] = "当你参与议事结束后，你可以对至多两名意见与你不同的角色造成1点伤害。",

  ["#m_js__fayi-choose"] = "伐异：你可以对至多%arg名意见与你不同的角色造成伤害",

  ["$m_js__fayi1"] = "吾除董贼，朝野自是吾一言之堂。",
  ["$m_js__fayi2"] = "念私惠而忘公义，其与董贼同罪！",
}

local U = require "packages.utility.utility"

fayi:addEffect(U.DiscussionFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fayi.name) and data.results[player] and
      table.find(data.tos, function(p)
        return not p.dead and data.results[p] and data.results[player].opinion ~= data.results[p].opinion
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.tos, function(p)
      return not p.dead and data.results[p] and data.results[player].opinion ~= data.results[p].opinion
    end)
    local n = room:isGameMode("1v2_mode") and 1 or 2
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = n,
      prompt = "#m_js__fayi-choose:::"..n,
      skill_name = fayi.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = fayi.name,
        }
      end
    end
  end,
})

return fayi
