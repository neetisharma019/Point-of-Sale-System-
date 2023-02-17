drop database if EXISTS pos;
create database pos;
use pos;

create table `city` (
  `zip` decimal (5,0) UNSIGNED zerofill NOT NULL PRIMARY KEY, 
  `city` varchar(32), 
  `state` varchar(4))Engine=InnoDB;

create table `customer`(
  `ID` int, 
  `firstName` varchar(64), 
  `lastName` varchar(32), 
  `email` varchar(128), 
  `address1` varchar(128),
   `address2` varchar(128), 
   `phone` varchar(32), 
   `birthDate` date, 
   `zip` decimal (5,0) UNSIGNED zerofill,
   PRIMARY KEY (`ID`), 
   FOREIGN KEY(`zip`) REFERENCES `city`(`zip`))Engine=InnoDB;

create table `status`(
  `status` tinyint , 
  `description` varchar(12), 
  PRIMARY KEY(`status`))Engine=InnoDB;
  
create table `order`(
  `ID` int, 
  `datePlaced` date,
  `dateShipped` date, 
  `status` tinyint,
  `customerID` int, 
  PRIMARY KEY(`ID`),
  FOREIGN KEY (`status`) REFERENCES `status`(`status`), 
  FOREIGN KEY (`customerID`) REFERENCES `customer`(`ID`)
)Engine=InnoDB;

create table `product`(
`ID` int, 
`name` varchar(128),
`currentPrice` decimal(6,2),
`qtyOnHand` int,
PRIMARY KEY (`ID`)
)Engine=InnoDB;

create table `orderLine`(
  `orderID` int,
  `productID` int,
  `quantity` int,
  PRIMARY KEY(`orderID`, `productID`),
  FOREIGN KEY(`orderID`) REFERENCES `order`(`ID`),
  FOREIGN KEY (`productID`) REFERENCES `product`(`ID`)
  )Engine=InnoDB;


create table `temp_city` (
  `zip` decimal (5,0) UNSIGNED zerofill, 
  `city` varchar(32), 
  `state` varchar(4)
  );

create table `temp_customer`(
  `ID` int, 
  `firstName` varchar(64), 
  `lastName` varchar(32), 
  `city` varchar(128), 
  `state` varchar(128), 
  `zip` decimal (5,0) UNSIGNED zerofill,
  `address1` varchar(128), 
  `address2` varchar(128),
  `email` varchar(128), 
  `birthDate` date);

create table `temp_status`(
  `status` tinyint , 
  `description` varchar(12));
  
create table `temp_order`(
  `OID` int, 
  `CID` int
);

create table `temp_product`(
`ID` int, 
`name` varchar(128),
`currentPrice` decimal(6,2),
`qtyOnHand` int);

create table `temp_orderLine`(
  `orderID` int,
  `productID` int
  );

Load data local infile 'customers.csv' 
Into table `temp_customer` 
Fields Terminated by ',' 
Enclosed by '"' 
Lines terminated by '\n' 
Ignore 1 Rows (`ID`, `firstName`, `lastName`, `city`, `state`, `zip`, `address1`, `address2`, `email`, @birthdate) set `birthdate` = str_to_date(@birthdate, '%m/%d/%Y') ;

Update `temp_customer` set `birthDate` = NULL where `birthDate` = '0000-00-00' ;
Update `temp_customer` set `address2` = NULL where `address2` = "";

Insert into `city` (`zip`, `city`, `state`)   
select distinct `zip`, `city`, `state` from `temp_customer` group by `zip`;

Insert into `customer` (`ID`, `firstName`, `lastName`, `email`, `address1`, `address2`, `birthDate`, `zip`)
select `ID`, `firstName`, `lastName`, `email`, `address1`, `address2`, `birthDate`, `zip` from `temp_customer`;

Load data local infile 'orders.csv' 
Into table `temp_order`
Fields Terminated by ',' 
Enclosed by '"' 
Lines terminated by '\n' 
Ignore 1 Rows (`OID`, `CID`) ;

Insert into `order` (`ID`, `customerID`)
Select `OID`, `CID` from `temp_order`;

Load data local infile 'products.csv' 
Into table `temp_product`
Fields Terminated by ',' 
Enclosed by '"' 
Lines terminated by '\n' 
Ignore 1 Rows (`ID`, `name`, @currentPrice, `qtyOnHand`) set `currentPrice`= replace(replace( @currentPrice, "$", ""), ",", "" );

Insert into `product` (`ID`, `name`, `currentPrice`, `qtyOnHand`)
Select `ID`, `name`, `currentPrice`, `qtyOnHand` from `temp_product`;

Load data local infile 'orderlines.csv' 
Into table `temp_orderLine`
Fields Terminated by ',' 
Enclosed by '"' 
Lines terminated by '\n' 
Ignore 1 Rows (`orderID`, `productID`) ;

Insert into `orderLine` (`orderID`, `productID`, `quantity`)
Select `orderID`, `productID`, COUNT(`productID`) from `temp_orderLine` group by `orderID`, `productID`;

drop table if EXISTS `temp_city`;
drop table if EXISTS `temp_customer`;
drop table if EXISTS `temp_order`;
drop table if EXISTS `temp_product`;
drop table if EXISTS `temp_orderLine`;
drop table if EXISTS `temp_status`;






