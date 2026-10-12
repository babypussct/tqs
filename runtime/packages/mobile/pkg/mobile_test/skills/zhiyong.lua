
local zhiyong = fk.CreateSkill {
  name = "zhiyong",
  max_branches_use_time = {
    ["1"] = {
      [Player.HistoryGame] = 1
    },
    ["2"] = {
      [Player.HistoryGame] = 1
    },
    ["3"] = {
      [Player.HistoryGame] = 1
    },
  },
}

Fk:loadTranslationTable{
  ["zhiyong"] = "致用",
  [":zhiyong"] = "每局游戏每项限一次，你可以弃置对应数量张牌，视为使用一张普通【杀】：<br>"..
  "1.手牌数；2.2；3.“惘”数。<br>"..
  "若弃置牌数等于序数，改为弃置一名其他角色对应数量张牌或摸等量张牌。",

  ["#zhiyong"] = "致用：弃置%arg张牌，视为使用一张【杀】",
  ["#zhiyong_update"] = "致用：弃置一名其他角色%arg张牌或摸%arg张牌，视为使用一张【杀】（先选择【杀】的目标，然后执行弃牌/摸牌效果）",
  ["zhiyong_1"] = "手牌数",
  ["zhiyong_3"] = "“惘”数",
  ["#zhiyong-choose"] = "致用：弃置一名其他角色%arg张牌，或点“取消”摸%arg张牌",

  ["$zhiyong1"] = "如今学业终成，朕可大显身手！",
  ["$zhiyong2"] = "相父曾言学以致用，今日朕当理事！",
}

zhiyong:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  prompt = function (self, player, selected_cards, selected)
    if self.interaction.data == "zhiyong_1" then
      if player:getHandcardNum() == 1 then
        return "#zhiyong_update:::1"
      else
        return "#zhiyong:::"..player:getHandcardNum()
      end
    elseif self.interaction.data == "2" then
      return "#zhiyong_update:::2"
    elseif self.interaction.data == "zhiyong_3" then
      if player:getMark("@xiangxue") == 3 then
        return "#zhiyong_update:::3"
      else
        return "#zhiyong:::"..player:getMark("@xiangxue")
      end
    end
  end,
  interaction = function (self, player)
    local choices = {}
    if zhiyong:withinBranchTimesLimit(player, "1", Player.HistoryGame) then
      table.insert(choices, "zhiyong_1")
    end
    if zhiyong:withinBranchTimesLimit(player, "2", Player.HistoryGame) then
      table.insert(choices, "2")
    end
    if zhiyong:withinBranchTimesLimit(player, "3", Player.HistoryGame) then
      table.insert(choices, "zhiyong_3")
    end
    return UI.ComboBox { choices = choices, all_choices = { "zhiyong_1", "2", "zhiyong_3" } }
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  card_filter = function (self, player, to_select, selected, selected_targets)
    if self.interaction.data == "zhiyong_1" then
      if player:getHandcardNum() == 1 then
        return false
      else
        return not player:prohibitDiscard(to_select) and #selected < player:getHandcardNum()
      end
    elseif self.interaction.data == "zhiyong_3" then
      if player:getMark("@xiangxue") == 3 then
        return false
      else
        return not player:prohibitDiscard(to_select) and #selected < player:getMark("@xiangxue")
      end
    end
  end,
  view_as = function(self, player, cards)
    if self.interaction.data == nil then return end
    local card = Fk:cloneCard("slash")
    card.skillName = zhiyong.name
    if self.interaction.data == "zhiyong_1" and player:getHandcardNum() ~= 1 then
      if #cards ~= player:getHandcardNum() then return end
      card:addFakeSubcards(cards)
    elseif self.interaction.data == "2" then
      if #cards ~= 0 then return end
    elseif self.interaction.data == "zhiyong_3" and player:getMark("@xiangxue") ~= 3 then
      if #cards ~= player:getMark("@xiangxue") then return end
      card:addFakeSubcards(cards)
    end
    return card
  end,
  before_use = function (self, player, use)
    local room = player.room
    local n = self.interaction.data:sub(-1)
    player:addSkillBranchUseHistory(zhiyong.name, n, 1)
    if #use.card.fake_subcards > 0 then
      room:throwCard(use.card.fake_subcards, zhiyong.name, player, player)
    else
      n = tonumber(n)  ---@cast n integer
      if (n == 1 and player:isKongcheng()) or (n == 3 and player:getMark("@xiangxue") == 0) then
        return
      end
      local targets = table.filter(room:getOtherPlayers(player, false), function (p)
        return #p:getCardIds("he") >= n
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#zhiyong-choose:::"..n,
          skill_name = zhiyong.name,
          cancelable = true,
        })
        if #to > 0 then
          to = to[1]
          local cards = room:askToChooseCards(player, {
            target = to,
            min = n,
            max = n,
            flag = "he",
            skill_name = zhiyong.name,
          })
          room:throwCard(cards, zhiyong.name, to, player)
        else
          player:drawCards(n, zhiyong.name)
        end
      else
        player:drawCards(n, zhiyong.name)
      end
    end
  end,
  enabled_at_play = function (self, player)
    return #player:getViewAsCardNames(zhiyong.name, { "slash" }) > 0
  end,
  enabled_at_response =function (self, player, response)
    return not response and #player:getViewAsCardNames(zhiyong.name, { "slash" }) > 0
  end,
}, { check_skill_limit = true })

return zhiyong
