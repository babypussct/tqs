local shuren = fk.CreateSkill {
  name = "shuren",
}

Fk:loadTranslationTable{
  ["shuren"] = "淑任",
  [":shuren"] = "出牌阶段限一次，你可废除一个装备栏，亮出牌堆顶三张牌，你选择其中一张牌获得并可选择一名其他角色获得其中一张牌，"..
    "若此装备栏有牌则此技能视为未发动过并恢复1点体力。",

  ["#shuren"] = "淑任：选择一个装备栏废除",
  ["#shuren-choose"] = "淑任：选择一名其他角色，令其挑选一张牌获得",

  ["$shuren1"] = "嫁舟过江浦，荷花犹记女儿红。",
  ["$shuren2"] = "玉锁枷春风，却惊小荷角上蜓。",
}

shuren:addEffect("active", {
  anim_type = "support",
  prompt = "#shuren",
  interaction = function(self, player)
    return UI.OptionBox { options = player:getAvailableEquipSlots(), direct_send = true }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(shuren.name, Player.HistoryPhase) < 1 and #player:getAvailableEquipSlots() > 0
  end,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local skillName = shuren.name
    local player = effect.from
    local slot_name = self.interaction.data
    local e_type = Util.convertSubtypeAndEquipSlot(slot_name)
    local recover = (player:getEquipment(e_type) ~= nil)

    room:abortPlayerArea(player, slot_name)
    if player.dead then return end

    if recover then
      player:clearSkillHistory(skillName, Player.HistoryPhase)
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = skillName
        }
        if player.dead then return end
      end
    end

    local cards = room:getNCards(3)
    room:turnOverCardsFromDrawPile(player, cards, skillName)
    room:delay(2000)

    if not player.dead then
      local id = room:askToChooseCard(player, {
        target = player,
        flag = {
          card_data = {
            { skillName, cards }
          }
        },
        skill_name = skillName,
      })

      room:obtainCard(player, id, true, fk.ReasonJustMove, player, skillName)
      table.removeOne(cards, id)
      if not player.dead then
        local targets = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = room:getOtherPlayers(player, false),
          skill_name = skillName,
          prompt = "#shuren-choose",
          cancelable = true,
        })
        if #targets > 0 then
          local to = targets[1]

          id = room:askToChooseCard(to, {
            target = player,
            flag = {
              card_data = {
                { skillName, cards }
              }
            },
            skill_name = skillName,
          })

          room:obtainCard(to, id, true, fk.ReasonJustMove, to, skillName)
        end
      end
    end

    room:cleanProcessingArea(cards, skillName)
  end,
})

return shuren
