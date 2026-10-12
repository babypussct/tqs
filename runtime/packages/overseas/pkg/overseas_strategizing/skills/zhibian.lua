local zhibian = fk.CreateSkill {
  name = "os__zhibian"
}

Fk:loadTranslationTable{
  ["os__zhibian"] = "直辩",
  [":os__zhibian"] = "出牌阶段开始时，你可以与一名角色拼点，若你赢，你可以选择一项：1.将其场上一张牌移至你的对应区域，"..
  "或将其区域内的一张牌移至你的手牌；2.回复1点体力；背水：弃置一张非基本牌；若你没赢，你失去1点体力。",

  ["#os__zhibian-choose"] = "直辩：你可以与一名角色拼点，若赢可以移动其牌或回复体力，没赢则失去体力",
  ["os__zhibian_move"] = "将%arg场上一张牌移至你的场上，或将其区域内一张牌移至你的手牌",
  ["os__zhibian_beishui"] = "背水：弃置一张非基本牌",
  ["os__zhibian_field"] = "将%arg场上一张牌移至你的场上",
  ["os__zhibian_get"] = "将%arg区域内一张牌移至你的手牌",

  ["$os__zhibian1"] = "两国各增守将，皆事势宜然，何足相问。",
  ["$os__zhibian2"] = "固边大计，乃立国之本，岂有不设之理。",
}

zhibian:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhibian.name) and player.phase == Player.Play and
      not player:isKongcheng() and table.find(player.room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__zhibian-choose",
      skill_name = zhibian.name,
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
    local pindian = player:pindian({to}, zhibian.name)
    if player.dead then return end
    if pindian.results[to].winner == player then
      if to.dead and not player:isWounded() then return end
      local all_choices = {
        "os__zhibian_move::"..target.id,
        "recover",
        "os__zhibian_beishui",
        "Cancel",
      }
      local choices = table.simpleClone(all_choices)
      if not player:isWounded() or
        not table.find(player:getCardIds("he"), function (id)
          return Fk:getCardById(id).type ~= Card.TypeBasic and not player:prohibitDiscard(id)
        end) then
        table.remove(choices, 3)
      end
      if not player:isWounded() then
        table.remove(choices, 2)
      end
      if to:isAllNude() or to.dead then
        table.remove(choices, 1)
      end
      if #choices == 1 then return end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = zhibian.name,
        all_choices = all_choices,
      })
      if choice == "os__zhibian_beishui" then
        room:askToDiscard(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = zhibian.name,
          cancelable = false,
          pattern = ".|.|.|.|.|^basic",
        })
        if player.dead then return end
      end
      if choice ~= "recover" and not to:isAllNude() and not to.dead then
        choices = {"os__zhibian_get::"..to.id}
        if to:canMoveCardsInBoardTo(player) then table.insert(choices, 1, "os__zhibian_move::"..to.id) end
        local choice2 = room:askToChoice(player, {
          choices = choices,
          skill_name = zhibian.name,
        })
        if choice2:startsWith("os__zhibian_move") then
          room:askToMoveCardInBoard(player, {
            target_one = to,
            target_two = player,
            skill_name = zhibian.name,
            move_from = target,
          })
        else
          local cid = room:askToChooseCard(player, {
            player = player,
            target = to,
            flag = "hej",
            skill_name = zhibian.name,
          })
          room:moveCardTo(cid, Player.Hand, player, fk.ReasonJustMove, zhibian.name, nil, false, player)
        end
        if player.dead then return end
      end
      if choice == "recover" or choice == "os__zhibian_beishui" then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = zhibian.name,
        }
      end
    else
      room:loseHp(player, 1, zhibian.name)
    end
  end,
})

return zhibian
