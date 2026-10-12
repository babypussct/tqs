local lianpo = fk.CreateSkill {
  name = "mobile__lianpo",
}

Fk:loadTranslationTable{
  ["mobile__lianpo"] = "连破",
  [":mobile__lianpo"] = "当你杀死其他角色后，你可以选择一项：1.于此回合结束后获得一个额外的回合（每回合限一次）；" ..
  "2.若你有〖极略〗，则你选择并获得一项你未拥有的〖极略〗中的技能。",

  ["mobile__lianpo_turn"] = "获得一个额外回合",
  ["mobile__lianpo_skill"] = "选择获得一项“极略”技能",
  ["@@mobile__lianpo-turn"] = "连破",

  ["$mobile__lianpo1"] = "能战当战，不能战当死尔！",
  ["$mobile__lianpo2"] = "连下诸城以筑京观，足永平辽东之患。",
}

local jilue_skills = {
  "guicai",
  "fangzhu",
  "jizhi",
  "zhiheng",
  "wansha",
}
lianpo:addEffect(fk.Deathed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(lianpo.name) and data.killer == player then
      if player:getMark("@@mobile__lianpo-turn") == 0 and player.room.logic:getCurrentEvent():findParent(GameEvent.Turn, true) then
        return true
      else
        return player:hasSkill("mobile__jilue", true) and
          table.find(jilue_skills, function(s) return
            not player:hasSkill(s, true)
          end)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = { "Cancel" }

    local skills = table.filter(jilue_skills, function(s)
      return not player:hasSkill(s, true)
    end)
    if #skills > 0 and player:hasSkill("mobile__jilue", true) then
      table.insert(choices, 1, "mobile__lianpo_skill")
    end

    if player:getMark("@@mobile__lianpo-turn") == 0 and room.logic:getCurrentEvent():findParent(GameEvent.Turn, true) then
      table.insert(choices, 1, "mobile__lianpo_turn")
    end

    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = lianpo.name,
      all_choices = {
        "mobile__lianpo_turn",
        "mobile__lianpo_skill",
        "Cancel",
      },
    })
    if choice == "Cancel" then
      return false
    elseif choice == "mobile__lianpo_skill" then
      choice = room:askToChoice(player, {
        choices = skills,
        skill_name = lianpo.name,
      })
    end
    event:setCostData(self, {choice = choice})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "mobile__lianpo_turn" then
      room:setPlayerMark(player, "@@mobile__lianpo-turn", 1)
      player:gainAnExtraTurn(true, lianpo.name)
    else
      room:handleAddLoseSkills(player, choice, nil, true, false)
    end
  end,
})

return lianpo
