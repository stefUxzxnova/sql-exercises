CREATE DATABASE KURSOVPROEKT

USE KURSOVPROEKT

DROP DATABASE KURSOVPROEKT

CREATE TABLE CLIENTS(
CLIENTID INT NOT NULL PRIMARY KEY IDENTITY,
FIRSTNAME VARCHAR(100) NOT NULL,
LASTNAME VARCHAR(100) NOT NULL,
STATUS BIT NOT NULL --1 -> ACTIVE  --0 -> BLOCKED 
)

-------------------------------------------------------------------------------------------------------------------
CREATE TABLE LOGININFO(
CLIENTID INT NOT NULL PRIMARY KEY,
USERNAME VARCHAR(50) NOT NULL,
PASSWORD VARCHAR(100) NOT NULL
CONSTRAINT FK_CLIENT_LOGININFO FOREIGN KEY(CLIENTID)
		REFERENCES CLIENTS(CLIENTID)
)

---------------------------------------------------------------------------------------------------------------

CREATE TYPE LOGININFO_TYPE AS TABLE(
USERNAME VARCHAR(50),
PASSWORD VARCHAR(100) 
)

---------------------------------------------------------------------------------------------------------------
--процедура за добавяне на клиенти и тяхното login info
CREATE PROC CLIENTSINSERT
@FIRSTNAME AS VARCHAR(100),
@LASTNAME AS VARCHAR(100),
@STATUS AS BIT,
@ParLoginInfo LOGININFO_TYPE READONLY,
@CLIENTID AS INT
AS
SET NOCOUNT ON
	
	BEGIN TRAN TRAN1
		INSERT INTO CLIENTS(FIRSTNAME, LASTNAME, STATUS)
		VALUES(@FIRSTNAME, @LASTNAME, @STATUS) 
		SET @CLIENTID = SCOPE_IDENTITY()
	IF @@ERROR <> 0 ROLLBACK
			

		INSERT INTO LOGININFO
		SELECT @CLIENTID, USERNAME, [PASSWORD] FROM @ParLoginInfo
	IF @@ERROR <> 0 ROLLBACK
	COMMIT TRAN TRAN1
--drop proc CLIENTSINSERT
---------------------------------------------------------------------------------------------------------------
DECLARE  @ParLoginInfo AS LOGININFO_TYPE --променлива от user-defined тип
DECLARE @CLIENTID INT = SCOPE_IDENTITY()

INSERT INTO @ParLoginInfo  --#CLIENTID, USERNAME, PASSWORD
VALUES ('MARTOOOO', HASHBYTES('SHA1', 'FDSFDSFDS4435'))

EXECUTE CLIENTSINSERT  'MARTIN', 'GOSHEV', 1, @ParLoginInfo, @CLIENTID


SELECT * FROM LOGININFO
SELECT * FROM CLIENTS

-------------------------------------------------------------------------------------------------------------------
CREATE TABLE ADDRESSES(
ID INT NOT NULL PRIMARY KEY IDENTITY,
STREETNAME VARCHAR(150) NOT NULL,
STREETNUMBER INT NOT NULL,
CLIENTID INT NOT NULL,
ISPRIMARY BIT,
CONSTRAINT FK_CLIENT_ADDRESS FOREIGN KEY(CLIENTID)
		REFERENCES CLIENTS(CLIENTID)
		ON DELETE CASCADE ON UPDATE CASCADE
)

CREATE UNIQUE INDEX UniquePrimaryAddress 
ON ADDRESSES(CLIENTID) 
WHERE IsPrimary = 1;
--drop index UniquePrimaryAddress on ADDRESS

INSERT INTO ADDRESSES
VALUES('DSFDSFSF', 344, 4, 1)
INSERT INTO ADDRESS
VALUES('23456F', 4, 4, 0)
INSERT INTO ADDRESSES
VALUES('F', 1, 5, 0)
INSERT INTO ADDRESSES
VALUES('D3', 8, 3, 0)
INSERT INTO ADDRESSES
VALUES('D', 6, 2, 1)

SELECT * FROM ADDRESSES
DELETE FROM ADDRESS WHERE CLIENTID = 2 AND ISPRIMARY = 1
-------------------------------------------------------------------------------------------------------------------
--trigger, който проверява при insert дали клиента има други адреси в таблица address 
--ако няма -> сетва isPrimary на 1, т.е. първият добавен адрес става default
--ако има други адреси, следователно вече има default -> isPrimary се сетва на 0
CREATE TRIGGER ONADDRESSINSERT
	ON ADDRESSES FOR INSERT
	AS		
		IF(SELECT COUNT(*) FROM ADDRESSES WHERE CLIENTID = (SELECT CLIENTID FROM inserted)) > 1
			BEGIN
				UPDATE ADDRESSES
				SET ISPRIMARY = 0
				WHERE ID = (SELECT ID FROM inserted)
			END		
		ELSE
			BEGIN
				UPDATE ADDRESSES
				SET ISPRIMARY = 1
				WHERE ID = (SELECT ID FROM inserted)
			END

-------------------------------------------------------------------------------------------------------------------
--trigger, който след delete срещне ли на друго място същото clientId като на изтрития в таблица address 
--го сетва на 1, т.е. го прави default
CREATE TRIGGER ONADDRESSUPDATE
	ON ADDRESSES AFTER DELETE, UPDATE
	AS
		BEGIN
			UPDATE ADDRESSES
			SET ISPRIMARY = 1
			WHERE ID = (SELECT top 1 ID
			FROM ADDRESSES
			WHERE CLIENTID = (select top 1 CLIENTID from deleted))
		END
--drop trigger SECOND

-------------------------------------------------------------------------------------------------------------------
CREATE TABLE CATEGORIES(
        CATEGORYID INT NOT NULL PRIMARY KEY ,
        NAME VARCHAR(20) NOT NULL,
        PARENTID INT NULL
		CONSTRAINT FK_CATEGORY_SUBCATEGORY FOREIGN KEY(PARENTID)
		REFERENCES CATEGORIES(CATEGORYID)
);
--тип, който използваме за процедурата 
CREATE TYPE categoryTYPE AS TABLE(
CATEGORYID INT, 
NAME VARCHAR(100), 
PARENTID INT
)

CREATE PROCEDURE InsertCategory 
@ParCategoryType categoryTYPE READONLY
AS
INSERT INTO CATEGORIES
SELECT * FROM @ParCategoryType
--за изтриване на процедура
--DROP PROCEDURE InsertCategory

--декларираме параметър от новия тип таблица
DECLARE @ParCategoryType AS categoryType

INSERT INTO @ParCategoryType
VALUES ( 1, 'CLOTHS', NULL
       )
INSERT INTO @ParCategoryType
VALUES ( 2, 'SHIRTS', 1
       )
INSERT INTO @ParCategoryType
VALUES ( 3, 'SHOES', NULL
       )
INSERT INTO @ParCategoryType
VALUES ( 4, 'SANDALS', 3
       )
INSERT INTO @ParCategoryType
VALUES ( 5, 'SPORTSHOES', 3
       )
--изпълняваме процедурата   
EXECUTE InsertCategory @ParCategoryType
select * from CATEGORIES

------------------------------------------------------------------------------------------------------------------------
--SELECT, който ни показва категориите и техните подкатегории
SELECT t1.name AS lev1, t2.name as lev2, t3.name as lev3, t4.name as lev4
FROM CATEGORIES AS t1
LEFT JOIN CATEGORIES AS t2 ON t2.PARENTID = t1.CATEGORYID
LEFT JOIN CATEGORIES AS t3 ON t3.PARENTID = t2.CATEGORYID
LEFT JOIN CATEGORIES AS t4 ON t4.PARENTID = t3.CATEGORYID
WHERE t1.name IN ('CLOTHS', 'SHOES');

------------------------------------------------------------------------------------------------------------------------
CREATE TABLE PRODUCTS(
        PRODUCTID INT NOT NULL PRIMARY KEY IDENTITY,
		CATEGORYID INT NOT NULL,
        NAME VARCHAR(100) NOT NULL,
		BRAND VARCHAR(50) NOT NULL,
		DESCRIPTION TEXT NOT NULL,
		DELIVERYPRICE DECIMAL NOT NULL, 
		SELLINGPRICE DECIMAL NOT NULL, 
		CONSTRAINT FK_PRODUCT_CATEGORY FOREIGN KEY(CATEGORYID)
		REFERENCES CATEGORIES(CATEGORYID)
);

	INSERT INTO PRODUCTS(CATEGORYID, NAME, BRAND, DESCRIPTION, DELIVERYPRICE, SELLINGPRICE)
	VALUES(2, 'KUS_RUKAV', 'ADIDAS', 'DESCRIPTION', 50, 100)
	INSERT INTO PRODUCTS(CATEGORYID, NAME, BRAND, DESCRIPTION, DELIVERYPRICE, SELLINGPRICE)
	VALUES(2, 'DULUG_RUKAV', 'ADIDAS', 'DESCRIPTION', 30, 60)
	INSERT INTO PRODUCTS(CATEGORYID, NAME, BRAND, DESCRIPTION, DELIVERYPRICE, SELLINGPRICE)
	VALUES(4, 'CHEHLI', 'NIKE', 'DESCRIPTION', 60, 110)
	INSERT INTO PRODUCTS(CATEGORYID, NAME, BRAND, DESCRIPTION, DELIVERYPRICE, SELLINGPRICE)
	VALUES(5, 'MARATONKI', 'NIKE', 'DESCRRIPTION', 100, 150)

	SELECT * FROM PRODUCTS
	--TRUNCATE TABLE PRODUCTS

----------------------------------------------------------------------------------------------------
--Продуктите трябва да имат доставна цена и продажна цена. Те трябва да могат да се сменят
--ежедневно, като се запазва информация за историческите им стойности.
--*Създаваме си таблица за история на промените
CREATE TABLE PRODUCTPRICE_HISTORY
	(
	PRODUCTID INT,
	OLDDELIVERYPRICE DECIMAL, 
	DELIVERYPRICE DECIMAL,
	OLDSELLINGPRICE DECIMAL,
	SELLINGPRICE DECIMAL,
	DATEOFCHANGE DATETIME
	)

--trigger, който при промяна на цената на даден продукт записва в таблица с история на промените
----------------------------------------------------------------------------------------------------
CREATE TRIGGER PRODUCTPRICE_HISTORY_TRIGGER
	ON PRODUCTS FOR UPDATE
	AS
		IF UPDATE(SELLINGPRICE) OR UPDATE(DELIVERYPRICE)
		BEGIN
			INSERT INTO PRODUCTPRICE_HISTORY (PRODUCTID, OLDDELIVERYPRICE, DELIVERYPRICE, OLDSELLINGPRICE, SELLINGPRICE, DATEOFCHANGE)
			SELECT I.PRODUCTID, D.DELIVERYPRICE, I.DELIVERYPRICE, D.SELLINGPRICE, I.SELLINGPRICE, GETDATE()
			FROM inserted I, deleted D
			WHERE I.PRODUCTID = D.PRODUCTID
		END

		SELECT * FROM PRODUCTPRICE_HISTORY_TRIGGER
----------------------------------------------------------------------------------------------------
--тест
		UPDATE PRODUCTS
		SET DELIVERYPRICE = 1, SELLINGPRICE = 2
		WHERE PRODUCTID = 4

		SELECT * FROM PRODUCTPRICE_HISTORY
		SELECT * FROM PRODUCTS

------------------------------------------------------------------------------------------------------------------------
CREATE TABLE FEATURES (
    FEATUREID INT NOT NULL PRIMARY KEY IDENTITY,
    NAME VARCHAR(100),
	)

	INSERT INTO FEATURES
	VALUES ('PRICE')
	INSERT INTO FEATURES
	VALUES ('SIZE')
	INSERT INTO FEATURES
	VALUES ('COLOR')
	INSERT INTO FEATURES
	VALUES ('SEASON')
	INSERT INTO FEATURES
	VALUES ('PODMETKA')

------------------------------------------------------------------------------------------------------------------------
-- Всяка категория има set от features
CREATE TABLE CATEGORYFEATURES (
    CATEGORYID INT NOT NULL,
    FEATUREID INT NOT NULL,
	PRIMARY KEY (CATEGORYID, FEATUREID),
    FOREIGN KEY (CATEGORYID) REFERENCES CATEGORIES (CATEGORYID),
    FOREIGN KEY (FEATUREID) REFERENCES FEATURES (FEATUREID))

	INSERT INTO CATEGORYFEATURES
	VALUES	(2, 1),(2, 2),(2, 3),(2, 4),
			(4, 1),(4, 2),(4, 3),(4, 4),(4, 5),
			(5, 1),(5, 2),(5, 3),(5, 4),(5, 5)
			
--SELECT * FROM CATEGORYFEATURES
------------------------------------------------------------------------------------------------------------------------
CREATE TABLE PRODUCTFEATURES (
    PRODUCTID INT NOT NULL,
    FEATUREID INT NOT NULL,
	PRIMARY KEY (PRODUCTID, FEATUREID),
    FOREIGN KEY (FEATUREID) REFERENCES FEATURES (FEATUREID),
	FOREIGN KEY (PRODUCTID) REFERENCES PRODUCTS (PRODUCTID)
)
--DROP TABLE PRODUCTFEATURES
SELECT * FROM PRODUCTFEATURES

------------------------------------------------------------------------------------------------------------------------
--TRIGGER, който при insert на продукт, добавя в PRODUCTFEATURES, какви характеристики могат да се добавят за този продукт
CREATE TRIGGER [FEATURESINSERT]
	ON PRODUCTS FOR INSERT
	AS		
		BEGIN
			INSERT INTO PRODUCTFEATURES(PRODUCTID, FEATUREID)
			SELECT I.PRODUCTID, FEATUREID 
			FROM inserted I
			JOIN CATEGORYFEATURES CF ON CF.CATEGORYID = I.CATEGORYID

		END	
--DROP TRIGGER [FEATURESINSERT]

------------------------------------------------------------------------------------------------------------------------
CREATE TABLE ORDERS(
orderid int primary key identity(1,1),
UNIQUENUMBER uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
CLIENTID INT NOT NULL,
DATEOFORDER DATETIME NOT NULL,
STATUSID INT NOT NULL,
PRICE DECIMAL, 
CONSTRAINT FK_CLIENT FOREIGN KEY(CLIENTID)
	REFERENCES CLIENTS(CLIENTID),
CONSTRAINT FK_STATUS FOREIGN KEY(STATUSID)
	REFERENCES ORDERSTATUSES(STATUSID)
)
--DROP TABLE ORDERS

--CREATE SEQUENCE sequence_count AS INT
-- START WITH 0000
-- INCREMENT BY 1
-- MINVALUE 0000
-- MAXVALUE 9999
 

-- drop sequence sequence_count
------------------------------------------------------------------------------------------------------------------------
CREATE TABLE ORDERSTATUSES(
STATUSID INT NOT NULL PRIMARY KEY IDENTITY,
NAME VARCHAR(50) NOT NULL
)

INSERT INTO ORDERSTATUSES
VALUES('IZPRATENA')
INSERT INTO ORDERSTATUSES
VALUES('NEPLATENA')
INSERT INTO ORDERSTATUSES
VALUES('ODOBRENO PLASHTANE')
INSERT INTO ORDERSTATUSES
VALUES('PODGOTVENA ZA IZPRASHTANE')
INSERT INTO ORDERSTATUSES
VALUES('POLUCHENA')
--DROP TABLE ORDERSTATUS

------------------------------------------------------------------------------------------------------------------------
CREATE TABLE ORDERITEMSFEATURESVALUES (
	ID INT NOT NULL PRIMARY KEY IDENTITY, 
	ORDERID int NOT NULL,
    PRODUCTID INT NOT NULL,
	ORDERITEMID INT NOT NULL,
	CATEGORYID INT NOT NULL,
    FEATUREID INT NOT NULL,
	VALUE NVARCHAR(100) NOT NULL,
	FOREIGN KEY (ORDERID) REFERENCES ORDERS (ORDERID),
    FOREIGN KEY (PRODUCTID) REFERENCES PRODUCTS (PRODUCTID),
	FOREIGN KEY (ORDERITEMID) REFERENCES ORDERITEMS(ID),
    FOREIGN KEY (FEATUREID) REFERENCES FEATURES (FEATUREID),
	FOREIGN KEY (CATEGORYID, FEATUREID) REFERENCES CATEGORYFEATURES (CATEGORYID, FEATUREID),
	FOREIGN KEY (PRODUCTID, FEATUREID) REFERENCES PRODUCTFEATURES (PRODUCTID, FEATUREID)
)
SELECT * FROM ORDERITEMSFEATURESVALUES
DROP TABLE ORDERITEMSFEATURESVALUES

------------------------------------------------------------------------------------------------------------------------
CREATE TABLE ORDERITEMS(
ID INT NOT NULL PRIMARY KEY IDENTITY,
ORDERID int NOT NULL,
PRODUCTID INT NOT NULL,
QUANTITY INT NOT NULL,
CONSTRAINT FK_PRODUCT FOREIGN KEY(PRODUCTID)
	REFERENCES PRODUCTS(PRODUCTID),
CONSTRAINT FK_ORDER FOREIGN KEY(ORDERID)
	REFERENCES ORDERS(ORDERID)
)
--SELECT * FROM ORDERITEMS
--drop TABLE ORDERitems

CREATE TYPE ORDERPRODUCTS_TYPE AS TABLE(
PRODUCTID INT,
QUANTITY INT
)
--DROP TYPE ORDERPRODUCTS_TYPE

CREATE TYPE ORDERITEMSFEATURESVALUES_TYPE AS TABLE(
PRODUCTID INT,
CATEGORYID INT,
FEATUREID INT,
VALUE NVARCHAR(100)
)
--drop type ORDERITEMSFEATURESVALUES_TYPE

--------------------------------------------------------------------------------------------------------------
--Процедура, която въвежда order, orderitems, features на съответните items
CREATE PROC ORDERINSERT
@CLIENTID AS INT,
@STATUSID AS INT,
@DATEOFORDER AS DATETIME,
@ParOrderProductType ORDERPRODUCTS_TYPE READONLY,
@ParOrderItemFeatureValuesType ORDERITEMSFEATURESVALUES_TYPE READONLY,
@ORDERID AS INT,
@ORDERITEMID AS INT
AS
SET NOCOUNT ON
	
	--BEGIN TRAN TRAN1
		INSERT INTO ORDERS(UNIQUENUMBER, CLIENTID, DATEOFORDER, STATUSID)
		VALUES(DEFAULT, @CLIENTID, @DATEOFORDER, @STATUSID) 
		SET @ORDERID = SCOPE_IDENTITY()
		--sequence_count
	--IF @@ERROR <> 0 ROLLBACK
			

		INSERT INTO ORDERITEMS
		SELECT @ORDERID, PRODUCTID, QUANTITY FROM @ParOrderProductType
		SET @ORDERITEMID = SCOPE_IDENTITY()
	--IF @@ERROR <> 0 ROLLBACK

		INSERT INTO ORDERITEMSFEATURESVALUES
		SELECT @ORDERID, PRODUCTID, @ORDERITEMID, CATEGORYID, FEATUREID, VALUE FROM @ParOrderItemFeatureValuesType

	--IF @@ERROR <> 0 ROLLBACK
	--COMMIT TRAN TRAN1
--drop proc ORDERINSERT
---------------------------------------------------------------------------------------------------------------
DECLARE @ParOrderProductType AS ORDERPRODUCTS_TYPE --променлива от user-defined тип
DECLARE @ParOrderItemFeatureValuesType AS ORDERITEMSFEATURESVALUES_TYPE
DECLARE @DATEOFORDER datetime = GETDATE() --datetime променливи се декларират отделно
DECLARE @CLIENTID INT = 1 -- тъй като отдолу не приема присвояване
DECLARE @STATUSID INT = 4
DECLARE @ORDERID INT = SCOPE_IDENTITY()
DECLARE @ORDERITEMID INT = SCOPE_IDENTITY()
--стойностите, които ще запишат в ORDERITEMS *(orderid, productid, quantity)
INSERT INTO @ParOrderProductType  --ORDERID, PRODUCTID, QUANTITY
VALUES (1, 3)

INSERT INTO @ParOrderItemFeatureValuesType  --#ORDERID, PRODUCTID, CATEGORYID, FEATUREID, VALUE
VALUES(1, 2, 3, 'YELLOW')


EXECUTE ORDERINSERT @CLIENTID, @STATUSID, @DATEOFORDER, @ParOrderProductType, @ParOrderItemFeatureValuesType, @ORDERID, @ORDERITEMID
select * from PRODUCTS
--------------------------------------------------------------------------------------------------------------
--select продукт -> СТОЙНОСТ НА FEATURES
SELECT OO.ORDERID, OO.ID AS ORDERITEMID, CF.FEATUREID, F.NAME, CF.VALUE
FROM ORDERITEMS OO 
JOIN ORDERITEMSFEATURESVALUES CF ON OO.PRODUCTID = CF.PRODUCTID
JOIN FEATURE F ON F.FEATUREID = CF.FEATUREID
ORDER BY 1 ASC
-----------------------------------------------------------------------------------------------------------------------

--SELECT * FROM ORDERS
--SELECT * FROM ORDERITEMS
--SELECT * FROM ORDERITEMSFEATURESVALUES 
--TRUNCATE TABLE ORDERITEMS

--SELECT * FROM CLIENTS
--SELECT * FROM PRODUCTS 
--SELECT * FROM FEATURE
--SELECT * FROM CATEGORYFEATURES
--SELECT * FROM PRODUCTFEATURES

-----------------------------------------------------------------------------------------------------------------------
--trigger за изчисление на price в ORDERS
CREATE TRIGGER [PRICECALCULATION]
	ON ORDERITEMS FOR INSERT
	AS	
		BEGIN
			UPDATE ORDERS
			set PRICE = (SELECT SUM(P.SELLINGPRICE * OO.QUANTITY) FROM PRODUCTS P 
						JOIN ORDERITEMS OO 
						on OO.PRODUCTID = P.PRODUCTID 
						JOIN ORDERS O ON O.ORDERID = OO.ORDERID 
						WHERE OO.ORDERID = (SELECT TOP 1 ORDERID FROM inserted ORDER BY 1 DESC))
			WHERE ORDERID = (SELECT TOP 1 ORDERID FROM inserted ORDER BY 1 DESC)

			SELECT * FROM ORDERS
		END		
--DROP TRIGGER [PRICECALCULATION]

-----------------------------------------------------------------------------------------------------------------------
--Да се напише изглед, който да връща списък на активните клиенти (тези, които имат
--направени поръчки и не са блокирани).
CREATE VIEW CLIENS_AND_ORDERS
AS
SELECT C.CLIENTID, C.FIRSTNAME, C.LASTNAME, C.STATUS, COUNT(C.CLIENTID) AS 'broi poruchki'
FROM ClIENTS C FULL JOIN ORDERS O ON C.CLIENTID = O.CLIENTID
WHERE STATUS = 1
GROUP BY C.CLIENTID, C.FIRSTNAME, C.LASTNAME, C.STATUS
HAVING COUNT(O.CLIENTID) > 0

SELECT * FROM CLIENS_AND_ORDERS
--DROP VIEW CLIENS_AND_ORDERS

-----------------------------------------------------------------------------------------------------------------------
--Да се напише UDF, който приема за параметър категория и дата и връща информация за
--поръчаните на или след тази дата продукти от тази категория и съответните поръчки
CREATE FUNCTION ORDERED_PRODUCTS_BY_CATEGORY (@CATEGORYID INT, @DATEORDER AS DATETIME) 
RETURNS TABLE
AS
RETURN
(
    SELECT P.CATEGORYID, OO.ORDERID, OO.PRODUCTID, P.NAME, O.DATEOFORDER
	FROM ORDERITEMS OO 
	JOIN PRODUCTS P ON OO.PRODUCTID = P.PRODUCTID
	JOIN ORDERS O ON OO.ORDERID = O.ORDERID
	WHERE P.CATEGORYID = @CATEGORYID
	AND O.DATEOFORDER >= @DATEORDER
);
--DROP FUNCTION 
--TEST на функцията, подавам датата на 7-та поръчка --categoryid, datetimePar
SELECT * FROM ORDERED_PRODUCTS_BY_CATEGORY(2, (Select DATEOFORDER from orders where orderid = 3))
-----------------------------------------------------------------------------------------------------------------------

--Да се напишат заявки, които връщат:
--1. Най-често поръчваните продукти (бест селърите в магазина)
--2. По зададен продукт, най-често поръчваните заедно с него продукти
--3. По зададен продукт, как се е променяла цената му в рамките на послените 30 дни
--4. Каква е печалбата ни (разликата между продажните цени и доставните цени) за
--зададен период от време, като се взимат предвид само платените поръчки

--1. Най-често поръчваните продукти (бест селърите в магазина)
SELECT * FROM PRODUCTS 
SELECT * FROM ORDERITEMS

SELECT TOP 3 OO.PRODUCTID, P.NAME,  COUNT(OO.PRODUCTID) AS 'PORUCHKI'
FROM PRODUCTS P JOIN ORDERITEMS OO
ON P.PRODUCTID = OO.PRODUCTID
GROUP BY P.NAME, OO.PRODUCTID
ORDER BY 3 DESC

--2. По зададен продукт, най-често поръчваните заедно с него продукти 
--(зададен продукт с id = 1)
SELECT PRODUCTID, count(PRODUCTID) as 'broi poruchani'
FROM ORDERITEMS
WHERE ORDERID in (select oi.orderid from ORDERITEMS oi join products p on p.PRODUCTID = oi.PRODUCTID where oi.productid = 1)
group by PRODUCTID
EXCEPT 
SELECT PRODUCTID, count(PRODUCTID) 
FROM ORDERITEMS
WHERE PRODUCTID = 1
group by PRODUCTID


--select * from orders
--select * from orderitems

SELECT * FROM ORDERITEMS
--3. По зададен продукт, как се е променяла цената му в рамките на послените 30 дни
SELECT P.PRODUCTID, P.NAME, PH.OLDDELIVERYPRICE, PH.DELIVERYPRICE, P.SELLINGPRICE
FROM PRODUCTPRICE_HISTORY PH JOIN PRODUCTS P
ON PH.PRODUCTID = P.PRODUCTID
WHERE P.PRODUCTID = 4 AND PH.DATEOFCHANGE >= DATEADD(day,-30,GETDATE()) 
ORDER BY PRODUCTID ASC


SELECT * FROM PRODUCTPRICE_HISTORY

--4. Каква е печалбата ни (разликата между продажните цени и доставните цени) за
--зададен период от време, като се взимат предвид само платените поръчки
SELECT SUM((SELLINGPRICE - DELIVERYPRICE) * QUANTITY) AS PROFIT
FROM PRODUCTS P JOIN ORDERITEMS OO
ON P.PRODUCTID = OO.PRODUCTID
JOIN ORDERS O ON O.ORDERID = OO.ORDERID
WHERE O.DATEOFORDER >= (Select DATEOFORDER from orders where orderid = 1)
	AND	O.DATEOFORDER <= (Select DATEOFORDER from orders where orderid = 4)

	SELECT * FROM PRODUCTS
	SELECT * FROM ORDERITEMS
	SELECT * FROM ORDERS
