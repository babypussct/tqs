local jinghe = fk.CreateSkill{
  name = "ty_heg__jinghe",
  related_skills = { "ex__leiji", "yinbingn", "huoqi", "guizhu", "xianshou", "lundao", "guanyue", "yanzhengn" },
}

Fk:loadTranslationTable{
  ["ty_heg__jinghe"] = "经合",
  [":ty_heg__jinghe"] = "出牌阶段限一次，你可以展示至多X张牌名各不同的手牌并选择等量有明置武将牌的角色，"..
  "从“写满技能的天书”随机展示X个技能，这些角色依次选择并获得其中一个技能，直到你下回合开始（X为你的体力上限）。",

  ["#ty_heg__jinghe"] = "经合：展示至多%arg张牌名各不同的手牌，令等量的角色获得技能",
  ["#ty_heg__jinghe-choice"] = "经合：选择你要获得的技能",

  ["$ty_heg__jinghe1"] = "大哉乾元，万物资始。",
  ["$ty_heg__jinghe2"] = "无极之外，复无无极。",
}

local H = require "packages.hegemony.util"

jinghe:addEffect("active", {
  anim_type = "support",
  min_card_num = 1,
  min_target_num = 1,
  prompt = function (self, player, selected_cards, selected_targets)
    return "#ty_heg__jinghe:::"..player.maxHp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(jinghe.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < player.maxHp and table.contains(player:getCardIds("h"), to_select) and
      table.every(selected, function(id)
        return Fk:getCardById(to_select).trueName ~= Fk:getCardById(id).trueName
      end)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected < #selected_cards and H.getGeneralsRevealedNum(to_select) > 0
  end,
  feasible = function (self, player, selected, selected_cards)
    return #selected > 0 and #selected == #selected_cards
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    player:showCards(effect.cards)
    if player.dead then return end

    local num = 0 + #effect.tos
    local all_skills = table.random({ "ex__leiji", "yinbingn", "huoqi", "guizhu", "xianshou", "lundao", "guanyue", "yanzhengn" }, num)
    local skills = table.simpleClone(all_skills)
    local record = {}
    for _, p in ipairs(effect.tos) do
      if not p.dead then
        local choices = table.filter(skills, function(s) return
          not p:hasSkill(s, true)
        end)
        if #choices > 0 then
          local choice = room:askToChoice(p, {
            choices = choices,
            skill_name = jinghe.name,
            prompt = "#ty_heg__jinghe-choice:::"..#skills,
            cancelable = true,
            all_choices = all_skills,
          })
          table.removeOne(skills, choice)
          record[p.id] = choice
          room:handleAddLoseSkills(p, choice, nil, true, true)
        end
      end
    end
    room:setPlayerMark(player, "ty_heg__jinghe_skills", record)
  end,
})

local spec = {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("ty_heg__jinghe_skills") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for pid, skill in pairs(player:getMark("ty_heg__jinghe_skills")) do
      room:handleAddLoseSkills(room:getPlayerById(pid), "-"..skill, nil, true, true)
    end
    room:setPlayerMark(player, "ty_heg__jinghe_skills", 0)
  end,
}

jinghe:addEffect(fk.TurnStart, spec)
jinghe:addEffect(fk.BuryVictim, spec)

return jinghe
