-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- 主機： 127.0.0.1
-- 產生時間： 2023-06-15 10:24:40
-- 伺服器版本： 10.4.28-MariaDB
-- PHP 版本： 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- 資料庫： `addressbook`
--

DELIMITER $$
--
-- 程序
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `buy1` (`mypid` INT)   BEGIN
	DECLARE n int DEFAULT 0;
    SELECT quantity into n FROM product WHERE pid=mypid;
    do sleep(5);
   
    if n >0 THEN
    	UPDATE product set quantity=quantity-1 WHERE pid=mypid;
        do sleep(5);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `buy2` (`mypid` INT)   BEGIN
	DECLARE n int DEFAULT 0;
    
    START TRANSACTION;
        UPDATE product set quantity=quantity-1 WHERE pid=mypid;
        do sleep(5);
        SELECT quantity into n FROM product WHERE pid=mypid;
        do sleep(5);   
        if n > -1 THEN
            COMMIT;
            do sleep(5);
        else 
            ROLLBACK;
            do sleep(5);
        END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `find` (`y` INT)   BEGIN
     SELECT * FROM(
        SELECT quarter(dd)as quarter,sum(fee) as sum_fee
        FROM bill
        WHERE year(dd)=y
        GROUP BY quarter
        UNION ALL
        SELECT 1,0
        UNION ALL
        SELECT 2,0
        UNION ALL
        SELECT 3,0
        UNION ALL
        SELECT 4,0
    )as a
    GROUP by quarter;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `login` (IN `myuid` VARCHAR(51), IN `mypwd` VARCHAR(20))   BEGIN
	DECLARE n int DEFAULT 0;
    SELECT COUNT(*)INTO n FROM userinfo WHERE uid=myuid and pwd = mypwd;
    IF n=1 THEN
    	SELECT 'welcome.php' as result;
    else 
    	SELECT 'error.html'as result;
      
    END IF ;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `queryUserInfo` (`myuid` VARCHAR(50), `nullDefault` VARCHAR(50))   BEGIN
select UserInfo.uid, ifnull(cname, '無') as cname, ifnull(address, '無') as address, ifnull(tel, '無') as tel
from UserInfo left join Live
    on UserInfo.uid  = Live.uid
    left join House
    on live.hid = House.hid
    left join phone
    on Phone.hid = House.hid
    where UserInfo.uid = myuid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `swap` (INOUT `a` INT, INOUT `b` INT)   BEGIN
	DECLARE tmp int;
    set tmp=a;
    set a=b;
    set b=tmp;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `test` ()   BEGIN	
	DECLARE error bool DEFAULT false;
    declare CONTINUE handler for SQLEXCEPTION set error = true;
    
    START TRANSACTION;
        UPDATE userinfo set cname ='王大毛' WHERE uid='A03';
        INSERT into userinfo (uid) VALUES('A01');
        if error THEN
        	ROLLBACK;
            SELECT 'ERROR' as state;
        ELSE
        	commit;
            SELECT 'OK' as state;
        end if;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `uidregister` (`myuid` VARCHAR(50), `mypwd` VARCHAR(50))   BEGIN
    DECLARE uid_count INT;
    
    -- 查询符合条件的记录数量
    SELECT COUNT(*) INTO uid_count FROM UserInfo WHERE uid = myuid;
    
    -- 判断 uid_count 的值
    IF uid_count > 0 THEN
        SELECT 'UID存在' AS result;
    ELSE
        -- 在这里执行插入或其他操作，表示 uid 不存在的情况
        SELECT '成功註冊' AS result;
    END IF;
    
END$$

--
-- 函式
--
CREATE DEFINER=`root`@`localhost` FUNCTION `maxfee` () RETURNS INT(11)  BEGIN
    DECLARE VALUE int;
    SELECT max(fee) into VALUE FROM bill;
    RETURN VALUE;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `myadd` (`a` INT, `b` INT) RETURNS INT(11)  BEGIN
    RETURN a+b;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `totalfee` () RETURNS INT(11)  BEGIN
	-- end of found
	declare EOF bool DEFAULT false;
    declare n int;
    DECLARE total int DEFAULT 0;
    declare c cursor for select fee from Bill;
    -- 如果cursor找不到資料，continue做EOF等於true
    declare continue handler for not found set EOF= true;
    
    OPEN c;    
    -- fetch 往下移動一筆，並把c指向的資料放入c_fee，fetch再寫一次
    fetch c into n;
    while !EOF do
        set total = total + n;
        fetch c into n;
    end while;    
    CLOSE c;
	return total;
    
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `updateAddress` () RETURNS INT(11)  BEGIN
    DECLARE modifiedCount INT DEFAULT 0;
    DECLARE curAddress VARCHAR(255);
    DECLARE newAddress VARCHAR(255);

    DECLARE curCursor CURSOR FOR SELECT address FROM new_house;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET curAddress = NULL;

    OPEN curCursor;
    read_loop: LOOP
        FETCH curCursor INTO curAddress;
        IF curAddress IS NULL THEN
            LEAVE read_loop;
        END IF;

        -- 將地址中的 "縣" 替換為 "市"
        SET newAddress = REPLACE(curAddress, '縣', '市');
        SET newAddress = REPLACE(newAddress, '台', '臺');

        -- 尋找第二個出現的 "市" 的位置
        SET @startIndex = LOCATE('市', newAddress);
        SET @endIndex = LOCATE('市', newAddress, @startIndex + 1);

        -- 如果找到第二個 "市"，並且其前面至少有兩個字，則將其替換為 "區"
        IF @startIndex > 0 AND @endIndex > 0 THEN
            IF @startIndex + 1 < @endIndex - 1 THEN
                SET newAddress = CONCAT(SUBSTRING(newAddress, 1, @endIndex - 1), '區', SUBSTRING(newAddress, @endIndex + 1));
            END IF;
        END IF;
        
        -- 更新地址
        UPDATE new_house SET address = newAddress WHERE address = curAddress;
        SET modifiedCount = modifiedCount + 1;
    END LOOP;
    CLOSE curCursor;

    RETURN modifiedCount;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- 替換檢視表以便查看 `after_house`
-- (請參考以下實際畫面)
--
CREATE TABLE `after_house` (
`hid` int(11)
,`address` varchar(200)
);

-- --------------------------------------------------------

--
-- 資料表結構 `bill`
--

CREATE TABLE `bill` (
  `tel` varchar(20) NOT NULL,
  `fee` int(11) DEFAULT NULL,
  `dd` datetime NOT NULL,
  `hid` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- 傾印資料表的資料 `bill`
--

INSERT INTO `bill` (`tel`, `fee`, `dd`, `hid`) VALUES
('1111', 300, '2019-01-01 00:00:00', 1),
('1111', 700, '2019-02-01 00:00:00', 1),
('1111', 400, '2019-11-01 13:47:54', 1),
('1111', 500, '2019-12-01 13:47:54', 1),
('1112', 700, '2019-01-01 00:00:00', 1),
('1112', 450, '2019-02-01 00:00:00', 1),
('1112', 200, '2019-03-01 00:00:00', 1),
('2222', 150, '2019-01-01 00:00:00', 2),
('2222', 400, '2019-02-01 00:00:00', 2),
('2222', 300, '2019-03-01 00:00:00', 2),
('3333', 500, '2019-04-01 00:00:00', 3),
('3333', 850, '2023-06-02 08:10:21', NULL);

-- --------------------------------------------------------

--
-- 資料表結構 `house`
--

CREATE TABLE `house` (
  `hid` int(11) NOT NULL,
  `address` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- 傾印資料表的資料 `house`
--

INSERT INTO `house` (`hid`, `address`) VALUES
(1, '台北市南京東路1號'),
(2, '新竹市光復北路1號'),
(3, '台中市公益路二段51號'),
(4, '高雄市五福路3號'),
(5, '台中縣大里市中山路1號'),
(6, '台中市台中路20號'),
(7, '台中縣豐原市中山路10號');

-- --------------------------------------------------------

--
-- 資料表結構 `live`
--

CREATE TABLE `live` (
  `uid` varchar(20) NOT NULL,
  `hid` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- 傾印資料表的資料 `live`
--

INSERT INTO `live` (`uid`, `hid`) VALUES
('A01', 1),
('A01', 3),
('A02', 1),
('A03', 1);

-- --------------------------------------------------------

--
-- 資料表結構 `log`
--

CREATE TABLE `log` (
  `id` int(11) NOT NULL,
  `body` varchar(200) NOT NULL,
  `dd` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- 傾印資料表的資料 `log`
--

INSERT INTO `log` (`id`, `body`, `dd`) VALUES
(1, '已新增一筆`new.uid`的資料', '2023-06-06 15:49:51'),
(3, '已新增一筆A09的資料', '2023-06-06 16:18:01'),
(4, '已刪除一筆A09的資料', '2023-06-06 16:19:49'),
(5, '已把舊姓名:朱小妹，更新為朱小梅', '2023-06-07 09:22:14'),
(6, '已把舊姓名:David，更新為Amy', '2023-06-07 09:38:20'),
(7, '將朱小梅的姓名:朱小梅，更新為朱小妹', '2023-06-07 09:48:13'),
(8, '將王大明的姓名:王大明，更新為王大明', '2023-06-07 09:49:30'),
(9, '將A05的姓名:null，更新為David', '2023-06-07 09:51:43'),
(11, '將A02的姓名:李大媽，更新為李大媽', '2023-06-07 10:03:39'),
(12, '將A04的姓名:朱小妹，更新為朱小妹', '2023-06-07 10:31:09'),
(13, '將A04的姓名:朱小妹，更新為朱小妹', '2023-06-07 10:32:07'),
(14, '將A02的姓名:李大媽，更新為李大媽', '2023-06-07 10:32:42'),
(16, '將A01的姓名:王大明，更新為王大明', '2023-06-07 10:35:53'),
(17, '將A02的姓名:李大媽，更新為李大媽', '2023-06-07 10:35:53'),
(18, '將A04的姓名:朱小妹，更新為朱小妹', '2023-06-07 10:35:53'),
(19, '將A05的姓名:David，更新為David', '2023-06-07 10:35:53'),
(20, '將A06的姓名:，更新為', '2023-06-07 10:35:53'),
(21, '將A07的姓名:李多喜，更新為李多喜', '2023-06-07 10:35:53'),
(22, '將Z01的姓名:David，更新為David', '2023-06-07 10:35:53'),
(23, '已新增一筆A03的資料', '2023-06-08 13:47:34'),
(24, '將A03的姓名:王大明，更新為王小毛', '2023-06-08 13:49:22'),
(26, '已新增一筆Z02的資料', '2023-06-08 15:37:07'),
(27, '將A02的姓名:李大媽，更新為李大媽', '2023-06-14 14:47:10'),
(28, '將A01的姓名:王大明，更新為王大明', '2023-06-14 14:56:15'),
(29, '將A01的姓名:王大明，更新為New Value', '2023-06-15 15:27:00'),
(30, '將A01的姓名:New Value，更新為王大明', '2023-06-15 15:36:59'),
(31, '將A01的姓名:王大明，更新為王小明', '2023-06-15 15:38:56'),
(32, '將A01的姓名:王小明，更新為王大明', '2023-06-15 15:39:04'),
(33, '將A01的姓名:王大明，更新為王小明', '2023-06-15 15:41:33'),
(34, '將A01的姓名:王小明，更新為王大明', '2023-06-15 15:41:44'),
(35, '將A01的姓名:王大明，更新為王小明', '2023-06-15 15:42:09'),
(36, '將A01的姓名:王小明，更新為王大明', '2023-06-15 15:44:10'),
(37, '將A01的姓名:王大明，更新為王小明', '2023-06-15 15:44:59'),
(38, '將A01的姓名:王小明，更新為王大明', '2023-06-15 15:45:08'),
(39, '將A01的姓名:王大明，更新為王明', '2023-06-15 15:48:46'),
(40, '將A01的姓名:王明，更新為王大明', '2023-06-15 15:49:24'),
(41, '將A01的姓名:王大明，更新為王大明', '2023-06-15 15:49:47'),
(42, '將A01的姓名:王大明，更新為王大明', '2023-06-15 15:59:31'),
(43, '將A01的姓名:王大明，更新為王大明', '2023-06-15 16:00:01'),
(44, '將A01的姓名:王大明，更新為王大明', '2023-06-15 16:01:16'),
(45, '將A01的姓名:王大明，更新為王大明', '2023-06-15 16:01:28'),
(46, '將A01的姓名:王大明，更新為王大明', '2023-06-15 16:02:57'),
(47, '將A01的姓名:王大明，更新為王大明', '2023-06-15 16:06:27'),
(48, '將A01的姓名:王大明，更新為王大明', '2023-06-15 16:06:46'),
(49, '將A01的姓名:王大明，更新為王大明', '2023-06-15 16:08:15'),
(50, '將A01的姓名:王大明，更新為王大明', '2023-06-15 16:12:33'),
(51, '將A01的姓名:王大明，更新為王大明', '2023-06-15 16:12:45'),
(52, '將A01的姓名:王大明，更新為王大明', '2023-06-15 16:13:13'),
(53, '將A01的姓名:王大明，更新為王大明', '2023-06-15 16:16:02'),
(54, '將A01的姓名:王大明，更新為王大明', '2023-06-15 16:16:20'),
(55, '將A01的姓名:王大明，更新為王大明', '2023-06-15 16:16:31'),
(56, '將A01的姓名:王大明，更新為王大明', '2023-06-15 16:20:42'),
(57, '將A01的姓名:王大明，更新為王大明', '2023-06-15 16:21:37'),
(58, '將A01的姓名:王大明，更新為王大明2', '2023-06-15 16:22:10');

-- --------------------------------------------------------

--
-- 資料表結構 `new_house`
--

CREATE TABLE `new_house` (
  `hid` int(11) NOT NULL,
  `address` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- 傾印資料表的資料 `new_house`
--

INSERT INTO `new_house` (`hid`, `address`) VALUES
(1, '臺北市南京東路1號'),
(2, '新竹市光復北路1號'),
(3, '臺中市公益路二段51號'),
(4, '高雄市五福路3號'),
(5, '臺中市大里區中山路1號'),
(6, '臺中市臺中路20號'),
(7, '臺中市豐原區中山路10號'),
(8, '臺中市大里區市政路123號');

-- --------------------------------------------------------

--
-- 資料表結構 `new_table`
--

CREATE TABLE `new_table` (
  `uid` varchar(20) NOT NULL,
  `cname` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- 資料表結構 `phone`
--

CREATE TABLE `phone` (
  `tel` varchar(20) NOT NULL,
  `hid` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- 傾印資料表的資料 `phone`
--

INSERT INTO `phone` (`tel`, `hid`) VALUES
('1111', 1),
('1112', 1),
('2222', 2),
('3333', 3);

-- --------------------------------------------------------

--
-- 資料表結構 `product`
--

CREATE TABLE `product` (
  `pid` int(11) NOT NULL,
  `name` varchar(20) NOT NULL,
  `quantity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- 傾印資料表的資料 `product`
--

INSERT INTO `product` (`pid`, `name`, `quantity`) VALUES
(1, '鉛筆', 0);

-- --------------------------------------------------------

--
-- 資料表結構 `userinfo`
--

CREATE TABLE `userinfo` (
  `uid` varchar(20) NOT NULL,
  `cname` varchar(45) DEFAULT NULL,
  `birthday` datetime DEFAULT NULL,
  `pwd` varchar(20) DEFAULT NULL,
  `image` mediumblob DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- 傾印資料表的資料 `userinfo`
--

INSERT INTO `userinfo` (`uid`, `cname`, `birthday`, `pwd`, `image`) VALUES
('A01', '王大明2', '2013-08-06 00:00:00', '1234', ''),
('A02', '李大媽', '2013-03-06 00:00:00', '6789', 0xffd8ffe000104a46494600010100000100010000ffdb008400090607121312121212101015151215151517151015150f0f15171617171715151515181e2921181b261c1715223222262a2c2f2f2f17203445342e38292e2f2c010a0a0a0e0d0e151010152c1e1e1e2c2f2e2e2c2c2e2c2c3130302e2f2e2c2e2e2c2c2c2e302c2f2c2c2e2c2e2e2c2e2c2c2c2e2c2e2c2e2e2e2e2e2c2e2e2e2effc000110800e100e103012200021101031101ffc4001b00000105010100000000000000000000000200010304050607ffc40042100001030203030906050302050500000001000203041112213105134106225161718191b1c1143252a1d1f0071523427233629253e11682a2c2f13443446374ffc4001a010101000301010000000000000000000000010304050206ffc400311100020200050203070207000000000000000102110304213141125161718105132232a1c1f091d114334282b1e1f1ffda000c03010002110311003f00f306a270ba1704ec2a14969dc46aadaa415881fc101210a07b6cac2191b740caae0ab54687b95b2a3959740563a04d6f552884946da7e9280aeefdbde98856f74dbf5f6a4e0d1c3d5014edaa6c07a0abc74ba06bafdc80a4633d05098cf4156b1e764d23ac42a0a65a7a0a1576475933c8d48405349597c038782af84f41420c92310bbe077814629643ff00b6ff00f121010a70ac0a097fd33f21ea8dbb325f87c48faa14acd5669e6b1bf8a91bb2a4fedf153336449f133c4fd10131cc0210b82b54bb35c322f163d44ab8fd8fc71fcbcb35018f6496bfe503e27782480c361ba4b7a8a06616f3197c233201e0acee5bc1adf0080e68152b5a7a0f815d1342205018d146f23dc7781528a493e0778596bb1d6564142d9cec9b3a4d701f103d507e5b2740ef2174a4281cd42183f95c99e6d1de7e88a0d96fceee6fccada212080c6fc8ce3c5bc1fe37f5533b6303abcf70b7aad4053a03319b1d805b13fe5f44e364463e2f1ff65a253140677e5717c27c4a7fcbe2f8077927d55d728ca02b1a28ff00d36778ba714ccd3033c029ca8d00e2319580cba9453b73bf4a9829268f2b2028a4924a81249248074e12012401b4f056a0938154d10720343ef54954de75a4a022a6f719fc5be415963957a7cd8cfe2df246d2a82721205302910a00c29627f055c23080b685edba689d74680ae9948f6a8d0093a6490ac74c9248404a8dca52a370404680a32a5822b9cd00a18f89ee457bdfa91cd2d8816ef4d64067cccb140ae54b32550054824ac914442019a809cd4a02878a00c1440a689b7ba45b640177249ae920151bb98cfe2df20a6705568cf319fc5be415b6942898e532ae42918e4012205314c0a8095ae53937170abb14ad36ec2803e19a84a9643c144801299394c80574e0a14ae80242539721720106a712d88e8493d90161cc0755190a461c90ca1011382a4596babc543335015484e4291cdd3b9081eaa81055c2b6ed0f7aa810858a70a6c22e6ff7920a452b5bef77a852be0ea494d83ad25419f4dee33f8b7c82b31b956a6f719fc5be414ad2842d917518471393bdaa142694f8544d2ac61402732c9db9a024e8a668b201142512128012992298a0052ba1320bd93a000a946881c53c4500411042538404d1146f19285a558080810b823213202b16e899a33533db9f8a00d3d050012e85540ae4ec36d0f055844ef84f82a0b74c3244c1cd3dfea940db04e0736df7aa806c092b164901894dee33f8b7c8295454dee33f8b7c94aa9038dd656c66a895669dfc101208af7498e3a291dd215bacd93242c8249708152d2f886205ee68009761d40e737c42852b34224064e758823b78abf5db16667b2b807482a58e903636b9dbb68735a3786d6188bb2ec280a2e781c54733ec2ebb09ff000e2a8ba9ac096bdac74c498d8612e231b002e38cb45f3191b2cedb9c9cdc56b291cebb257c618eb874858f73585ce0059a7162b0ea0a839f6bae3b5430348bdd77d5bc90a66c350f8cd5de17b636ba53008deedfee1c5ac65df60e0e1ce0dbdb2badd6f21e923616ba299ee6c7500c85d130b8dd981e03df66b802434dad91c5c2e21e4ce60bdd22fe85bf37258c9b525a084c86389f182f7105cd618a29247b88006af2075e10ba37ec78c6d089fecb4fbba86ca1b4b34661dc410101d5b365fbb807069fd46039e2200f3d7a6695ea705444c6890d2ece8a36c52d4c87d9497c54c0b853c8462043e5c370c22f66bf3bb6c798fc3da696aa5ab79731ac91af74d16e778e74733dceddc4dd1845ac3336e836b8039f968a50f0c745287917c058e125ad7be122f6b027b94afd99306c6e313ed2b0cacc231e28db8439f66dc868c4dccdb50bd42ae82aa69e1958faca263def966691485ed73236c51873b78e05a5a090db3c024936c952e52d389682b480e84535390041531ccf9a0841788e6e69dde221d70d3770c8b8e880f3ca1d9f34c6d1432487ff00ada5c0769190ef5a7b4793f514fb912b5a1f35c3236b8493659fb8dcf4be97d16d7e1e5dcf8236ed5746778e90d0c6c692f0db5dcf93de6b08032c8779ced0a5a366d9698e495f552d538cad7c2f8d8c66e6475c4ae659c06160167678901cb4db19e2965ab73b088a664263208931b9cc6f75b18f02ac6cae4f36480544b594f4ec74bb9699b22e7dae1a3317245f2ea2b4b6abefb32bcf4ed9987f8ce3e8b479294d56e8590d3d4ec770169cb266beaaaa3320c8b98d7b4308171e39a031bfe168a392b85455963287718e46c2e9316f9b8800c049caed195ef7547953b322a6f65314af91b53099839eddd9c24b30f34e62e1d7b1cc2f42d8f5b4cfda123a9769523dd335a67859fab2ccf89bbb0f6bb1d980370f35a0f12b8afc40731d503154d64f207b9819514a6963862e738e19374c120c41a01b9b837cf5407357caea3a79715f2b594d64cc8c0d02850716764ef75916148b6e801c6922c0124062537b8cfe2df252a8e987319fc5be414d6548094f7b68938689ec80f4ae405239fb3ea25869a966a81501acf6a030018622ebbad7000738d8715af34fb605b14db06000586212b8b474025e0772c1e4a53c4fd8f50d9a927ab63ab01dc53df78e21b0e13a8e682d04e69a9763c371bae49bf519d44ac8ac2fae789015ff0013e4036a024070653531c24d9ae3bca825bdf905d27293941b88768b238608fd8e969220e0dbe196a0b808af973581d1b80cbdebae47f1418e76d62181c5c62a76b437dec577e10debb90ba4dbd5a1d0474b2d5d3b36942ea5a8782d6b629a50fb410caed0bafbb26c4681d60d405bd9d353cf152ccd9b67cc2860a613be563eb2a63736c722d7f35f769b1209c42eb8b8a689db6f7ef8e431cd54d733146f89efc8322700f0d3844801bf51d57693f29a48e9f6838543a634429a37c913628c198bed50d8460200cdade762b1b8e0b91ad9a2936cc123b683268af0482495d1b4431873a56c0fc2006b8389f7b3e7b6e80ee36ad4fb3c552f9db118c18d8e1151cb1bf1cd53fa723649652d943647bdf603520dc6579a49ce3c0ec6c91c48c006ce8dce3258b86173dee25d669ebb05c7ed1e5252d4d1cecdfd2d3fb555c6f8817c9513e18ea77ae9e68c8fd3638331068c862d6e6cb51dcb4a013b663b471110e07b22a091dbc9ed6df6f8458ac05acd0ee0334061ec9ad60daf592cb553d3b18e76f1cec0e966dceee37c64c4db005ccfda2f85bc092574357b4e074d4f56da8646f74b336492ba19767c13d2865f738a56fbad2f8f0df5388d8f3970bb3b6d454f26d092392a267cf04cc8667c42173e69c07be57c79606890b869c15eabe58c55124aeada292588bd8f8618a50303c47bb7c8f93984e2686f37300df5d501d7c8f6533691f36d2d9ec8cb676c789aea86cf4cfcd90038c6f238c3a3b3b32708d2eebf9f7242baa8de1818cbd635ad95985c5e18039cf6c7778c2434bb3713a2daade5c533c42dfc9627b69d859109ea7dc69c370008dd7f71ba9e0b1761eda7d2d48ab10b1ee0642220f31c6049880687e039343ac39b9e1e080f4eadd8e087cac8bd9c6201b1329f673660308bbc3e52e6daf739d8f52e6397a2a0c6268dfbba77c4da49432485cf9dc71921e2205a0589b8046ba2e65db7dce7170d9bb0da492eb9a2df49726f72f73c5cf5d823da7ca2aa9e264127b2889b2092d041b838802068f22d9f45fad01d4fe1f57d3c0ea763087d5564ae6385bfa10c60b9c4ff00221b6e9c5fd8553afe56d4bebd844103df495557130df7724c37b2430c4e758e10d1c73b9b699df96a3aa9227892279648dbe17b435ce6dc11701c08d09d421639d72e2f717b9ee91cf360f2f7b8bdcfcac012e24e5640765b6e965836661a9608e5a9da4f9b05c3bfa9bc948046a058f82dfe49cae936786b29a8ace9b732b65fd38a48b08de3de2c71c86f6c2722bccb9cf707c924d2bda080ea8964a87341d434c8e36bd869d0a3aaa66bed8da1c06603b9cd07a434e57eb42d1e9d1eea076d330bf67536e6a69d90bea9ac65344df66a67383434b6d9b9d6008ccae6ff001176c7b455b23654b25860858eb42e6ba2df3cbc3cb8b49bb835adb03a071e95c8b2922186d14630ded66816beb6cb25705316b43b038349b075acc273360789c8f821014924ea1e9a6b71924e92106493a480c5a61cc67f16f929404a98735bd4d6f9052e15410c9c11593c8330880f34068d0f296b2180d3c1308a32f321746db541395c6326c1b90cb0dfad577ed8ab73ae6bab8e86c6a66c3707e10ec3dd6573935b20cf273b28999c8ed05b5c37e93f2172b529364ecfa998b69ea89b341c1082f00039b8c8eb8cc90bdc70e52568d2c7cfe0e0cdc257a2b74ad2f3ad9fe339aabaa96690cb3caf9647000bdf841b34580b300000ec55decd49b92e71739cf25ee738eae738e64f5953d63a212c8d8a4c6c8dce6879b00ec36c4458e601b8bf1b5d3514ec3342dfd279748d6063ddcd717bac2f6ced73f25e6b5a365cd7475f157db8be76f521f676d83437219868f76e33bd949b9362ec2ec3c5d63bbb9e976975e85b261ddbaa1b8695a591e629e9e6be62e01793faa3fb5b9a789ce14630b24b877bb4f45b87ebc29a6397695b0b2de270e5edd574b0bb6ef8f44fef679b93964ad53d04cf00b2099c0e8591bdcd3c35b596872eea9f8a39e4a79e18f08846f775773eee79b3637bad90e365b9b1d9512d0519a49305e62e909c209871cb880b839df0af0b0ae6e3d8dac4f693596c3c68a49ca55abd16ef56bcbea73716c0aa71204125c5ae086b08be9a90ad45c92ab3ac6d1fc9ecf4257475b4e7db2599d532b6281b093053ba532bddcf2dc71b45cb4f002f7c246562b3f62d4ba49a4ac9e1da8c7892411536ea610eef006b1d86c1988826f73ef5fa9645811be7f39fcd4d097b631fa6d74ad2fe596f5f2eebf5d9697ae872b3c458f7c6eb5d8e2d36cc5db91b15a7b4365eea0a794bafbfd1a1b6c37617e66f9ae425db6e3248e31805f2caf209d0bdee75bbaf6ee5e8f59b5e962a1d9cfaa824931c4cc0d8c0384ee8171389edcac5618454babf393a79acce2e0fb8d1b727aa8a4dbf87657e3d9a32b933b3995136ede5e06ecbff004c806e0b40d41e9541fabc0d1b24ac1c72648e68f905a74dcbea289d7828240eb5af6858eb745c389e85c77e67212e37c377c8fb58123138bad7b75a93514924d37e064cbcf1e78d394e12846952977d6d9dcd2d353329054cec9df797778612db9be960e23cd5d7fb1c606f206c25cd0e0dabaa8627107436129c9643240ed9549bd337ea56e03b8dd898ddd30606e3b3750dd785d742dda0212e63ea1a642c0c0caba8a3865665958431975f3e3896ce1c152d16cb83859ccd62fbc9a8e24ad4e4aba9a54a92aa6b9bbf4238dec6d44307b0d2da501d8db299acd75ec6ce8b3d3a562ed268f6999a000d12e101a2c00c2cc801d775a6d27dae89ee635ee9f1e195b572d48ddc6c2eb0618d8d2097eb65caed618b684c3a6aedff005b5be8bc632f87d7ec6e7b2e4fdea93bfe5b6edb77f1d5ab6fb571b1dbd553b1b2ba18367c5296471c85cf91ac68de19034738127fa655c22a0407153d046e69186396474900171ce2f0c184e6fc834f0cf3cb36ba9a196bab77ac89cd8a921369b38410e9dd770e22c8a99b18a076114584c99fb3d1493539376fff00181c4f76439dd8782d84926fd7b1c49ce73842ededabea7ab5e326affb53de8cbdb7b56610bd8faad91cfb465949bc92a2ce21a70f3c5add387258c6b63f8c7ccad4e5cb07b3d164dbb8b89222f65bfe9b73319cd9ae8745c7596a63bf8e8fa4f63422b2dd4bfa9bfa69f6fa9b676847f11f0284ed28ff00bbc16459359603ac6b7e66ce87f80faa4b26c92168aa368c801008b0cb4e809ff3097e3e1d0dfa2aa46bde8f8f8fa21069ab64c439eed3865c52150f3abdff00e47a14130e70ecf5463d7d101eabb3b6c47f951961a22e6b6d19a7377ef0b8c6d92e6ce320e713722e6cacd06d29450c9511ecd6c52e2c2c81913aee189ad0e73435a6d9b8e9a05c5f237696d021b4b47ba0d07139ee88bdacc5992f92f61d4355dfd26dd0eae6d135fbc3153b9f33ec05e4058c0dcb20732481a5c0e95bd873ea4b5ae365bf87e5781f1f9dcbfb8c4945c54b572f9a4df4ae24bc7bfccef4e0cd7d655bf66ed075540c8488a60c6b039976184e64171e24f42f3ae4e18054b1d3cf2c2180b98f81a1ee120b61162d76b736cb55bd0435f5d53353be7ac8e1719c5dcd7b69f08710d8cdac0822c355cac54ae3386b19249bb92dfa2c74970c7db10005ec6d7583126df4bd5d77e7f43ab92cbc211c784a4a3d4936a17f0aaeed7ddf367b26da97033718aa407004cfed304326b98c72bb10396ad6dac722386551d543208a977b048cde837936a6f6b09b9cb0c60e3d4f34bacaef29a685acf6b94889a00680fa780d53b3279bbecf8fbb6beb92a1c99dbb4f2b811b4276b838810d48a3a5de6595b771824763af92dc6d7551f3d0c39fbaf7918edbb4a5a3f3d8e3ff0011f693dd52ea50236c34ae6eed91b70e6e8d8e25dd36c440b5b55d45151c6fd99b3379571533639193974ce0c6c96321dddcb86b7ebd345c87e21d0cacac9249435a2721cc0d7b6424358d61c867c3a38abfb584306c98a373a19e7a93761c42a053b6c3108cdc86d859b97ee71e85ab7539b7dbfe1dcc4c353cae530f09eadadb5d69f53e568db6f5fdceba9ab9924db51f0555382f8a9e38e5de30c42411cd637cc1b170beaa3e4ed598a57beab6dd25434308ddb5f1d986ed25e403c00234e2b9cdaf3ecf8ebb674b0b68cc61a04ed8c44e8985c6d8a4b658862273cf99d48f66729e921aeadcc3a8ea839c4eedd8779879c036d721c4c834b66d59bad296af9eefcffd1cf7949cf09bc38b69c13f9537f0d4293a74da5d5a55ec700d697101a2ee79b003525c7203bcaf5be547289941ecd4becb14ee6400dde40c005a316e63b5c27a3dd5e7bc9dda14d0573667b25740c7bcb2ff00d560b9dd3dcdcc38b470bf5f0b28f6d6d7755d44b3b85b1901add7031b931bdb6ccf592b5a13e88b69eaceee632ffc563c14e0fa229bed6de95a6aa92d7f6dfd17927cb292a6a443ecd044d2c7baec712ee68b8fda02e076e3af5957ff00e9a8f94af1e8a7e4b6d71493efdd1bde031ccc31900ddd6cee7bd52ac9448f926b61de4b2c9626e407bdce009e9174962394126f5b265b251c0cdca5870e987455f8ddf36f83b4dd1fcbf65800902be391d841759ad7cc4936e16e2b73da30c933a374c43e7df8c14db41e2fba8e3b3c4403641fa77ccdb3ea5c5d272c2aa2823a78374c0cbf3edbc91d7249167734667e484f293681f7ab65ff009590b3c98b2c71a292f25c781cfc5f6563e2ce6f457293d5f0ddec93ff0027694d4521a8d9c5b1cc594d0ccd7c8f88d38c4f6b4021921be641e9b2e7b655119b6a482d70caa9a577508a6247fd41a3bd64336dd607e315955717d5e5edcf2fe9b8169f055048fc45fbc7e32e7485e0e07e27124b816dada9d178962c5d69cd9b78190cc43aee51b70714d5f3272b7a2e64fe9a1d8fe754a27a99cd7d442f92574786189b38c305e38c82e89e2c709765f12d8976ac22844cea9af92332e1de36d0d5138bdd166b6c2e2da0c9799b1800000b002c13b9b7b5f86999b0ec08b30d7027ec4c3974beb7a52d6b64aa952edb377ea6e6d5dad49230e08368ba5d18fab9cc8d65c8c46c673c0742c5492586737276ce965b2d1cbc3a2326d78bbfd36a4249249783604924920331fa7df4a5fefe893f4f0f3456f55485794738767aa92d99ecfaa19bdf6f67aa377a203a1aae5ad4ba26d3c2d8699ad606b8d30c2f71b58965ac2307a85c74ac4d8db4a5a69b7b0b835e05aee18c10ed4381d6e403dcab03ce3d812039c7b02f4e726d36f635f0f2b8387094210494b7f1f3bd59d15672df6848d2d33b5a1c08fd28dac701a64e3723b466b0b67ed29a99e1d4f2ba37612dbb6c411d041041ef1aa0b68a19bde08e726edb2c32b8308b8470d24f754b5f3efea4d5550f95e5f2c9248f3fba5717bbb05f41d43255de322a4b28dfeabc99a294524b4a1a4e19936b0cc93603402fa0ea418474046e099c10a4453a7212b2a0608e13623b52b213c101a40dae3c10471dcdaea4819700a919159e5dc08d3c1404919683841cfe68a49437536ba89b073f1dfbb8e964f574f8ed9dac809dce005ce89a294385c1ba67b6e08e916414b0e1045ef7374016f862c37cd3cd3068b941ecfcfc77eeeeb22a8803c58923b1006d75c03c0e6861983b4bf7a28d9600740b208610dbdaf9f4a0627ce038373cfc13cb261174d246d2412731d69e4c24589163d68087db8741f92496e63e9f9a740559343dde6939dafdf04a5d0fdf14c467e0808e43ce69edf3ff007523b87df4a8243ee9ebfa29fa3b7ea800b73bbbd51b473bb8244738758faa26b731fc50017cbc14730cc1525b2fbe94d2f0ed403151bc6bdaa62a370c8f6faa001c3cd396a32dd3b7ea9c8f340424256c91bc26769e0800b2178d14a0792670cda80923791a12884eef88a163723de9cb72ec1e88051d4bfe23f24efa87fc45040dc913db98ed401095d9f38a4d95df11d4f14ed1e6819f5f9a00b1bbe23e25433bcdb53e2ac90a0ad1601015d8e3d2b4236ace882d7685415a4199ec291668a5c399ec48374ec2a022b248ee9201dc323dfe6911c7a0792207e694635fbd7340539db977a999a0ed1e9f54d28c8f65fc128ce56ecf97d8401cbab7bd27792671d3b7cc2371cfb9000467dbfeca39ff006f6fd14aee1dea39f41da8071e9ea865191ed52687bbd504fa77a009e34edf4424668e4e099a35eef240472049e32fbe844ed53cbf7f20800c3f7e0961e737b11e1fbfbec48fbe7a9a80268cbbbcd29726bbc3d11db4ee49c32ef3f54047037249c331de7c54b18e68ec09adceee0806032f1faa68dba7de9ff846fd0f6149a7240270556bce9deae7154b681cc77f9a023a76dc85ac166d18cd69374280886ae3f7a2723c930d1dda89df44006ed24ae92011091c8f879a90a0934f9a002d727ef5ff00ca862390edb7a29fd5427f778faa01de723e3e08ddc108098683b9004f3a76f98433b79bde13bce5de13ca39a7ef42806b69d8529c647b4273ff00694f3e9de1002fe1f7c0a9a8e95f23b0b1a5ce3c0740033cd467895bbc8dff00d41fe0effb101507276aaffd13fe4cfaa693939557fe89d3e2674dfa7a97b3ecad9903e16b880e710ec5cf6b733763466eb820ba23a798b8ec8a1a673662ec0eb492341924c030b5b76602c27524026e741d8a90f1bff87aabfd13afc4ce8ed41ff0ed55ddfa27a3de67575af5ca4d9b189f039f89ad9c4406579010e2e26c720034663a422d81b26393de25e1ec85edb737373887b4db304163c76745c100793bb60548b9dc9c8702d27c0159929c8f679af6be52d03627b03598039aecaf71cd3c0ebc46abc4ea4db2e93f20a147e007626666e77779291da8514233776a01e4191eb207cd181af6a8ddc3b47d54a3ebe680669cd50ae3ce57dbaacfaa3cf2a80e8867dcb499a2cfa219abe3450110d0f6faa95deaa21ee8eb7290ebf7d0801c2124781242d001d71926769e3e2a0a73636e0ac9e1da842106f648b79c3ac108dadb771b7d3e485eecdbd5ea8006680a603d7cd26e9644785be2400bc587879a37fbaeec4d2e9fe3e694deebbaca01c643c534a74ed093fea99fc3b7c900e4e5f7d4b536057b60971bc122c5a70e645ec6f6ee5933295f9203b8672c61b61c73dac05ac6c0620fb017cb9c01cb88088f2da304fead40e75f8ea5c1ee3aea5cd69bff00685c244dd7efa146e19f6b8fc9507a0c5cb289aec62498388c38b0ddd600002e4e59347828e9395d0340c0e99b983cd05b7b5ed7b1cecb88b65de7d50c42cd6f6203bc9f9651385dce99e5b8ac1c3a7336b9cae42e06490e203a75f1457cbb6e808e7f600a026073f051d3e84f49289dc4a68720100fc7c7d022275411f0fbeb45ea80262cc9cddc7b56a3464b21f993da5505ca06ea55d768aad2b720ad3f8f72808ddfb475a90a07eadef4ee76bd9ea806c2524f8bad2405472b51e9e09248073fbbb4790509d47df0492400c7f7e2987eded1e49248039f4ff1f34d3fbbde92480677d7cc247f6f69f24924029be88dfe9e899240133d7d103b51dae4924048ed3fcbd526e8dee4924045d1d8937df3dde41249006efddde986812490071e83ef82478249200dba771f4591d3da924a834a97dd1da3cd4afe3ff2f9a49280677bc3bd31d3c3d124900c9249203fffd9),
('A03', '王小毛', '2023-06-08 13:47:09', NULL, NULL),
('A04', '朱小妹', '2013-03-06 00:00:00', NULL, NULL),
('A05', 'David', '2013-03-06 00:00:00', NULL, NULL),
('A06', '', '2013-03-06 00:00:00', NULL, NULL),
('A07', '李多喜', '2013-03-06 00:00:00', NULL, NULL),
('Z01', 'David', '2013-03-06 00:00:00', NULL, NULL),
('Z02', NULL, NULL, NULL, NULL);

--
-- 觸發器 `userinfo`
--
DELIMITER $$
CREATE TRIGGER `aaa` AFTER INSERT ON `userinfo` FOR EACH ROW BEGIN
	INSERT into log(body) VALUES (concat('已新增一筆',new.uid,'的資料'));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `bbb` AFTER DELETE ON `userinfo` FOR EACH ROW BEGIN
	INSERT into log(body) VALUES (concat('已刪除一筆',old.uid,'的資料'));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `ccc` AFTER UPDATE ON `userinfo` FOR EACH ROW BEGIN
	INSERT into log(body) VALUES (
        concat(
            '將',old.uid,
            '的姓名:',
            ifnull(old.cname,'null'),
            '，更新為',
            ifnull(new.cname,'null')
            )
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `ddd` BEFORE UPDATE ON `userinfo` FOR EACH ROW BEGIN
	if @count is null THEN
		set @count =1;
    ELSE
    	set @count=@count+1;
    END if;
    
    if (@count>1) AND (
    	(old.pwd is null AND new.pwd is not null)OR
        (old.pwd is NOT null AND new.pwd is null)OR
        (old.pwd is NOT null AND new.pwd is not null AND old.pwd<>new.pwd)
    )
    THEN
    	SIGNAL SQLSTATE'45001' set MESSAGE_TEXT='無法修改兩筆以上資料';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- 替換檢視表以便查看 `vw_max_fee`
-- (請參考以下實際畫面)
--
CREATE TABLE `vw_max_fee` (
`max_fee` decimal(32,0)
,`tel` varchar(20)
,`sum_fee` decimal(32,0)
);

-- --------------------------------------------------------

--
-- 替換檢視表以便查看 `vw_vacancy_rate`
-- (請參考以下實際畫面)
--
CREATE TABLE `vw_vacancy_rate` (
`空屋率` decimal(24,4)
);

-- --------------------------------------------------------

--
-- 檢視表結構 `after_house`
--
DROP TABLE IF EXISTS `after_house`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `after_house`  AS SELECT `house`.`hid` AS `hid`, `house`.`address` AS `address` FROM `house` ;

-- --------------------------------------------------------

--
-- 檢視表結構 `vw_max_fee`
--
DROP TABLE IF EXISTS `vw_max_fee`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_max_fee`  AS SELECT `maxsf`.`max_fee` AS `max_fee`, `bb`.`tel` AS `tel`, `bb`.`sum_fee` AS `sum_fee` FROM ((select max(`sf`.`sum_fee`) AS `max_fee` from (select sum(`bill`.`fee`) AS `sum_fee` from `bill` group by `bill`.`tel`) `sf`) `maxsf` join (select `bill`.`tel` AS `tel`,sum(`bill`.`fee`) AS `sum_fee` from `bill` group by `bill`.`tel`) `bb`) WHERE `maxsf`.`max_fee` = `bb`.`sum_fee` ;

-- --------------------------------------------------------

--
-- 檢視表結構 `vw_vacancy_rate`
--
DROP TABLE IF EXISTS `vw_vacancy_rate`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_vacancy_rate`  AS SELECT (select count(0) from (select `house`.`address` AS `address`,count(`live`.`uid`) AS `number` from (`house` left join `live` on(`live`.`hid` = `house`.`hid`)) group by `house`.`address`) `a` where `a`.`number` = 0) / (select count(0) from `house`) AS `空屋率` ;

--
-- 已傾印資料表的索引
--

--
-- 資料表索引 `bill`
--
ALTER TABLE `bill`
  ADD PRIMARY KEY (`tel`,`dd`),
  ADD KEY `fee` (`fee`);

--
-- 資料表索引 `house`
--
ALTER TABLE `house`
  ADD PRIMARY KEY (`hid`);

--
-- 資料表索引 `live`
--
ALTER TABLE `live`
  ADD PRIMARY KEY (`uid`,`hid`);

--
-- 資料表索引 `log`
--
ALTER TABLE `log`
  ADD PRIMARY KEY (`id`);

--
-- 資料表索引 `new_house`
--
ALTER TABLE `new_house`
  ADD PRIMARY KEY (`hid`);

--
-- 資料表索引 `phone`
--
ALTER TABLE `phone`
  ADD PRIMARY KEY (`tel`);

--
-- 資料表索引 `product`
--
ALTER TABLE `product`
  ADD PRIMARY KEY (`pid`);

--
-- 資料表索引 `userinfo`
--
ALTER TABLE `userinfo`
  ADD PRIMARY KEY (`uid`),
  ADD KEY `cname` (`cname`);

--
-- 在傾印的資料表使用自動遞增(AUTO_INCREMENT)
--

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `house`
--
ALTER TABLE `house`
  MODIFY `hid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `log`
--
ALTER TABLE `log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=59;

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `new_house`
--
ALTER TABLE `new_house`
  MODIFY `hid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
