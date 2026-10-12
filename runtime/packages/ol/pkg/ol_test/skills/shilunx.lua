
local shilunx = fk.CreateSkill {
  name = "shilunx",
}

Fk:loadTranslationTable{
  ["shilunx"] = "世论",
  [":shilunx"] = "出牌阶段限一次，你可以进行“评鉴”并获得对应技能（出牌阶段、结束阶段、受到伤害后可以发动并失去一个对应时机的技能）。",

  ["#shilunx"] = "世论：进行一次“评鉴”，获得对应技能！",
  ["#shilunx-ask"] = "世论：请评鉴技能",

  ["$shilunx1"] = "",
  ["$shilunx2"] = "",
}

local pinjian_skills = {
  "zhiheng", "poxi", "ty_ex__fengcheng", "ol_ex__luanwu",
  "luanji", "ol__sanyao", "qice", "zhanjue",
  "huaiyi", "guangu", "mobile__mutao", "ol__shanjia",
  "xiongluan", "jianhe", "pingduan", "manwang",

  --受到伤害
  "yiji", "fangzhu", "ex__jianxiong",
  "kuangshou", "linjie", "ol__guixin",
  "yuce", "huanghan", "huituo",
  "chouce", "liejie", "jieming",

  --结束阶段
  "biyue", "ol__jushou",
  "mozhi", "lizhan", "zhiyan",
  "ranji", "zuilun", "jieli",
  "miji", "fenchao", "ol_ex__zhuiyi", "zhengu",
}

shilunx.pinjian_skills = pinjian_skills

local mapper = {
  --出牌阶段
  zhiheng = "年轻的贤君",    poxi = "江表之力牧",    ty_ex__fengcheng = "乱世谋焚",    ol_ex__luanwu = "洞察先机者",
  luanji = "高贵的名门",    ol__sanyao = "街亭之殇",    qice = "曹魏的谋主",    zhanjue = "血荐轩辕",
  huaiyi = "狡徒悬海",    guangu = "慨然永怀",    mobile__mutao = "坚朴的忠相",    ol__shanjia = "虎豹骑首",
  xiongluan = "北地枪王",    jianhe = "双剑化龙",    pingduan = "瀚海鲸波",    manwang = "勒格诗惹",

  --受到伤害
  yiji = "早终的先知",    fangzhu = "霸业继承者",    ex__jianxiong = "治世之能臣",
  kuangshou = "委蛇两端",    linjie = "无愆垣下",    ol__guixin = "天下归心",
  yuce = "法不容情",    huanghan = "机捷谈笑",    huituo = "天资的明君",
  chouce = "社稷的先驱",    liejie = "慧眼识君",    jieming = "驱虎吞狼",

  --结束阶段
  biyue = "绝世的舞姬",    ol__jushou = "固若金汤",
  mozhi = "归汉的才女",    lizhan = "鬼神之勇",    zhiyan = "狂直之士",
  ranji = "炎志灼心",    zuilun = "临难死义",    jieli = "意前笔启",
  miji = "大义不惜",    fenchao = "烛照官渡",    ol_ex__zhuiyi = "后后嘉荣",    zhengu = "扣弦的豪将",
}

Fk:addMiniGame {
  name = shilunx.name,
  qml_path = "packages/ol/qml/ShiLunxBox",
  default_choice = function(player, data)
    return ""
  end,
}

shilunx:addEffect("active", {
  anim_type = "special",
  prompt = "#shilunx",
  card_num = 0,
  target_num = 0,
  can_use = function (self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local n = room:random(3)
    local skills = room:tableRandomPick(pinjian_skills, n)
    local strs = table.map(skills, function (s)
      return mapper[s]
    end)
    local data_table = {}
    local charPool = table.concat(strs)
    for _, str in ipairs(room:tableRandomPick(pinjian_skills, 3 - n)) do
      charPool = charPool..mapper[str]
    end
    for _, p in ipairs(room.players) do
      data_table[p.id] = {
        words = strs,
        charPool = charPool,
      }
    end
    local req = room:askToMiniGame(room.players, {
      skill_name = shilunx.name,
      game_type = shilunx.name,
      data_table = data_table,
    })
    local result = string.split(req:getResult(player), ",")
    local skill = {}
    for _, s in ipairs(skills) do
      if table.contains(result, mapper[s]) then
        player:clearSkillHistory(s)
        table.insertIfNeed(skill, s)
      end
    end
    skill = table.filter(skill, function (s)
      return not player:hasSkill(s, true)
    end)
    if #skill > 0 then
      local mark = player:getTableMark(shilunx.name)
      table.insertTableIfNeed(mark, skill)
      room:setPlayerMark(player, shilunx.name, mark)
      room:handleAddLoseSkills(player, skill)
    end
  end
})

shilunx:addEffect(fk.AfterSkillEffect, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(player:getTableMark(shilunx.name), data.skill:getSkeleton().name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:removeTableMark(player, shilunx.name, data.skill:getSkeleton().name)
    room:handleAddLoseSkills(player, "-"..data.skill:getSkeleton().name)
  end,
})

return shilunx
