--
-- ER/Studio 8.0 SQL Code Generation
-- Company :      tc
-- Project :      Model2.DM1
-- Author :       tc
--
-- Date Created : Saturday, November 01, 2025 15:53:42
-- Target DBMS : MySQL 5.x
--

-- 
-- TABLE: Discount 
--

CREATE TABLE Discount(
    vipLevel    INT    NOT NULL,
    discount    INT    NOT NULL,
    PRIMARY KEY (vipLevel)
)ENGINE=INNODB
;



-- 
-- TABLE: Furniture 
--

CREATE TABLE Furniture(
    furnitureID      INT            NOT NULL,
    furnitureName    VARCHAR(10)    NOT NULL,
    PRIMARY KEY (furnitureID)
)ENGINE=INNODB
;



-- 
-- TABLE: Furniture_Room 
--

CREATE TABLE Furniture_Room(
    furnitureID    INT,
    roomID         INT
)ENGINE=INNODB
;



-- 
-- TABLE: OrderDetail 
--

CREATE TABLE OrderDetail(
    orderID     INT,
    fromTime    DATE    NOT NULL,
    toTime      DATE    NOT NULL,
    roomID      INT
)ENGINE=INNODB
;



-- 
-- TABLE: Orders 
--

CREATE TABLE Orders(
    orderID      INT     NOT NULL,
    orderTime    DATE    NOT NULL,
    isDirect     INT     NOT NULL,
    userID       INT,
    PRIMARY KEY (orderID)
)ENGINE=INNODB
;



-- 
-- TABLE: Room 
--

CREATE TABLE Room(
    roomID                 INT             NOT NULL,
    isUsed                 INT             NOT NULL,
    isOrdered              INT             NOT NULL,
    floor                  INT             NOT NULL,
    locationDescription    VARCHAR(300),
    roomTypeID             INT,
    PRIMARY KEY (roomID)
)ENGINE=INNODB
;



-- 
-- TABLE: RoomPrice 
--

CREATE TABLE RoomPrice(
    roomTypeID    INT    NOT NULL,
    roomPrice     INT    NOT NULL,
    PRIMARY KEY (roomTypeID)
)ENGINE=INNODB
;



-- 
-- TABLE: User 
--

CREATE TABLE User(
    userID               INT            NOT NULL,
    password             VARCHAR(20)    NOT NULL,
    userName             VARCHAR(10)    NOT NULL,
    telephone            CHAR(11)       NOT NULL,
    Discount_vipLevel    INT,
    PRIMARY KEY (userID)
)ENGINE=INNODB
;



-- 
-- TABLE: Furniture_Room 
--

ALTER TABLE Furniture_Room ADD CONSTRAINT RefRoom2 
    FOREIGN KEY (roomID)
    REFERENCES Room(roomID)
;

ALTER TABLE Furniture_Room ADD CONSTRAINT RefFurniture4 
    FOREIGN KEY (furnitureID)
    REFERENCES Furniture(furnitureID)
;


-- 
-- TABLE: OrderDetail 
--

ALTER TABLE OrderDetail ADD CONSTRAINT RefOrders10 
    FOREIGN KEY (orderID)
    REFERENCES Orders(orderID)
;

ALTER TABLE OrderDetail ADD CONSTRAINT RefRoom24 
    FOREIGN KEY (roomID)
    REFERENCES Room(roomID)
;


-- 
-- TABLE: Orders 
--

ALTER TABLE Orders ADD CONSTRAINT RefUser7 
    FOREIGN KEY (userID)
    REFERENCES User(userID)
;


-- 
-- TABLE: Room 
--

ALTER TABLE Room ADD CONSTRAINT RefRoomPrice1 
    FOREIGN KEY (roomTypeID)
    REFERENCES RoomPrice(roomTypeID)
;


-- 
-- TABLE: User 
--

ALTER TABLE User ADD CONSTRAINT RefDiscount26 
    FOREIGN KEY (Discount_vipLevel)
    REFERENCES Discount(vipLevel)
;


