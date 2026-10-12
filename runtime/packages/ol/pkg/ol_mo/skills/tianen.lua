local tianen = fk.CreateSkill {
  name = "tianen",
  tags = { Skill.Compulsory },
  max_branches_use_time = {
    ["tianen1"] = {
      [Player.HistoryTurn] = 1
    },
    ["tianen2"] = {
      [Player.HistoryTurn] = 1
    },
  }
}

local U = require "packages.utility.utility"

Fk:loadTranslationTable{
  ["tianen"] = "天恩",
  [":tianen"] = "锁定技，每回合每项各限一次，当你使用牌指定唯一目标后，若本轮你与其选择的“权御”效果不同，"..
  "你随机弃置其一张牌，对其发动一次〖权御〗；若与你相同，你获得一张不计入手牌上限的【杀】。",

  ["@@tianen-inhand"] = "天恩",

  ["$tianen1"] = "臣是薪，恩是火，莫让朕寒了心。",
  ["$tianen2"] = "雷霆雨露，俱是朕赏你的。",
  ["$tianen3"] = "庙堂之上，贤良忠臣独汝一人？",
}

tianen:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if
      target == player and
      data:isOnlyTarget(data.to) and
      data.to:isAlive() and
      player:hasSkill(tianen.name)
    then
      --没有标记的角色固定算标记不同
      local mark = U.getPrivateMark(player, "quanyu_effect-round-noclear", false)
      local same = (mark == U.getPrivateMark(data.to, "quanyu_effect-round-noclear", false) and mark ~= 0)
      return tianen:withinBranchTimesLimit(player, same and "tianen2" or "tianen1", Player.HistoryTurn)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local mark = U.getPrivateMark(player, "quanyu_effect-round-noclear", false)
    local same = (mark == U.getPrivateMark(data.to, "quanyu_effect-round-noclear", false) and mark ~= 0)
    event:setCostData(self, {
      tos = { data.to },
      history_branch = same and "tianen2" or "tianen1"
    })
    return true
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = tianen.name
    local room = player.room
    local dat = event:getCostData(self)
    local to = dat.tos[1]
    if dat.history_branch == "tianen1" then
      --优先弃置手牌
      local toDiscard = to:getCardIds("h")
      if #toDiscard == 0 then
        toDiscard = to:getCardIds("e")
      end
      if #toDiscard > 0 then
        room:throwCard(room:tableRandomPick(toDiscard), skillName, to, player)
      end

      if to:isAlive() then
        local quanyuChoices = { "quanyu_baihong", "quanyu_qingming", "quanyu_bixie", "quanyu_zidian", "quanyu_baili", "quanyu_liuxing" }

        local choices = table.filter(quanyuChoices, function(choice)
          return not table.contains(to:getTableMark("quanyu_chosen-noclear"), choice .. "_name")
        end)

        if #choices == 0 then
          --不会消除最后的标记
          --room:setPlayerMark(to, "@[private]quanyu_effect-round-noclear", 0)
          return false
        end

        local choice = room:askToChoice(
          to,
          {
            choices = choices,
            skill_name = "quanyu",
            prompt = "#quanyu-choice",
            all_choices = quanyuChoices,
          }
        )

        local formattedChoice = choice .. "_name"
        room:addTableMark(to, "quanyu_chosen-noclear", formattedChoice)
        U.setPrivateMark(to, "quanyu_effect-round-noclear", formattedChoice, { to.id, player.id })

        if formattedChoice == U.getPrivateMark(player, "quanyu_effect-round-noclear", false) and player:isAlive() then
          player:drawCards(1, skillName)
        end
      end
    else
      local cards = room:getCardsFromPileByRule("slash", 1)
      if #cards > 0 then
        --移动信息对其他角色不可见
        room:obtainCard(player, cards, false, fk.ReasonPrey, player, skillName, "@@tianen-inhand")
      end
    end
  end,
})

tianen:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@tianen-inhand") > 0
  end,
})

return tianen
