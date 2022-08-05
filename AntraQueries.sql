-- Q1)
WITH cte_company(PrimaryContact,AlternateContact,CompanyPhone,CompanyFax) AS (
	SELECT C.PrimaryContactPersonID,C.AlternateContactPersonID,C.PhoneNumber,C.FaxNumber
	FROM Sales.Customers C
		UNION ALL
	SELECT S.PrimaryContactPersonID,S.AlternateContactPersonID,S.PhoneNumber,S.FaxNumber
	FROM Purchasing.Suppliers S
)
SELECT P.PersonID, P.FullName, P.PhoneNumber, P.FaxNumber, C.CompanyPhone, C.CompanyFax
FROM Application.People P LEFT JOIN cte_company C ON P.PersonID=C.PrimaryContact OR P.PersonID=C.AlternateContact;

-- Q2)
SELECT S.CustomerName,P.PhoneNumber,S.PhoneNumber
FROM Sales.Customers S LEFT JOIN Application.People P ON S.PrimaryContactPersonID=P.PersonID AND S.PhoneNumber=P.PhoneNumber;

-- Q3)
WITH cte_TransactDates(CustomerId, NewestOrder, OldestOrder) AS (
	SELECT T.CustomerID, MAX(T.TransactionDate)NewestOrder, MIN(T.TransactionDate)OldestOrder
	FROM Sales.CustomerTransactions T
	GROUP BY T.CustomerID
)
SELECT C.CustomerName
FROM Sales.Customers C INNER JOIN cte_TransactDates T ON C.CustomerID=T.CustomerId
WHERE T.OldestOrder<'2016-01-01' AND T.NewestOrder<'2016-01-01';

-- Q4) Multiplies "OrderedOuter" with "QuantityPerOuter" to get total stock purchased
SELECT L.StockItemID, I.StockItemName, SUM(L.OrderedOuters*I.QuantityPerOuter) TotalPurchased
FROM Purchasing.PurchaseOrders O INNER JOIN Purchasing.PurchaseOrderLines L ON O.PurchaseOrderID=L.PurchaseOrderID AND YEAR(OrderDate)='2013' INNER JOIN Warehouse.StockItems I ON L.StockItemID=I.StockItemID
GROUP BY L.StockItemID, I.StockItemName;

-- Q5) Assumes description=SearchDetails
SELECT S.StockItemID,S.StockItemName,S.SearchDetails
FROM Warehouse.StockItems S
WHERE LEN(S.SearchDetails)>10;

-- Q6) 
WITH cte_Sold_To_GA_AL(Items) AS(
SELECT DISTINCT O.StockItemID FROM (
	SELECT InvoiceID
	FROM Sales.CustomerTransactions T 
		LEFT JOIN (SELECT C.CustomerID, C.DeliveryCityID FROM Sales.Customers C) C ON T.CustomerID=C.CustomerID
		LEFT JOIN (SELECT Ct.CityID, Ct.StateProvinceID FROM Application.Cities Ct) Ct ON C.DeliveryCityID=Ct.CityID
		LEFT JOIN (SELECT S.StateProvinceID, S.StateProvinceName FROM Application.StateProvinces S) S ON Ct.StateProvinceID=S.StateProvinceID
	WHERE YEAR(T.TransactionDate)=2014 AND (StateProvinceName='Alabama' OR StateProvinceName='Georgia')
	) TR LEFT JOIN Sales.InvoiceLines O ON TR.InvoiceID = O.InvoiceID
)
SELECT *
FROM Warehouse.StockItems S 
WHERE S.StockItemID NOT IN (SELECT Items FROM cte_Sold_To_GA_AL);

-- Q7) 
SELECT S.StateProvinceName, AVG(DATEDIFF(day,O.OrderDate,I.ConfirmedDeliveryTime))AvgTurnaroundDay
FROM Sales.Invoices I 
	INNER JOIN Sales.Orders O ON I.OrderID=O.OrderID 
	LEFT JOIN Sales.Customers C ON O.CustomerID=C.CustomerID
	LEFT JOIN Application.Cities Ct ON Ct.CityID=C.DeliveryCityID
	LEFT JOIN Application.StateProvinces S ON Ct.StateProvinceID=S.StateProvinceID
GROUP BY S.StateProvinceName;

-- Q8)
SELECT S.StateProvinceName,MONTH(O.OrderDate)OrderMonth, AVG(DATEDIFF(day,O.OrderDate,I.ConfirmedDeliveryTime))AvgTurnaroundDay
FROM Sales.Invoices I 
	INNER JOIN Sales.Orders O ON I.OrderID=O.OrderID 
	LEFT JOIN Sales.Customers C ON O.CustomerID=C.CustomerID
	LEFT JOIN Application.Cities Ct ON Ct.CityID=C.DeliveryCityID
	LEFT JOIN Application.StateProvinces S ON Ct.StateProvinceID=S.StateProvinceID
GROUP BY S.StateProvinceName,MONTH(O.OrderDate)
ORDER BY MONTH(O.OrderDate),S.StateProvinceName;

-- Q9)
;WITH cte_Bought(StockID,StockName,Bought) AS (
SELECT S.StockItemID,S.StockItemName, SUM(PL.OrderedOuters*S.QuantityPerOuter)TotalPurchased
FROM Purchasing.PurchaseOrders P 
	LEFT JOIN Purchasing.PurchaseOrderLines PL ON P.PurchaseOrderID=PL.PurchaseOrderID
	LEFT JOIN Warehouse.StockItems S ON PL.StockItemID= S.StockItemID
WHERE YEAR(P.OrderDate)=2015
GROUP BY S.StockItemID,S.StockItemName
),
cte_Sold(StockID,StockName,Sold) AS (
SELECT S.StockItemID,S.StockItemName, SUM(OL.Quantity)TotalSold
FROM Sales.Orders O 
	LEFT JOIN Sales.OrderLines OL ON O.OrderID=OL.OrderID
	LEFT JOIN Warehouse.StockItems S ON OL.StockItemID= S.StockItemID
WHERE YEAR(O.OrderDate)=2015
GROUP BY S.StockItemID,S.StockItemName
)
SELECT S.StockID,S.StockName
FROM cte_Sold S FULL OUTER JOIN cte_Bought B ON B.StockID=S.StockID
WHERE DIFFERENCE(S.Sold,B.Bought)>0;

-- Q10)
WITH cte_MugsSold(CID, Mugs) AS(
SELECT O.CustomerID,SUM(OL.Quantity)MugsSold
FROM Sales.Customers C 
	LEFT JOIN Sales.Orders O ON O.CustomerID=C.CustomerID
	LEFT JOIN Sales.OrderLines OL ON OL.OrderID=O.OrderID
WHERE YEAR(O.OrderDate)=2016 AND CHARINDEX('mug',OL.Description)>0
GROUP BY O.CustomerID
)
SELECT C.CustomerName,C.PhoneNumber,P.FullName
FROM Sales.Customers C 
	LEFT JOIN cte_MugsSold M ON C.CustomerID=M.CID
	LEFT JOIN Application.People P ON C.PrimaryContactPersonID=P.PersonID
WHERE M.Mugs<10 OR M.Mugs IS NULL;

-- Q11)
SELECT *
FROM Application.Cities
WHERE ValidFrom >'2015-01-01'

-- Q12) SI-StockItem, I-Delivery Address (DeliveryInstructions), SP-Delivery State,Ct-City, Cty-Country,C-CustomerName, P-Customer Contact Person Name, C-Customer Phone (PhoneNumber), OL-Quantity
SELECT SI.StockItemName,I.DeliveryInstructions AS DeliveryAddress, SP.StateProvinceName, Ct.CityName,Cty.CountryName,C.CustomerName,P.FullName,C.PhoneNumber AS CustomerPhone, OL.Quantity
FROM (SELECT * FROM Sales.Orders O WHERE OrderDate='2014-07-01') O 
	LEFT JOIN Sales.OrderLines OL ON O.OrderID=OL.OrderID 
	LEFT JOIN Warehouse.StockItems SI ON OL.StockItemID=SI.StockItemID
	LEFT JOIN Sales.Invoices I ON I.OrderID=O.OrderID
	LEFT JOIN Sales.Customers C ON C.CustomerID=I.CustomerID
	LEFT JOIN Application.Cities Ct ON C.DeliveryCityID=Ct.CityID
	LEFT JOIN Application.StateProvinces SP ON Ct.StateProvinceID=SP.StateProvinceID
	LEFT JOIN Application.Countries Cty ON SP.CountryID=Cty.CountryID
	LEFT JOIN Application.People P ON C.PrimaryContactPersonID=P.PersonID;

-- Q13)
WITH cte_bought(StockItemID, Bought) AS(
SELECT SI.StockItemID, SUM(POL.OrderedOuters*SI.QuantityPerOuter)Bought 
FROM Purchasing.PurchaseOrderLines POL LEFT JOIN Warehouse.StockItems SI ON POL.StockItemID=SI.StockItemID
GROUP BY SI.StockItemID
)
SELECT SG.StockGroupID, SG.StockGroupName, SUM(S.Sold)Sold, SUM(B.Bought)Bought,SUM(B.Bought-S.Sold)RemainingStock
FROM Warehouse.StockItems SI
	LEFT JOIN Warehouse.StockItemStockGroups SISG ON SI.StockItemID=SISG.StockItemID
	LEFT JOIN Warehouse.StockGroups SG ON SISG.StockGroupID=SG.StockGroupID
	LEFT JOIN (SELECT OL.StockItemID, SUM(OL.Quantity)Sold FROM Sales.OrderLines OL GROUP BY OL.StockItemID) S 
		ON S.StockItemID = SI.StockItemID
	LEFT JOIN cte_bought B ON B.StockItemID=SI.StockItemID 
GROUP BY SG.StockGroupID,SG.StockGroupName

-- Q15)
SELECT * 
FROM Sales.Orders
WHERE OrderID IN(
SELECT OrderID FROM Sales.Invoices WHERE JSON_VALUE(ReturnedDeliveryData, '$.Events[1].Comment') IS NOT NULL
);

-- Q16)
SELECT S.StockItemID,S.StockItemName,S.Manuf
FROM(
	SELECT *, JSON_VALUE(CustomFields, '$.CountryOfManufacture')Manuf 
	FROM Warehouse.StockItems)S
WHERE Manuf='China';

-- Q17)
SELECT sum(OL.Quantity)QuantitySoldFromChina
FROM Sales.Orders O 
	LEFT JOIN Sales.OrderLines OL ON O.OrderID=OL.OrderID 
	LEFT JOIN Warehouse.StockItems SI ON  OL.StockItemID=SI.StockItemID
WHERE YEAR(O.OrderDate)=2015 AND JSON_VALUE(CustomFields, '$.CountryOfManufacture')='China';

-- Q18)
DROP VIEW IF EXISTS StockGroupByYear;
GO
CREATE VIEW StockGroupByYear
AS
WITH cte_annualSale(StockGroupName, [Year], Sold) AS(
	SELECT SG.StockGroupName,YEAR(O.OrderDate)Year, sum(OL.Quantity)Sold
	FROM Warehouse.StockGroups SG 
		INNER JOIN Warehouse.StockItemStockGroups SISG ON SG.StockGroupID=SISG.StockGroupID
		INNER JOIN Warehouse.StockItems SI ON SI.StockItemID=SISG.StockItemID
		INNER JOIN Sales.OrderLines OL ON OL.StockItemID= SI.StockItemID 
		INNER JOIN Sales.Orders O on O.OrderID=OL.OrderID
	GROUP BY SG.StockGroupName, YEAR(O.OrderDate)
	)
SELECT Sname.StockGroupName, [2013], [2014], [2015], [2016], [2017]
FROM (SELECT DISTINCT a.StockGroupName AS StockGroupName FROM cte_annualSale a)Sname
	LEFT JOIN (SELECT StockGroupName, (b.Sold)[2013] FROM cte_annualSale b WHERE b.[Year]=2013)yr2013 ON Sname.StockGroupName=yr2013.StockGroupName
	LEFT JOIN (SELECT StockGroupName, (b.Sold)[2014] FROM cte_annualSale b WHERE b.[Year]=2014)yr2014 ON Sname.StockGroupName=yr2014.StockGroupName
	LEFT JOIN (SELECT StockGroupName, (b.Sold)[2015] FROM cte_annualSale b WHERE b.[Year]=2015)yr2015 ON Sname.StockGroupName=yr2015.StockGroupName
	LEFT JOIN (SELECT StockGroupName, (b.Sold)[2016] FROM cte_annualSale b WHERE b.[Year]=2016)yr2016 ON Sname.StockGroupName=yr2016.StockGroupName
	LEFT JOIN (SELECT StockGroupName, (b.Sold)[2017] FROM cte_annualSale b WHERE b.[Year]=2017)yr2017 ON Sname.StockGroupName=yr2017.StockGroupName;

SELECT * FROM StockGroupByYear;

-- Q19) GIVE UP
DROP VIEW IF EXISTS StockGroupByYear2;
GO
CREATE VIEW StockGroupByYear2
AS 

SELECT 'Sales' AS StockGroupName, [T-Shirts], [USB Novelties], [Packaging Materials], [Clothing], [Novelty Items], [Furry Footwear], [Mugs], [Computing Novelties], [Toys]
FROM (SELECT * FROM StockGroupByYear) AS Piv
PIVOT
(
-- Q20)
GO
DROP FUNCTION IF EXISTS f_OrderTotal
GO
CREATE FUNCTION f_OrderTotal(@orderid int)
RETURNS float AS
BEGIN
	DECLARE @total float
	SELECT @total = sum(Quantity*UnitPrice*(1+(TaxRate/100)))
	FROM Sales.OrderLines
	WHERE OrderID=@orderid
	RETURN @total
END;
GO
SELECT InvoiceID, OrderID, dbo.f_OrderTotal(InvoiceID)
FROM Sales.Invoices;

-- Q21)
GO
CREATE SCHEMA ods;
GO
DROP TABLE IF EXISTS ods.Orders;
GO
CREATE TABLE ods.Orders(
	orderID int PRIMARY KEY,
	orderDate date,
	orderTotal float,
	customerID int);

DROP PROCEDURE IF EXISTS p_DayOrders;
GO
CREATE PROCEDURE p_DayOrders @Day date
AS BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			INSERT INTO ods.Orders
			SELECT S.OrderID, S.OrderDate, SUM(Quantity*UnitPrice*(1+(TaxRate/100)))OrderTotal, S.CustomerID
			FROM Sales.Orders S LEFT JOIN Sales.OrderLines OL ON S.OrderID=OL.OrderID
			WHERE S.OrderDate=@Day
			GROUP BY S.OrderID, S.OrderDate,S.CustomerID;
		COMMIT
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE() AS ErrorMessage;
		ROLLBACK;
	END CATCH
END
GO
EXEC p_DayOrders @day = '2013-01-01';
EXEC p_DayOrders @day = '2014-03-21';
EXEC p_DayOrders @day = '2015-02-01';
EXEC p_DayOrders @day = '2015-03-23';
EXEC p_DayOrders @day = '2015-11-11';
EXEC p_DayOrders @day = '2015-11-11';

SELECT * FROM ods.Orders;

-- Q22)
SELECT StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID, Brand, Size, 
	LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, 
	TypicalWeightPerUnit, MarketingComments, InternalComments, 
	JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture, NULL AS Range, NULL AS Shelflife
INTO ods.StockItem
FROM Warehouse.StockItems

SELECT * FROM ods.StockItem

-- Q23)
GO
ALTER PROCEDURE p_DayOrders @day date
AS
	DELETE FROM ods.Orders WHERE OrderDate < @day;
	INSERT INTO ods.Orders
			SELECT S.OrderID, S.OrderDate, SUM(Quantity*UnitPrice*(1+(TaxRate/100)))OrderTotal, S.CustomerID
			FROM Sales.Orders S LEFT JOIN Sales.OrderLines OL ON S.OrderID=OL.OrderID
			WHERE S.OrderDate>@Day AND S.OrderDate<=DATEADD(day,7,@Day)
			GROUP BY S.OrderID, S.OrderDate,S.CustomerID;
GO
EXEC p_DayOrders @day='2015-12-31';
SELECT * FROM ods.Orders

-- Q24) JSON text is not properly formatted. Unexpected character '.' is found at position 1.
DECLARE @json NVARCHAR;
SET @json = N'{
   "PurchaseOrders":[
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"7",
         "UnitPackageId":"1",
         "OuterPackageId":[
            6,
            7
         ],
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"
      },
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-025",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"
      }
   ]
}';
SELECT *
FROM OPENJSON(@json)
	WITH (
		StockItemName varchar '$'
	);

-- Q27)
DROP TABLE IF EXISTS ods.ComfirmedDeviveryJson;
GO
CREATE TABLE ods.ConfirmedDeviveryJson(
	id int,
	[date] date,
	value varchar);
GO
CREATE PROCEDURE p_populateCDJ @day date
AS BEGIN
	INSERT INTO ods.ConfirmedDeviveryJson
		SELECT I.*,IL.InvoiceLineID, IL.StockItemID,IL.Description,IL.PackageTypeID,IL.Quantity,IL.UnitPrice,IL.TaxRate,IL.TaxAmount,IL.LineProfit,IL.ExtendedPrice,IL.LastEditedBy AS IL_LastEditedBy,IL.LastEditedWhen AS IL_LastEditedWhen
		FROM Sales.Invoices I JOIN Sales.InvoiceLines IL ON I.InvoiceID=IL.InvoiceID
		WHERE I.InvoiceDate=@Day
		FOR JSON PATH;
END