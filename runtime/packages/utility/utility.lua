-- 这个文件用来堆一些常用的函数，视情况可以分成多个文件
-- 因为不是拓展包，所以不能用init.lua（否则会被当拓展包加载并报错）
-- 因为本体里面已经有util了所以命名为完整版utility

-- 要使用的话在拓展开头加一句 local U = require "packages.utility.utility" 即可(注意别加.lua)

---@class Utility
local Utility = require 'packages.utility._base'

-- 判断一张牌是否为非转化的卡牌（不为转化使用且对应实体牌数为1且两者牌名相同）
---@param card Card @ 待判别的卡牌
---@return boolean
Utility.isPureCard = function(card)
  return not card:isVirtual() and card.name == Fk:getCardById(card.id, true).name
end

-- 根据模式修改角色的属性
---@param player ServerPlayer @ 要换将的玩家
---@param mode string @ 模式名
---@return table @ 返回表，键为调整的角色属性，值为调整后的属性
Utility.changePlayerPropertyByMode = function(player, mode)
  local room = player.room
  if not Fk.game_modes[mode] then return {} end
  local func = Fk.game_modes[mode].getAdjustedProperty
  if type(func) == "function" then
    return func(player)
  else
    local list = {}
    if player.role == "lord" and player.role_shown and #room.players > 4 then
      list.hp = player.hp + 1
      list.maxHp = player.maxHp + 1
    end
    return list
  end
end

-- 获取角色对应私人Mark的实际值
---@param player Player @ 要被获取标记的那个玩家
---@param name string @ 标记名称（不带前缀）
---@param isTableMark? boolean @ 是否为表标记，默认是
---@return any
Utility.getPrivateMark = function(player, name, isTableMark)
  isTableMark = (isTableMark == nil) and true or isTableMark
  return type(player:getMark("@[private]" .. name)) == "table" and player:getMark("@[private]" .. name).value or (isTableMark and {} or 0)
end

-- 设置角色对应私人Mark
---@param player ServerPlayer @ 要被获取标记的那个玩家
---@param name string @ 标记名称（不带前缀）
---@param value any @ 标记实际值。更新：可赋string，直接显示
---@param players? integer[] @ 公开标记的角色，若为nil则为仅对自己可见
Utility.setPrivateMark = function(player, name, value, players)
  local mark = player:getMark("@[private]" .. name)
  if type(mark) ~= "table" then mark = {} end
  if mark.players == nil then
    mark.players = players
  end
  mark.value = value
  player.room:setPlayerMark(player, "@[private]" .. name, mark)
end

--让一名角色的仅对自己可见的mark对所有角色都可见
---@param player ServerPlayer @ 要公开标记的角色
---@param name? string @ 要公开的标记名（不含前缀）
Utility.showPrivateMark = function(player, name)
  local room = player.room
  local mark = player:getMark("@[private]" .. name)
  if type(mark) == "table" then
    mark.players = table.map(room.players, Util.IdMapper)
    room:setPlayerMark(player, "@[private]" .. name, mark)
  end
end

--- 类似于askForCardsChosen，适用于“选择每个区域各一张牌”
---@param chooser ServerPlayer @ 要被询问的人
---@param target ServerPlayer @ 被选牌的人
---@param flag any @ 用"hej"三个字母的组合表示能选择哪些区域, h - 手牌区, e - 装备区, j - 判定区
---@param skill_name? string @ 技能名（暂时没用的参数，poxi没提供接口）
---@param prompt? string @ 提示信息（暂时没用的参数，poxi没提供接口）
---@param disable_ids? integer[] @ 不允许选的牌
---@param cancelable? boolean @ 是否可以点取消，默认是
---@return integer[] @ 选择的id
Utility.askforCardsChosenFromAreas = function(chooser, target, flag, skill_name, prompt, disable_ids, cancelable)
  cancelable = (cancelable == nil) and true or cancelable
  disable_ids = disable_ids or {}
  local card_data = {}
  if type(flag) ~= "string" then
    flag = "hej"
  end
  local data = {
    to = target.id,
    skillName = skill_name,
    prompt = prompt,
  }
  local visible_data = {}
  if string.find(flag, "h") then
    local cards = table.filter(target:getCardIds("h"), function (id)
      return not table.contains(disable_ids, id)
    end)
    if #cards > 0 then
      table.insert(card_data, {"$Hand", cards})
      for _, id in ipairs(cards) do
        if not chooser:cardVisible(id) then
          visible_data[tostring(id)] = false
        end
      end
      if next(visible_data) == nil then visible_data = nil end
      data.visible_data = visible_data
    end
  end
  if string.find(flag, "e") then
    local cards = table.filter(target:getCardIds("e"), function (id)
      return not table.contains(disable_ids, id)
    end)
    if #cards > 0 then
      table.insert(card_data, {"$Equip", cards})
    end
  end
  if string.find(flag, "j") then
    --- TODO: 蓄谋可见性判断
    local cards = table.filter(target:getCardIds("j"), function (id)
      return not table.contains(disable_ids, id)
    end)
    if #cards > 0 then
      table.insert(card_data, {"$Judge", cards})
    end
  end
  if #card_data == 0 then return {} end
  local ret = chooser.room:askToPoxi(chooser, {
    poxi_type ="askforCardsChosenFromAreas",
    data = card_data,
    extra_data = data,
    cancelable = cancelable,
  })
  return ret
end

Utility.familySkillMember = {
  --颍川荀
  ["yingchuan_xun"] = {
    "xunshu",
    "xunshuang", "xunchen", "xuncai", "xunyu", "xunyou",
    "xuncan", "xunshix",
    "xunxu",
    "xunguan",
  },
  --陈留吴
  ["chenliu_wu"] = {
    "wukuang",
    "wuxian", "wuyi", "wuban",
    "wuqiao",
  },
  --颍川韩
  ["yingchuan_han"] = {
    "hanshao",
    "hanrong", "hanfu",
  },
  --太原王
  ["taiyuan_wang"] = {
    "wangyun",
    "wangling", "wangchang",
    "wangguang", "wangmingshan", "wanghun", "wanglun", "wangshen",
  },
  --颍川钟
  ["yingchuan_zhong"] = {
    "zhonghao",
    "zhongyao",
    "zhongyu", "zhonghui",
    "zhongyan",
  },
  --弘农杨
  ["hongnong_yang"] = {
    "yangci",
    "yangbiao", "yangzhongh",
    "yangxiu",
    "yangjun",
    "yangyan", "yangzhi",
  },
  --吴郡陆
  ["wujun_lu"] = {
    "lukangl",
    "luji", "luxun",
    "luyusheng", "lukang", "lukai", "lutan",
    "lujing", "lujij", "luyun",
  },
  --颍川陈
  ["yingchuan_chen"] = {
    "chenshih",
    "chenji",
    "chenqun",
    "chentai",
  },
  --琅琊诸葛
  ["langya_zhuge"] = {
    "zhugeliang", "zhugejin", "zhugejun", "zhugedan", "zhugeruoxue", "zhugemengxue",
    "zhugezhan", "zhugeguo", "zhugeke", "zhugexu",
    "zhugeshang",
    "zhugejing",
  },
  --扶风法
  ["fufeng_fa"] = {
    "fazhen",
    "fayan",
    "fazheng",
    "famiao",
  },


  --河内司马
  ["henei_sima"] = {
    "simalang", "simayi", "simafu",
    "simashi", "simazhao", "simazhou", "simaliang", "simalun", "xuangongzhu",
    "simayan", "simayong", "simayue",
    "simazhong", "simawei", "simayij", "simaying", "simajiong", "simarui",
    "simayu", "linhaigongzhu",
  },
  --颍川郭
  ["yingchuan_guo"] = {
    "guojia", "guotu",
    "guotiying",
  },
  --汝南袁
  ["runan_yuan"] = {
    "yuanwei",
    "yuanshao", "yuanshu",
    "yuanshang", "yuantan", "yuanxi", "yuanji", "yuanyin",
  },
  --清河崔
  ["qinghe_cui"] = {
    "cuiyan", "cuilin",
    "cuilingyi",
  },
  --太原郭
  ["taiyuan_guo"] = {
    "guohuai",
    "guohuaij",
  },
  --泰山羊
  ["taishan_yang"] = {
    "yanghuiyu", "yanghu",
    "yangxianrong",
  },
  --京兆杜
  ["jingzhao_du"] = {
    "duji",
    "dushu",
    "duyu",
  },
  --范阳卢
  ["fanyang_lu"] = {
    "luzhi",
    "luyu", "luyi",
  },
  --琅琊王
  ["langya_wang"] = {
    "wangxiang",
    "wangrong", "wangyan", "wangdun", "wangdao",
  },
  --陈留阮
  ["chenliu_ruan"] = {
    "ruanyu",
    "ruanji", "ruanhui",
    "ruanxian",
  },
  --陇西辛
  ["longxi_xin"] = {
    "xinpi", "xinping",
    "xinxianying", "xinchang",
  },
  --陈留蔡
  ["chenliu_cai"] = {
    "caiyong",
    "caiwenji", "caizhenji",
  },
  --江夏黄
  ["jiangxia_huang"] = {"huangyueying", "huangchengyan", "huangzhong", "huangzu", "huangwudie"},
}

--- 判断一名角色是否为同族成员——OL宗族技专用
---@param player Player @ 自己
---@param target Player @ 待判断的角色
---@return boolean | string[] @ 如果有确定的家族，返回家族字符串表[]；对于自己必定返回true。否则返回false
Utility.FamilyMember = function (player, target)
  if target == player then
    return true
  end
  local family = {}
  local familyMap = Utility.familySkillMember
  for f, members in pairs(familyMap) do
    if table.contains(members, Fk.generals[player.general].trueName) then
      table.insertIfNeed(family, f)
    end
    if table.contains(table.map(members, function (name)
      return "god"..name
    end), Fk.generals[player.general].trueName) then
      table.insertIfNeed(family, f)
    end
    if player.deputyGeneral ~= "" then
      if table.contains(members, Fk.generals[player.deputyGeneral].trueName) then
        table.insertIfNeed(family, f)
      end
      if table.contains(table.map(members, function (name)
        return "god"..name
      end), Fk.generals[player.deputyGeneral].trueName) then
        table.insertIfNeed(family, f)
      end
    end
  end
  if #family == 0 then return false end
  local ret = {}
  for _, f in ipairs(family) do
    local members = familyMap[f]
    if table.contains(members, Fk.generals[target.general].trueName) then
      table.insertIfNeed(ret, f)
    end
    if target.deputyGeneral ~= "" and table.contains(members, Fk.generals[target.deputyGeneral].trueName) then
      table.insertIfNeed(ret, f)
    end
  end
  if #ret == 0 then return false end
  return ret
end

--- 将一个武将添加到某宗族中
---@param general string @ 武将名（用trueName）
---@param family string @ 加入宗族
Utility.addFamilyMember = function (general, family)
  local familyMap = Utility.familySkillMember
  if familyMap[family] == nil then
    familyMap[family] = {}
  end
  table.insertIfNeed(familyMap[family], general)
end

--- 改变一名角色的转换技状态，自动转换插画阴阳形态
---@param player ServerPlayer @ 自己
---@param skill_name string @ 转换技技能名
---@param switch_state integer? @ 要切换到的状态，不填则默认与当前状态不同
---@param prefix string[]? @ 要检测的武将前缀{阳形态前缀, 阴形态前缀}，不填则默认检测 {"tymou__", "tymou2__"}
---@return any @ 
Utility.SetSwitchSkillState = function (player, skill_name, switch_state, prefix)
  assert(prefix == nil or #prefix == 2, "prefix error")
  if switch_state == nil then
    switch_state = player:getSwitchSkillState(skill_name, true)
  end
  if player:getSwitchSkillState(skill_name, true) == switch_state then
    player.room:setPlayerMark(player, MarkEnum.SwithSkillPreName .. skill_name, switch_state)
    player:setSkillUseHistory(skill_name, 0, Player.HistoryGame)
  end

  prefix = prefix or {"tymou__", "tymou2__"}
  local generalName = nil
  for _, str in ipairs(prefix) do
    if player.general:startsWith(str) and
      table.contains(Fk.generals[player.general]:getSkillNameList(), skill_name) then
      generalName = player.general
    end
    if generalName == nil then
      if player.deputyGeneral ~= "" then
        if player.deputyGeneral:startsWith(str) and
          table.contains(Fk.generals[player.deputyGeneral]:getSkillNameList(), skill_name) then
          generalName = player.deputyGeneral
        end
      end
    end
  end
  if generalName == nil then return end
  local name = Fk.generals[generalName].trueName
  if switch_state == fk.SwitchYang then
    name = prefix[1] .. name
  else
    name = prefix[2] .. name
  end
  if generalName == player.deputyGeneral then
    player.deputyGeneral = name
    player.room:broadcastProperty(player, "deputyGeneral")
  else
    player.general = name
    player.room:broadcastProperty(player, "general")
  end
end

--花色互转（支持int(Card.Heart)，string("heart")，icon("♥")，symbol(translate后的红色"♥")）
---@param value any @ 花色
---@param input_type "int"|"str"|"icon"|"sym"
---@param output_type "int"|"str"|"icon"|"sym"
Utility.ConvertSuit = function(value, input_type, output_type)
  local mapper = {
    ["int"] = {Card.Spade, Card.Heart, Card.Club, Card.Diamond, Card.NoSuit},
    ["str"] = {"spade", "heart", "club", "diamond", "nosuit"},
    ["icon"] = {"♠", "♥", "♣", "♦", ""},
    ["sym"] = {"log_spade", "log_heart", "log_club", "log_diamond", "log_nosuit"},
  }
  return mapper[output_type][table.indexOf(mapper[input_type], value)]
end

--将数字转换为汉字，或将汉字转换为数字
---@param value number | string @ 数字或汉字
---@param to_num boolean? @ 是否转换为数字
---@return number | string @ 结果
Utility.ConvertNumber = function(value, to_num)
  local ret = "" ---@type number | string
  local candidate = {"零", "一", "二", "三", "四", "五", "六", "七", "八", "九"}
  local space = {"十", "百", "千"}

  if to_num then
    if tonumber(value) then return tonumber(value) end
    -- 耦一个两
    if value == "两" then return 2 end
    if value:find("万") or value:find("亿") then
      printf("你确定需要<%s>那么大的数字？", value)
      return value
    end
    local leng = value:len()
    for i = leng, 1, -1 do
      local _start = (i - 1) * 3 + 1
      local _end = (i) * 3
      local num = value:sub(_start, _end)
      if table.contains(candidate, num) then
        ret = tostring(table.indexOf(candidate, num) - 1) .. ret
      elseif table.contains(space, num) then
        local pos = table.indexOf(space, num) + 1
        local suc = pos - ret:len() - 1
        if suc > 0 then
          for j = 1, suc, 1 do
            ret = "0" .. ret
          end
        end
        if i == 1 then
          ret = "1" .. ret
        end
      elseif i == 1 then
        local ext = value:sub(1, 6)
        if ext == "两" then ret = 2 end
        if table.contains({"两百", "两千"}, ext) then
          ret = "2" .. ret
        end
      end
    end
    ret = tonumber(ret)
  else
    if not tonumber(value) then return value end
    local str = tostring(value)
    if value > 9999 then
      printf("你确定需要<%s>那么大的数字？", str)
      return value
    end
    local leng = str:len()
    for i = leng, 1, -1 do
      local pos = leng - i
      local num = candidate[tonumber(str:sub(i, i)) + 1]
      if pos > 0 then
        num = num .. space[pos - 1 % 3 + 1]
      end
      ret = num .. ret
    end
    if leng > 1 then
      ret = string.gsub(ret, "^一十", "")
    end
    for _, spc in ipairs(space) do
      ret = string.gsub(ret, "零" .. spc, "零")
    end
    ret = string.gsub(ret, "零零+", "零")
  end
  return ret
end

---增加标记数量的使用杀次数上限，可带后缀
MarkEnum.SlashResidue = "__slash_residue"
---使用杀无次数限制，可带后缀
MarkEnum.SlashBypassTimes = "__slash_by_times"
---使用杀无距离限制，可带后缀
MarkEnum.SlashBypassDistances = "__slash_by_dist"

--- 询问选择若干个牌名
---@param room Room
---@param player ServerPlayer @ 询问角色
---@param names table<string> @ 可选牌名
---@param minNum integer @ 最小值
---@param maxNum integer @ 最大值
---@param skillName? string @ 技能名
---@param prompt? string @ 提示信息
---@param all_names? table<string> @ 所有显示的牌名
---@param cancelable? boolean @ 是否可以取消，默认不可
---@param repeatable? boolean @ 是否可以选择重复的牌名，默认不可
---@return table<string> @ 选择的牌名
Utility.askForChooseCardNames = function (room, player, names, minNum, maxNum, skillName, prompt, all_names, cancelable, repeatable)
  local choices = {}
  skillName = skillName or ""
  prompt = prompt or skillName
  if (cancelable == nil) then cancelable = false end
  if (repeatable == nil) then repeatable = false end
  if type(all_names) == "table" then
    if #all_names == 0 or type(all_names[1]) ~= "table" then
      all_names = { all_names }
    end
  else
    all_names = { names }
  end
  local result = room:askToCustomDialog(player, {
    skill_name = skillName or "",
    component = {
      url = "packages/utility/qml/ChooseCardNamesBox.qml",
      model = {
        url = "packages/utility/qml/models/ChooseCardNamesModel.qml",
        prop = {
          choices = names,
          minNum = minNum,
          maxNum = maxNum,
          prompt = prompt,
          allChoices = all_names,
          cancelable = cancelable,
          repeatable = repeatable,
        }
      }
    }
  })
  if result ~= "" then
    choices = result
  elseif not cancelable and minNum > 0 then
    choices = room:tableRandomPick(names, minNum)
    if #choices < minNum and repeatable then
      for i = 1, minNum - #choices do
        table.insert(choices, names[1])
      end
    end
  end
  return choices
end
Fk:loadTranslationTable{
  ["Clear All"] = "清空",
}

--- 按组展示牌，并询问选择若干个牌组（用于清正等）
---@param room Room
---@param player ServerPlayer @ 询问角色
---@param listNames table<string> @ 牌组名的表
---@param listCards table<table<integer>> @ 牌组所含id表的表
---@param minNum integer @ 最小值
---@param maxNum integer @ 最大值
---@param skillName? string @ 技能名
---@param prompt? string @ 提示信息
---@param allowEmpty? boolean @ 是否可以选择空的牌组，默认不可
---@param cancelable? boolean @ 是否可以取消，默认可
---@return table<string> @ 返回选择的牌组的组名列表
Utility.askForChooseCardList = function (room, player, listNames, listCards, minNum, maxNum, skillName, prompt, allowEmpty, cancelable)
  local choices = {}
  skillName = skillName or ""
  prompt = prompt or skillName
  if (allowEmpty == nil) then allowEmpty = false end
  if (cancelable == nil) then cancelable = true end
  local availableList = table.simpleClone(listNames)
  if not allowEmpty then
    for i = #listCards, 1, -1 do
      if #listCards[i] == 0 then
        table.remove(availableList, i)
      end
    end
  end
  -- set 'cancelable' to 'true' when the count of cardlist is out of range
  if not cancelable and #availableList < minNum then
    cancelable = true
  end
  local result = room:askToCustomDialog(player, {
    skill_name = skillName or "",
    component = {
      url = "packages/utility/qml/ChooseCardListBox.qml",
      model = {
        url = "packages/utility/qml/models/ChooseCardListModel.qml",
        prop = {
          listNames = listNames,
          listCards = listCards,
          min = minNum,
          max = maxNum,
          prompt = prompt,
          allowEmpty = allowEmpty,
          cancelable = cancelable,
        }
      }
    }
  }
  )
  if result ~= "" then
    choices = result
  elseif not cancelable and minNum > 0 then
    if #availableList > 0 then
      choices = room:tableRandomPick(availableList, minNum)
    end
  end
  return choices
end

--- 从多种规则中选择一种并选牌
---@param player ServerPlayer @ 被询问的玩家
---@param patterns [string, integer, integer, string][] @ 选牌规则组。格式{{规则，选牌下限，选牌上限，提示名},{},...}
---@param skillName? string @ 技能名
---@param cancelable? boolean @ 能否点取消。默认可以
---@param prompt? string @ 提示信息
---@param extra_data? {expand_pile: string|table, discard_skill: boolean, [any]:any} @ 额外信息。可以选择"expand_pile"|"discard_skill"
---@return integer[], string @ 返回选择的牌，和选择的规则提示名
Utility.askForCardByMultiPatterns = function (player, patterns, skillName, cancelable, prompt, extra_data)
  skillName = skillName or "choose_cards_mutlipat_skill"
  cancelable = (cancelable == nil) or cancelable
  prompt = prompt or "#askForCardByMultiPatterns"
  extra_data = extra_data or {}
  local aval_cards = player:getCardIds("he")
  if type(extra_data.expand_pile) == "string" then
    table.insertTable(aval_cards, player:getPile(extra_data.expand_pile))
  elseif type(extra_data.expand_pile) == "table" then
    table.insertTable(aval_cards, extra_data.expand_pile)
  end
  if extra_data.discard_skill then
    aval_cards = table.filter(aval_cards, function(cid)
      return not player:prohibitDiscard(cid)
    end)
  end
  local aval_cardlist = {}
  local selecteable_patterns = {}
  for _, v in ipairs(patterns) do
    local cards = table.filter(aval_cards, function(cid)
      return Exppattern:Parse(v[1]):match(Fk:getCardById(cid))
    end)
    if #cards >= v[2] then
      table.insert(selecteable_patterns, v)
      table.insert(aval_cardlist, cards)
    end
  end
  if cancelable or #selecteable_patterns > 0 then
    extra_data.skillName = skillName
    extra_data.patterns = selecteable_patterns
    extra_data.all_patterns = patterns
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "choose_cards_mutlipat_skill",
      prompt = prompt,
      cancelable = cancelable,
      extra_data = extra_data
    })
    if dat then
      return dat.cards, dat.interaction
    elseif cancelable then
      return {}, ""
    end
  end

  if #selecteable_patterns == 0 then
    return {}, ""
  else
    for i, v in ipairs(selecteable_patterns) do
      return player.room:tableRandomPick(aval_cardlist[i], v[2]), v[4]
    end
  end
end

---@class AskToChooseSkillsParams: AskToUseActiveSkillParams
---@field skills string[] @ 可选的技能名
---@field generals? string[] @ 武将名
---@field min_num? integer @ 最小值，默认1
---@field max_num? integer @ 最大值，默认1
---@field skill_name string @ 发动技能名
---@field prompt? string @ 提示信息
---@field cancelable? boolean @ 能否点取消。**默认不可**
---@field send_log? boolean @ 是否发送日志，默认发送

--- 询问选择技能（可显示一技能一武将对应关系）
---@param player ServerPlayer @ 被询问的玩家
---@param params AskToChooseSkillsParams @ 询问参数
---@return string[] @ 返回选择的技能名列表
Utility.askToChooseSkills = function (player, params)
  local generals, skills, maxNum, minNum, skillName =
    params.generals, params.skills, params.max_num or 1, params.min_num or 1, params.skill_name
  if #skills == 0 then return {} end
  local cancelable = params.cancelable or false
  local prompt = params.prompt or ("#AskToChooseSkills:::" .. skillName .. ":" .. minNum .. ":" .. maxNum)
  local room = player.room
  local result = room:askToCustomDialog(player, {
    skill_name = skillName,
    component = {
      url = "packages/utility/qml/ChooseSkillBox.qml",
      model = {
        url = "packages/utility/qml/models/ChooseSkillModel.qml",
        prop = {
          skills = skills,
          min = minNum,
          max = maxNum,
          prompt = prompt,
          generals = generals,
          cancelable = cancelable,
        }
      },
    }
  })
  if result == "" then
    if cancelable then
      result = {}
    else
      result = room:tableRandomPick(skills, minNum)
    end
  end
  if params.send_log == nil or params.send_log then
    local skill_log = table.concat(table.map(result, function (s)
      return Fk:translate(s)
    end), " ")
    room:sendLog{
      type = "#Choice",
      from = player.id,
      arg = skill_log,
      toast = true,
    }
  end
  return result
end

Fk:loadTranslationTable{
  ["#AskToChooseGeneralSkills"] = "%arg：请选择%arg2到%arg3个技能",
}

---@class AskToJointSkillsParams: AskToChooseSkillsParams
---@field players ServerPlayer[] @ 被询问的玩家们
---@field skills string[] | string[][] @ 技能名
---@field generals string[] | string[][] @ 武将名，仅用于提示
---@field prompt? string | string[] @ 提示信息
---@field min_num integer | integer[] @ 最小值
---@field max_num integer | integer[] @ 最大值
---@field timeout? number @ 思考时间

--- 询问多人选择技能（可显示一技能一武将对应关系）
---@param player ServerPlayer @ 被询问的玩家
---@param params AskToJointSkillsParams @ 询问参数
---@return table<ServerPlayer, string[]> @ 每个玩家选择的技能
Utility.askToJointSkills = function (player, params)
  local players, generals, skills, maxNum, minNum, skillName =
    params.players, params.generals, params.skills, params.max_num, params.min_num, params.skill_name
  assert(#players > 0 and #skills > 0)
  local prompt = params.prompt or ("#AskToChooseSkills:::" .. skillName .. ":" .. minNum .. ":" .. maxNum)
  local room = player.room

  local req = Request:new(players, "CustomDialog")
  if params.timeout then
    req.timeout = params.timeout
  end
  req.focus_text = skillName

  local skillsMap = skills ---@type string[][]
  if type(skills[1]) == "table" then
    assert(#skills == #players)
  else
    skillsMap = table.map(players, function() return skills end)
  end
  local genralsMap ---@type string[][]?
  if generals then
    if type(generals[1]) == "table" then
      genralsMap = generals
    else
      genralsMap = table.map(players, function() return generals end)
    end
  end
  local promptMap = prompt
  if type(promptMap) == "string" then ---@type string[][]
    promptMap = table.map(players, function() return prompt end)
  end
  local minNumMap = minNum
  if type(minNum) == "number" then
    minNumMap = table.map(players, function() return minNum end)
  end
  local maxNumMap = maxNum
  if type(maxNum) == "number" then
    maxNumMap = table.map(players, function() return maxNum end)
  end

  for i, p in ipairs(players) do
    local component = {
      url = "packages/utility/qml/ChooseSkillBox.qml",
      model = {
        url = "packages/utility/qml/models/ChooseSkillModel.qml",
        prop = {
          skills = skillsMap[i],
          generals = genralsMap and genralsMap[i],
          min = minNumMap[i],
          max = maxNumMap[i],
          prompt = promptMap[i],
        }
      },
    }
    req:setData(p, {
      component = component,
    })
    req:setDefaultReply(p, room:tableRandomPick(skillsMap[i], minNumMap[i]))
  end
  req:ask()

  local result = {}
  for _, p in ipairs(players) do
    result[p] = req:getResult(p)
  end

  if params.send_log == nil or params.send_log then
    for _, p in ipairs(players) do
      local skill_log = table.concat(table.map(result[p], function (s)
        return Fk:translate(s)
      end), " ")
      room:sendLog{
        type = "#Choice",
        from = p.id,
        arg = skill_log,
        toast = true,
      }
    end
  end
  return result
end

---@class AskToChooseGeneralSkillsParams: AskToUseActiveSkillParams
---@field generals string[] @ 武将名，如```{ "liubei", "luxun" }```
---@field skills string[][] @ 可选的技能名，与武将名对应，如```{ {"rende"}, {"lilanying", "qianxun"} }```
---@field min_num integer @ 最小值
---@field max_num integer @ 最大值
---@field skill_name string @ 发动技能名
---@field prompt? string @ 提示信息
---@field cancelable? boolean @ 能否点取消，默认可以

--- 询问选择武将技能（显示一武将多技能对应关系）
---@param player ServerPlayer @ 被询问的玩家
---@param params AskToChooseGeneralSkillsParams @ 询问参数
---@return string[] @ 返回选择的技能名列表
Utility.askToChooseGeneralSkills = function (player, params)--generals, skills, minNum, maxNum, skillName, prompt, cancelable)
  local generals, skills, maxNum, minNum, skillName =
    params.generals, params.skills, params.max_num, params.min_num, params.skill_name
  local cancelable = (params.cancelable == nil) and true or params.cancelable
  local prompt = params.prompt or ("#AskToChooseGeneralSkills:::" .. skillName .. ":" .. minNum .. ":" .. maxNum)
  local result = player.room:askToCustomDialog(player, {
    skill_name = skillName,
    component = {
      url =  "packages/utility/qml/ChooseGeneralSkillsBox.qml",
      model = {
        url = "packages/utility/qml/models/ChooseGeneralSkillsModel.qml",
        prop = {
          cards = generals,
          skills = skills,
          min = minNum,
          max = maxNum,
          prompt = prompt,
          cancelable = cancelable,
        }
      }
    }
  })
  if result == "" then
    if cancelable then
      return {}
    else
      local ret, i = {}, 0 ---@type string[]
      for _, gs in ipairs(skills) do
        for _, s in ipairs(gs) do
          table.insert(ret, s)
          i = i + 1
          if i >= minNum then
            return ret
          end
        end
      end
      return ret
    end
  end
  return result
end

Fk:loadTranslationTable{
  ["#AskToChooseGeneralSkills"] = "%arg：请选择%arg2到%arg3个武将技能",
}


---@class AskToChooseGeneralsAndChoiceParams: AskToSkillInvokeParams
---@field generals string[] @ 武将名，如```{ "liubei", "luxun" }```
---@field ok_options? string[] @ 确认选项
---@field all_generals? string[] @ 全部的武将
---@field disable_generals? string[] @ 不能选择的武将
---@field min_num? integer @ 最小选择数，默认1
---@field max_num? integer @ 最大选择数，默认generals的数量
---@field cancel_options? string[] @ 取消选项
---@field cancelable? boolean @ 能否点取消，默认不能

--- 询问选择若干个武将
---@param player ServerPlayer @ 被询问的玩家
---@param params AskToChooseGeneralsAndChoiceParams @ 询问参数
---@return string[], string @ 返回选择的武将列表，选项
Utility.askToChooseGeneralsAndChoice = function (player, params)
  local generals = params.generals
  local minNum = params.min_num or 1
  local maxNum = params.max_num or #generals
  local all_generals = params.all_generals or params.generals
  local disable_generals = params.disable_generals or {}
  local ok_options = params.ok_options or {"OK"}
  local cancelable = not not params.cancelable
  local cancel_options = params.cancel_options or (cancelable and {"Cancel"} or {})
  local skillName = params.skill_name or ""
  local prompt = params.prompt or ("#AskToChooseGeneralsAndChoice:::" .. skillName .. ":" .. minNum .. ":" .. maxNum)
  assert(#ok_options > 0 or #cancel_options > 0)
  assert(#cancel_options > 0 or #generals >= minNum)
  local result = player.room:askToCustomDialog(player, {
    skill_name = skillName,
    component = {
      url =  "packages/utility/qml/ChooseGeneralsAndChoiceBox.qml",
      model = {
        url = "packages/utility/qml/models/ChooseGeneralsAndChoiceModel.qml",
        prop = {
          cards = generals,
          all_cards = all_generals,
          disable_cards = disable_generals,
          min = minNum,
          max = maxNum,
          prompt = prompt,
          ok_options = ok_options,
          cancel_options = cancel_options,
        }
      }
    }
  })
  if result == "" then
    if #cancel_options > 0 then
      return {}, cancel_options[1]
    else
      return player.room:tableRandomPick(generals, minNum), ok_options[1]
    end
  end
  return result.cards, result.choice
end

Fk:loadTranslationTable{
  ["#AskToChooseGeneralsAndChoice"] = "%arg：请选择 %arg2 到 %arg3 个武将",
}

---印影
---@param room Room
---@param n number
Utility.getShade = function (room, n)
  local ids = {}
  for _, id in ipairs(room.void) do
    if n <= 0 then break end
    if Fk:getCardById(id).name == "shade" then
      room:setCardMark(Fk:getCardById(id), MarkEnum.DestructIntoDiscard, 1)
      table.insert(ids, id)
      n = n - 1
    end
  end
  while n > 0 do
    local card = room:printCard("shade", Card.Spade, 1)
    room:setCardMark(card, MarkEnum.DestructIntoDiscard, 1)
    table.insert(ids, card.id)
    n = n - 1
  end
  return ids
end

---蓄谋
---@param player ServerPlayer @ 被蓄谋的玩家
---@param card integer | Card | integer[] | Card[]  @ 用来蓄谋的牌，每次只能蓄谋一张
---@param skill_name? string @ 技能名
---@param proposer? ServerPlayer @ 移动操作者，默认和player相同
---@return nil
Utility.premeditate = function(player, card, skill_name, proposer)
  skill_name = skill_name or ""
  proposer = proposer or player
  assert(#Card:getIdList(card) == 1)

  local room = player.room
  room:addSkill("#premeditate_rule&")

  card = Card:getIdList(card)[1]
  local xumou = Fk:cloneCard("premeditate")
  xumou:addSubcard(card)
  room:moveCards{
    ids = {card},
    from = room:getCardOwner(card),
    to = player,
    toArea = Player.Judge,
    moveReason = fk.ReasonJustMove,
    skillName = skill_name,
    moveVisible = false,
    proposer = proposer,
    visiblePlayers = {proposer, player},
    virtualEquip = xumou,
  }
end

---连接牌标记名
---@type string
Utility.ConnectedMark = "@@connected-inhand"

---@param card integer | Card
Utility.isConnectedCard = function(card)
  if type(card) == "number" then
    card = Fk:getCardById(card)
  end

  return card:getMark(Utility.ConnectedMark) > 0
end

---连接卡牌
---@param room Room
---@param cards integer | Card | integer[] | Card[]  @ 连接的卡牌
Utility.connectCards = function(room, cards)
  cards = Card:getIdList(cards)

  table.forEach(cards, function(id)
    assert(room:getCardArea(id) == Card.PlayerHand)
    local card = Fk:getCardById(id)
    if card:getMark(Utility.ConnectedMark) > 0 then
      room:setCardMark(card, Utility.ConnectedMark, 0)
    else
      room:setCardMark(card, Utility.ConnectedMark, 1)
    end
  end)

  if not room:hasSkill("#connected_cards_rule") then
    room:addSkill("#connected_cards_rule")
  end
end
Fk:loadTranslationTable{
  ["#ConnectCards"] = "一种对手牌的操作，被连接的手牌会对所有角色可见，当任意角色一张被连接的牌因使用、打出或弃置离开其手牌区后，" ..
  "所有角色依次弃置其余被连接的牌（此操作不会重复触发该规则的弃置）。当连接的牌再次被连接或离开对应区域后，将重置为正常状态。",
  ["@@connected-inhand"] = "连接",
}

require 'packages.utility.mobile_util'

require 'packages.utility.aux_events.joint_pindian'
require 'packages.utility.aux_events.discussion'
require 'packages.utility.aux_events.delayed_pindian'
require 'packages.utility.aux_events.general_appear'
require 'packages.utility.aux_events.present'

return Utility
