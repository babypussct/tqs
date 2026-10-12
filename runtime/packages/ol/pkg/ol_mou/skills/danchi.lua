local danchi = fk.CreateSkill {
  name = "danchi",
}

Fk:loadTranslationTable {
  ["danchi"] = "胆持",
  [":danchi"] = "每回合限一次，与你距离1以内的角色受到伤害后，你可以令受到伤害的角色选择一个类型。然后伤害来源本回合使用下一张牌后，" ..
  "你视为使用一张【无中生有】，若与“胆持”选择的类型不同，你额外可以视为使用一张【杀】。",

  ["#danchi-invoke"] = "胆持：是否令目标角色猜测 %dest 本回合使用的下一张牌？",
  ["#danchi-choice"] = "胆持：猜测 %src 本回合使用的下一张牌",
  ["#danchi-use"] = "胆持：请视为使用一张牌",
  ["#danchi-slash"] = "胆持：请视为使用一张【杀】",
  ["@@danchi-turn"] = "胆持",

  ["$danchi1"] = "敌军势大，必轻易不来攻。",
  ["$danchi2"] = "两军相持，从来有胆者胜，无胆者亡。",
}

danchi:addEffect(fk.Damaged, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target:compareDistance(player, 1, "<=") and player:hasSkill(danchi.name) and
      player:usedSkillTimes(danchi.name, Player.HistoryTurn) == 0 and
      not (data.from.dead or data.to.dead)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = danchi.name,
      prompt = "#danchi-invoke::" .. data.to.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(data.to, {
      choices = { "basic", "trick", "equip" },
      skill_name = danchi.name,
      prompt = "#danchi-choice:" .. data.from.id,
    })
    room:setPlayerMark(player, "@@danchi-turn", { data.from.id, choice, room.logic.current_event_id })
  end,
})

danchi:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(danchi.name) then
      local mark = player:getTableMark("@@danchi-turn")
      return #mark == 3 and mark[1] == target.id and player.room.logic:getCurrentEvent().id > mark[3]
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@@danchi-turn")
    room:setPlayerMark(player, "@@danchi-turn", 0)
    if mark[2] == data.card:getTypeString() then
      room:useVirtualCard("ex_nihilo", {}, player, player, danchi.name)
    else
      local use = room:askToUseVirtualCard(player, {
        name = { "slash", "ex_nihilo" },
        skill_name = danchi.name,
        prompt = "#danchi-use",
        extra_data = {
          bypass_times = true,
          bypass_distances = true,
        },
        skip = true
      })
      if use then
        if use.card.trueName == "slash" then
          use.extraUse = true
          room:useCard(use)
          if not player.dead then
            room:useVirtualCard("ex_nihilo", {}, player, player, danchi.name)
          end
        else
          room:useCard(use)
          room:askToUseVirtualCard(player, {
            name = "slash",
            skill_name = danchi.name,
            prompt = "#danchi-slash",
            extra_data = {
              bypass_times = true,
              bypass_distances = true,
              extraUse = true
            }
          })
        end
      end
    end
  end,
})

return danchi
