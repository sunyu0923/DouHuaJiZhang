import Foundation

/// 豆花 IP 语句管理器 — 场景化拟人语句系统
enum DouhuaQuoteManager {
    
    /// 场景类型
    enum Scene: String, Sendable {
        case welcome            // 欢迎页
        case login              // 登录
        case loginFailed        // 登录失败
        case loginSuccess       // 登录成功
        case register           // 注册
        case registerSuccess    // 注册成功
        case ledgerHome         // 账本首页
        case recording          // 记录页面
        case recordSuccess      // 记录成功
        case deleteConfirm      // 删除确认
        case editSuccess        // 编辑成功
        case ledgerSwitch       // 切换账本
        case ledgerCreate       // 新建账本
        case statistics         // 统计页面
        case savingsSetup       // 设置攒钱目标
        case savingsProgress    // 攒钱进度
        case savingsExceeded    // 超攒
        case savingsWarning     // 攒钱提醒
        case financeMarket      // 理财行情
        case stockUp            // 涨
        case stockDown          // 跌
        case investmentAdd      // 添加投资
        case investmentMaturity // 投资到期
        case poopRecord         // 拉屎记录
        case poopRecordSuccess  // 拉屎记录成功
        case menstrualRecord    // 月经记录
        case menstrualPrediction // 月经预测提醒
        case menstrualRecordSuccess // 月经记录成功
        case profile            // 个人中心
        case streakCelebration  // 连续记账庆祝
        case badgeUnlocked      // 勋章解锁
        case familyGroup        // 家庭组
        case memberJoined       // 新成员加入
        case settings           // 设置
        case reminder           // 每日提醒
        case evening            // 晚间
        case morning            // 早晨
    }
    
    /// 获取随机语句
    static func randomQuote(for scene: Scene) -> String {
        let quotes = self.quotes(for: scene)
        return quotes.randomElement() ?? "豆花陪你～"
    }
    
    /// 所有场景对应的语句库
    static func quotes(for scene: Scene) -> [String] {
        switch scene {
        case .welcome:
            return [
                "欢迎来到豆花记账，快来和我一起记账吧～",
                "豆花等你好久啦，一起管理钱钱吧～",
                "嘿！今天也要做个精打细算的人哦～",
            ]
        case .login:
            return [
                "请输入你的手机号，豆花帮你守护账号～",
                "输入密码登录吧，豆花在等你哦～",
            ]
        case .loginFailed:
            return [
                "密码不对哦，再试一次～",
                "登录失败啦，检查一下密码？",
                "不对不对，再想想密码是什么～",
            ]
        case .loginSuccess:
            return [
                "欢迎回来！今天也要记得记账呀～",
                "好久不见！豆花想你啦～",
                "登录成功！今天要好好记账哦～",
            ]
        case .register:
            return [
                "请输入你的手机号，豆花帮你守护账号～",
            ]
        case .registerSuccess:
            return [
                "注册成功啦！以后我们一起记账攒狗粮钱吧～",
                "欢迎新朋友！豆花会陪着你记好每一笔～",
            ]
        case .ledgerHome:
            return [
                "今天给豆花攒狗粮钱了吗？",
                "看看今天花了多少钱呀～",
                "又是元气满满的一天！来看看收支吧～",
                "今天的钱花在了什么好地方呀？",
            ]
        case .recording:
            return [
                "我来帮你记账吧～",
                "拿出小本本，记下来～",
                "豆花准备好啦，开始记账吧～",
            ]
        case .recordSuccess:
            return [
                "记账成功啦！豆花记下来咯～",
                "记好啦！你真是个好习惯的人～",
                "又记了一笔，继续保持哦～",
            ]
        case .deleteConfirm:
            return [
                "确定要删除吗？豆花会舍不得的哦",
                "真的要删掉吗？删了就找不回来啦",
            ]
        case .editSuccess:
            return [
                "账单修改好啦，豆花已更新～",
                "修改成功！数据已同步～",
            ]
        case .ledgerSwitch:
            return [
                "要切换账本吗？还是新建一个专属账本呀～",
            ]
        case .ledgerCreate:
            return [
                "新账本建好啦！快开始记账吧～",
            ]
        case .statistics:
            return [
                "原来你这个月花在吃饭上最多呀！",
                "看看你的收支分析吧～",
                "数据不会骗人哦，看看花在哪里最多～",
            ]
        case .savingsSetup:
            return [
                "爸爸妈妈这个月要给豆花攒多少钱呢？",
                "设个攒钱目标，一起努力吧～",
            ]
        case .savingsProgress:
            return [
                "少花点钱，要花超啦！",
                "这个月能顺利攒下钱吗？",
                "太棒啦，已经攒了一半啦！",
                "加油加油，离目标不远啦～",
            ]
        case .savingsExceeded:
            return [
                "超攒啦！可以给豆花买更多零食啦～",
                "太厉害了！攒钱小能手就是你！",
            ]
        case .savingsWarning:
            return [
                "注意啦，这个月花销有点多哦～",
                "悠着点花，不然攒不到钱啦～",
            ]
        case .financeMarket:
            return [
                "看看今天的理财行情怎么样，能不能赚狗粮钱～",
                "市场有风险，投资需谨慎哦～",
            ]
        case .stockUp:
            return [
                "涨啦涨啦！豆花的狗粮钱变多啦～",
                "太好了，又赚了一点点～",
            ]
        case .stockDown:
            return [
                "跌啦跌啦，再等等说不定会涨哦",
                "别着急，市场总会回来的～",
            ]
        case .investmentAdd:
            return [
                "新投资添加好啦，坐等赚钱买狗粮～",
            ]
        case .investmentMaturity:
            return [
                "你的定期存款快到期啦，记得处理哦",
            ]
        case .poopRecord:
            return [
                "今天拉屎了吗？记得记录哦，有益健康～",
                "排便很重要哦，记得记录～",
            ]
        case .poopRecordSuccess:
            return [
                "记录成功啦！豆花也要养成好习惯～",
                "记录好啦，坚持下去哦！",
            ]
        case .menstrualRecord:
            return [
                "记得记录月经时间哦，豆花帮你记着～",
            ]
        case .menstrualPrediction:
            return [
                "下次月经快到啦，记得注意休息哦",
                "豆花提醒你，月经快来了，注意保暖～",
            ]
        case .menstrualRecordSuccess:
            return [
                "记录好啦，下次月经时间豆花已经帮你算好啦",
            ]
        case .profile:
            return [
                "这是你的个人中心哦，看看你已经记账多少天啦～",
            ]
        case .streakCelebration:
            return [
                "太棒啦，已经连续记账好多天，继续加油！",
                "坚持就是胜利！豆花为你骄傲～",
            ]
        case .badgeUnlocked:
            return [
                "恭喜你解锁新勋章！豆花为你骄傲～",
                "又解锁了一个勋章，真厉害！",
            ]
        case .familyGroup:
            return [
                "这是你的家庭账本哦，快邀请家人一起记账吧～",
            ]
        case .memberJoined:
            return [
                "新成员加入啦，以后大家一起记账更方便～",
            ]
        case .settings:
            return [
                "可以在这里设置你的专属功能哦～",
            ]
        case .reminder:
            return [
                "今天还没记账哦，豆花等你一起记～",
            ]
        case .evening:
            return [
                "晚上也要记得记账哦，豆花陪你～",
                "今天辛苦了，记完账早点休息～",
            ]
        case .morning:
            return [
                "早上好！新的一天，从记账开始～",
                "早安～今天也要做个精打细算的人哦",
            ]
        }
    }
    
    /// 根据时间获取问候语
    static func greetingQuote() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:
            return randomQuote(for: .morning)
        case 18..<24:
            return randomQuote(for: .evening)
        default:
            return randomQuote(for: .ledgerHome)
        }
    }
}
