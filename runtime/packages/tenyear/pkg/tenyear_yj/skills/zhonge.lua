local zhonge = fk.CreateSkill {
  name = "zhonge",
}

Fk:loadTranslationTable{
  ["zhonge"] = "忠锷",
  [":zhonge"] = "出牌阶段限一次，你可以将手牌调整至体力上限，然后与一名其他角色同时选择一项并依次执行："..
    "1.你与其依次摸一张牌；2.你与其依次视为对对方使用一张【杀】。若其选择的项与你不同，每项操作在你执行时均多执行一次。",

  ["#zhonge"] = "忠锷：将手牌调整至体力上限",
  ["#zhonge-target"] = "忠锷：选择一名其他角色，与其同时选择一项并依次执行",
  ["#zhonge-choice"] = "忠锷：选择一项执行",
  ["zhonge_draw"] = "与其各摸一张牌",
  ["zhonge_slash"] = "与其依次视为对对方使用【杀】",

  ["$zhonge1"] = "殿陛群臣数万，岂无诛贼之人！",
  ["$zhonge2"] = "汉有忠，天不绝！",
}

zhonge:addEffect("active", {
  anim_type = "control",
  prompt = "#zhonge",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(zhonge.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local skillName = zhonge.name
    local player = effect.from
    local x = player:getHandcardNum() - player.maxHp
    if x < 0 then
      player:drawCards(-x, skillName)
    else
      room:askToDiscard(player, {
        min_num = x,
        max_num = x,
        include_equip = false,
        skill_name = skillName,
        cancelable = false,
      })
    end
    if player.dead then return end
    local targets = room:getOtherPlayers(player)
    if#targets == 0 then return end
    local target = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#zhonge-target",
      skill_name = skillName,
      cancelable = false,
    })[1]

    local result = room:askToJointChoice(player, {
      players = { player, target },
      choices = { "zhonge_draw", "zhonge_slash" },
      skill_name = skillName,
      prompt = "#zhonge-choice:" .. player.id,
      send_log = false,
    })

    if result[player] == result[target] then
      if result[player] == "zhonge_draw" then
        for _ = 1, 2, 1 do
          if not player.dead then
            player:drawCards(1, skillName)
          end
          if not target.dead then
            target:drawCards(1, skillName)
          end
        end
      else
        for _ = 1, 4, 1 do
          if player.dead or target.dead then break end
          local slash = Fk:cloneCard("slash")
          slash.skillName = skillName
          if player:canUseTo(slash, target, { bypass_distances = true, bypass_times = true }) then
            room:useCard{
              from = player,
              tos = { target },
              card = slash,
              extraUse = true,
            }
          end
          local tmp = player
          player = target
          target = tmp
        end
      end
    else
      if not player.dead then
        player:drawCards(1, skillName)
        if not player.dead then
          player:drawCards(1, skillName)
        end
      end
      if not target.dead then
        target:drawCards(1, skillName)
      end
      for i = 1, 3, 1 do
        if player.dead or target.dead then break end
        if i == 3 then
          local tmp = player
          player = target
          target = tmp
        end
        local slash = Fk:cloneCard("slash")
        slash.skillName = skillName
        if player:canUseTo(slash, target, { bypass_distances = true, bypass_times = true }) then
          room:useCard{
            from = player,
            tos = { target },
            card = slash,
            extraUse = true,
          }
        end
      end
    end
  end,
})

return zhonge
